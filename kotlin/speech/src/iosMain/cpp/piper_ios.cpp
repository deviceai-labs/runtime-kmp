/**
 * piper_ios.cpp
 *
 * Thin C delegate — forwards the legacy speech_tts_* iOS API to the unified
 * dai_tts_* API in deviceai_speech_engine.{h,cpp}.
 *
 * No TTS logic lives here. The Swift cinterop def still references speech_ios.h,
 * so legacy speech_tts_* symbols are kept as shims.
 *
 * Callback types share the same function signatures, so direct casting is safe.
 */

#include "../c_interop/include/speech_ios.h"
#include "deviceai_speech_engine.h"

extern "C" {

bool speech_tts_init(const char *model_path, const char *config_path,
                     const char *espeak_data_path, int speaker_id,
                     float speech_rate, int sample_rate, float sentence_silence) {
    return dai_tts_init(model_path, config_path, espeak_data_path,
                        speaker_id, speech_rate, sample_rate,
                        sentence_silence) != 0;
}

int16_t *speech_tts_synthesize(const char *text, int *out_length) {
    return dai_tts_synthesize(text, out_length);
}

bool speech_tts_synthesize_to_file(const char *text, const char *output_path) {
    return dai_tts_synthesize_to_file(text, output_path) != 0;
}

void speech_tts_synthesize_stream(const char *text,
                                   tts_on_chunk on_chunk,
                                   tts_on_complete on_complete,
                                   tts_on_error on_error,
                                   void *user) {
    // tts_on_chunk/complete/error share identical signatures with dai_tts_*_cb.
    dai_tts_synthesize_stream(text,
                              (dai_tts_chunk_cb)on_chunk,
                              (dai_tts_complete_cb)on_complete,
                              (dai_tts_error_cb)on_error,
                              user);
}

void speech_tts_cancel(void) {
    dai_tts_cancel();
}

void speech_tts_shutdown(void) {
    dai_tts_shutdown();
}

void speech_free_audio(int16_t *ptr) {
    dai_speech_free_audio(ptr);
}

void speech_shutdown_all(void) {
    dai_speech_shutdown_all();
}

} // extern "C"
