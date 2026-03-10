/**
 * whisper_ios.cpp
 *
 * Thin C delegate — forwards the legacy speech_stt_* iOS API to the unified
 * dai_stt_* API in deviceai_speech_engine.{h,cpp}.
 *
 * No STT logic lives here. The Swift cinterop def still references speech_ios.h,
 * so legacy speech_stt_* symbols are kept as shims.
 *
 * Callback types share the same function signatures, so direct casting is safe.
 */

#include "../c_interop/include/speech_ios.h"
#include "deviceai_speech_engine.h"

extern "C" {

bool speech_stt_init(const char *model_path, const char *language,
                     bool translate, int max_threads, bool use_gpu, bool use_vad) {
    // speech_ios.h omits single_segment / no_context; enable both for best perf.
    return dai_stt_init(model_path, language,
                        translate ? 1 : 0, max_threads, use_gpu ? 1 : 0,
                        use_vad ? 1 : 0,
                        /*single_segment=*/1,
                        /*no_context=*/1) != 0;
}

char *speech_stt_transcribe(const char *audio_path) {
    return dai_stt_transcribe_file(audio_path);
}

char *speech_stt_transcribe_detailed(const char *audio_path) {
    return dai_stt_transcribe_file_detailed(audio_path);
}

char *speech_stt_transcribe_audio(const float *samples, int n_samples) {
    return dai_stt_transcribe(samples, n_samples);
}

void speech_stt_transcribe_stream(const float *samples, int n_samples,
                                   stt_on_partial on_partial,
                                   stt_on_final on_final,
                                   stt_on_error on_error,
                                   void *user) {
    // stt_on_partial/final/error share identical signatures with dai_stt_*_cb.
    dai_stt_transcribe_stream(samples, n_samples,
                              (dai_stt_partial_cb)on_partial,
                              (dai_stt_final_cb)on_final,
                              (dai_stt_error_cb)on_error,
                              user);
}

void speech_stt_cancel(void) {
    dai_stt_cancel();
}

void speech_stt_shutdown(void) {
    dai_stt_shutdown();
}

void speech_free_string(char *ptr) {
    dai_speech_free_string(ptr);
}

// ─── TTS stubs (STT-only iOS builds) ─────────────────────────────────────────

#ifdef SPEECHKMP_STT_ONLY

bool speech_tts_init(const char *, const char *, const char *, int, float, int, float) {
    return false;
}

int16_t *speech_tts_synthesize(const char *, int *out_length) {
    *out_length = 0;
    return nullptr;
}

bool speech_tts_synthesize_to_file(const char *, const char *) { return false; }

void speech_tts_synthesize_stream(const char *, tts_on_chunk, tts_on_complete,
                                   tts_on_error on_error, void *user) {
    if (on_error) on_error("TTS not available in this build", user);
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

} // extern "C"
