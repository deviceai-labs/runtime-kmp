package dev.deviceai.llm

/**
 * Configuration for LLM engine initialization.
 *
 * Context window size is intentionally omitted — llama.cpp reads it directly
 * from the model's GGUF metadata and uses the model's native context length.
 *
 * @param maxThreads CPU threads for inference (default 4)
 * @param useGpu Use GPU acceleration — Metal on iOS, Vulkan on Android (default true)
 */
data class LlmInitConfig(
    val maxThreads: Int = 4,
    val useGpu: Boolean = true,
)
