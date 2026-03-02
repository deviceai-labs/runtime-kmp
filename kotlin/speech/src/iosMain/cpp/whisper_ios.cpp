/**
 * whisper_ios.cpp - C wrapper for whisper.cpp (Speech-to-Text) on iOS
 */

#include "../c_interop/include/speech_ios.h"
#include "whisper.h"

#include <string>
#include <vector>
#include <atomic>
#include <mutex>
#include <cstring>
#include <fstream>
#include <sstream>

// ═══════════════════════════════════════════════════════════════
//                          GLOBAL STATE
// ═══════════════════════════════════════════════════════════════

static struct whisper_context *g_ctx = nullptr;
static struct whisper_full_params g_params;
static std::mutex g_mutex;
static std::atomic<bool> g_cancel_requested{false};

// Configuration
static std::string g_language = "en";
static std::atomic<bool> g_translate{false};
static std::atomic<int> g_max_threads{4};
static std::atomic<bool> g_use_gpu{true};
static std::atomic<bool> g_use_vad{true};

// Debug logging
static bool debug_enabled() {
    static int enabled = -1;
    if (enabled < 0) {
        const char *env = getenv("SPEECHKMP_DEBUG");
        enabled = (env && strcmp(env, "1") == 0) ? 1 : 0;
    }
    return enabled == 1;
}

#define LOG_DEBUG(fmt, ...) if (debug_enabled()) fprintf(stderr, "[SpeechKMP-STT] " fmt "\n", ##__VA_ARGS__)
#define LOG_ERROR(fmt, ...) fprintf(stderr, "[SpeechKMP-STT ERROR] " fmt "\n", ##__VA_ARGS__)

// ═══════════════════════════════════════════════════════════════
//                      HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════

static char *strdup_safe(const std::string &str) {
    char *result = static_cast<char*>(malloc(str.size() + 1));
    if (result) {
        strcpy(result, str.c_str());
    }
    return result;
}

static bool read_wav_file(const std::string &path, std::vector<float> &samples, int &sample_rate) {
    std::ifstream file(path, std::ios::binary);
    if (!file.is_open()) {
        LOG_ERROR("Failed to open WAV file: %s", path.c_str());
        return false;
    }

    // Read WAV header
    char riff[4];
    file.read(riff, 4);
    if (std::strncmp(riff, "RIFF", 4) != 0) {
        LOG_ERROR("Invalid WAV file: missing RIFF header");
        return false;
    }

    file.seekg(4, std::ios::cur); // Skip file size

    char wave[4];
    file.read(wave, 4);
    if (std::strncmp(wave, "WAVE", 4) != 0) {
        LOG_ERROR("Invalid WAV file: missing WAVE header");
        return false;
    }

    // Find fmt and data chunks
    while (file.good()) {
        char chunk_id[4];
        file.read(chunk_id, 4);

        uint32_t chunk_size;
        file.read(reinterpret_cast<char*>(&chunk_size), 4);

        if (std::strncmp(chunk_id, "fmt ", 4) == 0) {
            uint16_t audio_format;
            file.read(reinterpret_cast<char*>(&audio_format), 2);

            uint16_t num_channels;
            file.read(reinterpret_cast<char*>(&num_channels), 2);

            uint32_t sr;
            file.read(reinterpret_cast<char*>(&sr), 4);
            sample_rate = sr;

            file.seekg(chunk_size - 8, std::ios::cur);
        } else if (std::strncmp(chunk_id, "data", 4) == 0) {
            std::vector<int16_t> pcm(chunk_size / 2);
            file.read(reinterpret_cast<char*>(pcm.data()), chunk_size);

            samples.resize(pcm.size());
            for (size_t i = 0; i < pcm.size(); i++) {
                samples[i] = static_cast<float>(pcm[i]) / 32768.0f;
            }
            break;
        } else {
            file.seekg(chunk_size, std::ios::cur);
        }
    }

    return !samples.empty();
}

static bool resample_to_16k(const std::vector<float> &input, int input_rate, std::vector<float> &output) {
    if (input_rate == WHISPER_SAMPLE_RATE) {
        output = input;
        return true;
    }

    double ratio = static_cast<double>(WHISPER_SAMPLE_RATE) / input_rate;
    size_t output_size = static_cast<size_t>(input.size() * ratio);
    output.resize(output_size);

    for (size_t i = 0; i < output_size; i++) {
        double src_idx = i / ratio;
        size_t idx0 = static_cast<size_t>(src_idx);
        size_t idx1 = std::min(idx0 + 1, input.size() - 1);
        double frac = src_idx - idx0;
        output[i] = static_cast<float>(input[idx0] * (1.0 - frac) + input[idx1] * frac);
    }

    return true;
}

static std::string build_json_result(const std::string &text,
                                      const std::vector<std::tuple<std::string, int64_t, int64_t>> &segments,
                                      const std::string &language,
                                      int64_t durationMs) {
    std::ostringstream json;
    json << "{";
    json << "\"text\":\"" << text << "\",";
    json << "\"language\":\"" << language << "\",";
    json << "\"durationMs\":" << durationMs << ",";
    json << "\"segments\":[";

    for (size_t i = 0; i < segments.size(); i++) {
        if (i > 0) json << ",";
        json << "{";
        json << "\"text\":\"" << std::get<0>(segments[i]) << "\",";
        json << "\"startMs\":" << std::get<1>(segments[i]) << ",";
        json << "\"endMs\":" << std::get<2>(segments[i]);
        json << "}";
    }

    json << "]}";
    return json.str();
}

// ═══════════════════════════════════════════════════════════════
//                        C API FUNCTIONS
// ═══════════════════════════════════════════════════════════════

bool speech_stt_init(const char *model_path, const char *language,
                     bool translate, int max_threads, bool use_gpu, bool use_vad) {

    std::lock_guard<std::mutex> lock(g_mutex);

    // Shutdown existing context
    if (g_ctx != nullptr) {
        whisper_free(g_ctx);
        g_ctx = nullptr;
    }

    g_language = language ? language : "en";
    g_translate = translate;
    g_max_threads = max_threads;
    g_use_gpu = use_gpu;
    g_use_vad = use_vad;

    LOG_DEBUG("Initializing Whisper with model: %s", model_path);

    struct whisper_context_params ctx_params = whisper_context_default_params();
    ctx_params.use_gpu = use_gpu;

    g_ctx = whisper_init_from_file_with_params(model_path, ctx_params);
    if (g_ctx == nullptr) {
        LOG_ERROR("Failed to initialize Whisper model");
        return false;
    }

    g_params = whisper_full_default_params(WHISPER_SAMPLING_GREEDY);
    g_params.language = g_language.c_str();
    g_params.translate = translate;
    g_params.n_threads = max_threads;
    g_params.no_timestamps = false;
    g_params.print_special = false;
    g_params.print_progress = false;
    g_params.print_realtime = false;
    g_params.print_timestamps = false;

    LOG_DEBUG("Whisper model initialized successfully");
    return true;
}

char *speech_stt_transcribe(const char *audio_path) {
    std::lock_guard<std::mutex> lock(g_mutex);

    if (g_ctx == nullptr) {
        LOG_ERROR("Whisper not initialized");
        return strdup_safe("");
    }

    g_cancel_requested = false;

    std::vector<float> samples;
    int sample_rate;
    if (!read_wav_file(audio_path, samples, sample_rate)) {
        return strdup_safe("");
    }

    std::vector<float> samples_16k;
    resample_to_16k(samples, sample_rate, samples_16k);

    if (whisper_full(g_ctx, g_params, samples_16k.data(), samples_16k.size()) != 0) {
        LOG_ERROR("Whisper inference failed");
        return strdup_safe("");
    }

    std::string result;
    int n_segments = whisper_full_n_segments(g_ctx);
    for (int i = 0; i < n_segments; i++) {
        const char *text = whisper_full_get_segment_text(g_ctx, i);
        if (text) {
            result += text;
        }
    }

    return strdup_safe(result);
}

char *speech_stt_transcribe_detailed(const char *audio_path) {
    std::lock_guard<std::mutex> lock(g_mutex);

    if (g_ctx == nullptr) {
        LOG_ERROR("Whisper not initialized");
        return strdup_safe("{\"text\":\"\",\"segments\":[],\"language\":\"en\",\"durationMs\":0}");
    }

    g_cancel_requested = false;

    std::vector<float> samples;
    int sample_rate;
    if (!read_wav_file(audio_path, samples, sample_rate)) {
        return strdup_safe("{\"text\":\"\",\"segments\":[],\"language\":\"en\",\"durationMs\":0}");
    }

    std::vector<float> samples_16k;
    resample_to_16k(samples, sample_rate, samples_16k);

    if (whisper_full(g_ctx, g_params, samples_16k.data(), samples_16k.size()) != 0) {
        LOG_ERROR("Whisper inference failed");
        return strdup_safe("{\"text\":\"\",\"segments\":[],\"language\":\"en\",\"durationMs\":0}");
    }

    std::string fullText;
    std::vector<std::tuple<std::string, int64_t, int64_t>> segments;

    int n_segments = whisper_full_n_segments(g_ctx);
    for (int i = 0; i < n_segments; i++) {
        const char *text = whisper_full_get_segment_text(g_ctx, i);
        int64_t t0 = whisper_full_get_segment_t0(g_ctx, i) * 10;
        int64_t t1 = whisper_full_get_segment_t1(g_ctx, i) * 10;

        if (text) {
            fullText += text;
            segments.emplace_back(text, t0, t1);
        }
    }

    int64_t durationMs = samples_16k.size() * 1000 / WHISPER_SAMPLE_RATE;
    std::string json = build_json_result(fullText, segments, g_language, durationMs);

    return strdup_safe(json);
}

char *speech_stt_transcribe_audio(const float *samples, int n_samples) {
    std::lock_guard<std::mutex> lock(g_mutex);

    if (g_ctx == nullptr) {
        LOG_ERROR("Whisper not initialized");
        return strdup_safe("");
    }

    g_cancel_requested = false;

    if (whisper_full(g_ctx, g_params, samples, n_samples) != 0) {
        LOG_ERROR("Whisper inference failed");
        return strdup_safe("");
    }

    std::string result;
    int n_segments = whisper_full_n_segments(g_ctx);
    for (int i = 0; i < n_segments; i++) {
        const char *text = whisper_full_get_segment_text(g_ctx, i);
        if (text) {
            result += text;
        }
    }

    return strdup_safe(result);
}

void speech_stt_transcribe_stream(const float *samples, int n_samples,
                                   stt_on_partial on_partial,
                                   stt_on_final on_final,
                                   stt_on_error on_error,
                                   void *user) {

    std::lock_guard<std::mutex> lock(g_mutex);

    if (g_ctx == nullptr) {
        if (on_error) on_error("Whisper not initialized", user);
        return;
    }

    g_cancel_requested = false;

    if (whisper_full(g_ctx, g_params, samples, n_samples) != 0) {
        if (on_error) on_error("Transcription failed", user);
        return;
    }

    std::string fullText;
    std::vector<std::tuple<std::string, int64_t, int64_t>> segments;

    int n_seg = whisper_full_n_segments(g_ctx);
    for (int i = 0; i < n_seg; i++) {
        if (g_cancel_requested) {
            if (on_error) on_error("Cancelled", user);
            return;
        }

        const char *text = whisper_full_get_segment_text(g_ctx, i);
        int64_t t0 = whisper_full_get_segment_t0(g_ctx, i) * 10;
        int64_t t1 = whisper_full_get_segment_t1(g_ctx, i) * 10;

        if (text) {
            fullText += text;
            segments.emplace_back(text, t0, t1);

            if (on_partial) {
                on_partial(fullText.c_str(), user);
            }
        }
    }

    int64_t durationMs = n_samples * 1000 / WHISPER_SAMPLE_RATE;
    std::string json = build_json_result(fullText, segments, g_language, durationMs);

    if (on_final) {
        on_final(json.c_str(), user);
    }
}

void speech_stt_cancel(void) {
    g_cancel_requested = true;
}

void speech_stt_shutdown(void) {
    std::lock_guard<std::mutex> lock(g_mutex);

    if (g_ctx != nullptr) {
        LOG_DEBUG("Shutting down Whisper");
        whisper_free(g_ctx);
        g_ctx = nullptr;
    }
}

void speech_free_string(char *ptr) {
    if (ptr) {
        free(ptr);
    }
}

// ═══════════════════════════════════════════════════════════════
//                    TTS STUBS (when TTS disabled)
// ═══════════════════════════════════════════════════════════════

#ifdef SPEECHKMP_STT_ONLY

bool speech_tts_init(const char *model_path, const char *config_path,
                     const char *espeak_data_path, int speaker_id,
                     float speech_rate, int sample_rate, float sentence_silence) {
    LOG_ERROR("TTS not available - built with STT only");
    return false;
}

int16_t *speech_tts_synthesize(const char *text, int *out_length) {
    LOG_ERROR("TTS not available - built with STT only");
    *out_length = 0;
    return nullptr;
}

bool speech_tts_synthesize_to_file(const char *text, const char *output_path) {
    LOG_ERROR("TTS not available - built with STT only");
    return false;
}

void speech_tts_synthesize_stream(const char *text,
                                   tts_on_chunk on_chunk,
                                   tts_on_complete on_complete,
                                   tts_on_error on_error,
                                   void *user) {
    if (on_error) on_error("TTS not available - built with STT only", user);
}

void speech_tts_cancel(void) {}

void speech_tts_shutdown(void) {}

void speech_free_audio(int16_t *ptr) {
    if (ptr) free(ptr);
}

void speech_shutdown_all(void) {
    speech_stt_shutdown();
}

#endif // SPEECHKMP_STT_ONLY
