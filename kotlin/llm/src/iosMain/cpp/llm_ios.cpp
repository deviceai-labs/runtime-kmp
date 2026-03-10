/**
 * llm_ios.cpp
 *
 * Thin C delegate — forwards the legacy llm_* iOS API to the unified
 * dai_llm_* API in deviceai_llm_engine.{h,cpp}.
 *
 * No inference logic lives here. The Kotlin Swift cinterop def file still
 * references llm_ios.h, so the legacy llm_* symbols are kept as shims.
 */

#include "../c_interop/include/llm_ios.h"
#include "deviceai_llm_engine.h"

extern "C" {

bool llm_init(const char *model_path, int context_size, int max_threads, bool use_gpu) {
    return dai_llm_init(model_path, context_size, max_threads, use_gpu ? 1 : 0) != 0;
}

void llm_shutdown(void) {
    dai_llm_shutdown();
}

char *llm_generate(
    const char **roles, const char **contents, int count,
    int max_tokens, float temperature,
    float top_p, int top_k, float repeat_penalty
) {
    // dai_llm_generate returns malloc'd string; llm_free_string → free() frees it.
    return dai_llm_generate(roles, contents, count,
                            max_tokens, temperature, top_p, top_k, repeat_penalty);
}

void llm_generate_stream(
    const char **roles, const char **contents, int count,
    int max_tokens, float temperature,
    float top_p, int top_k, float repeat_penalty,
    llm_on_token on_token,
    llm_on_error on_error,
    void *user
) {
    // llm_on_token and dai_llm_token_cb share the same signature: (const char*, void*)
    dai_llm_generate_stream(
        roles, contents, count,
        max_tokens, temperature, top_p, top_k, repeat_penalty,
        (dai_llm_token_cb)on_token,
        (dai_llm_error_cb)on_error,
        user
    );
}

void llm_cancel(void) {
    dai_llm_cancel();
}

void llm_free_string(char *ptr) {
    dai_llm_free_string(ptr);
}

} // extern "C"
