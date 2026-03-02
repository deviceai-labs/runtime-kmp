#ifndef SPEECH_IOS_H
#define SPEECH_IOS_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

// ═══════════════════════════════════════════════════════════════
//                            STT API
// ═══════════════════════════════════════════════════════════════

/**
 * Initialize the STT engine with a Whisper model.
 *
 * @param model_path Absolute path to .bin model file (ggml format)
 * @param language Language code (ISO 639-1), e.g., "en", "es", "auto"
 * @param translate If true, translate non-English speech to English
 * @param max_threads Number of CPU threads for inference
 * @param use_gpu Use GPU acceleration if available (Metal)
 * @param use_vad Enable voice activity detection
 * @return true if initialization succeeded
 */
bool speech_stt_init(const char *model_path, const char *language,
                     bool translate, int max_threads, bool use_gpu, bool use_vad);

/**
 * Transcribe an audio file to text.
 *
 * @param audio_path Path to WAV file (16kHz, mono, 16-bit PCM)
 * @return Transcribed text (caller must free with speech_free_string)
 */
char *speech_stt_transcribe(const char *audio_path);

/**
 * Transcribe with detailed results including timestamps.
 *
 * @param audio_path Path to WAV file
 * @return JSON string with transcription result (caller must free)
 */
char *speech_stt_transcribe_detailed(const char *audio_path);

/**
 * Transcribe raw PCM audio samples.
 *
 * @param samples Float array of audio samples (16kHz, mono, normalized -1.0 to 1.0)
 * @param n_samples Number of samples
 * @return Transcribed text (caller must free with speech_free_string)
 */
char *speech_stt_transcribe_audio(const float *samples, int n_samples);

/**
 * Cancel ongoing transcription.
 */
void speech_stt_cancel(void);

/**
 * Release STT resources and unload model.
 */
void speech_stt_shutdown(void);

// Streaming callbacks
typedef void (*stt_on_partial)(const char *text, void *user);
typedef void (*stt_on_final)(const char *json_result, void *user);
typedef void (*stt_on_error)(const char *message, void *user);

/**
 * Stream transcription with real-time callbacks.
 *
 * @param samples Audio samples to transcribe
 * @param n_samples Number of samples
 * @param on_partial Callback for partial results
 * @param on_final Callback for final result (JSON)
 * @param on_error Callback for errors
 * @param user User data passed to callbacks
 */
void speech_stt_transcribe_stream(const float *samples, int n_samples,
                                   stt_on_partial on_partial,
                                   stt_on_final on_final,
                                   stt_on_error on_error,
                                   void *user);

// ═══════════════════════════════════════════════════════════════
//                            TTS API
// ═══════════════════════════════════════════════════════════════

/**
 * Initialize the TTS engine with a Piper voice model.
 *
 * @param model_path Absolute path to .onnx model file
 * @param config_path Absolute path to model's .json config file
 * @param espeak_data_path Absolute path to espeak-ng-data directory
 * @param speaker_id Speaker ID for multi-speaker models (-1 for default)
 * @param speech_rate Speech rate multiplier (1.0 = normal)
 * @param sample_rate Output sample rate in Hz
 * @param sentence_silence Seconds of silence between sentences
 * @return true if initialization succeeded
 */
bool speech_tts_init(const char *model_path, const char *config_path,
                     const char *espeak_data_path, int speaker_id,
                     float speech_rate, int sample_rate, float sentence_silence);

/**
 * Synthesize text to audio samples.
 *
 * @param text Text to synthesize
 * @param out_length Output: number of samples
 * @return PCM audio samples (16-bit signed, caller must free with speech_free_audio)
 */
int16_t *speech_tts_synthesize(const char *text, int *out_length);

/**
 * Synthesize text directly to a WAV file.
 *
 * @param text Text to synthesize
 * @param output_path Path for output WAV file
 * @return true if file was written successfully
 */
bool speech_tts_synthesize_to_file(const char *text, const char *output_path);

/**
 * Cancel ongoing synthesis.
 */
void speech_tts_cancel(void);

/**
 * Release TTS resources and unload model.
 */
void speech_tts_shutdown(void);

// Streaming callbacks
typedef void (*tts_on_chunk)(const int16_t *samples, int n_samples, void *user);
typedef void (*tts_on_complete)(void *user);
typedef void (*tts_on_error)(const char *message, void *user);

/**
 * Stream synthesis with audio chunk callbacks.
 *
 * @param text Text to synthesize
 * @param on_chunk Callback for audio chunks
 * @param on_complete Callback when synthesis is complete
 * @param on_error Callback for errors
 * @param user User data passed to callbacks
 */
void speech_tts_synthesize_stream(const char *text,
                                   tts_on_chunk on_chunk,
                                   tts_on_complete on_complete,
                                   tts_on_error on_error,
                                   void *user);

// ═══════════════════════════════════════════════════════════════
//                           UTILITIES
// ═══════════════════════════════════════════════════════════════

/**
 * Free a string returned by speech functions.
 */
void speech_free_string(char *ptr);

/**
 * Free audio samples returned by speech functions.
 */
void speech_free_audio(int16_t *ptr);

/**
 * Shutdown both STT and TTS, releasing all resources.
 */
void speech_shutdown_all(void);

#ifdef __cplusplus
}
#endif

#endif // SPEECH_IOS_H
