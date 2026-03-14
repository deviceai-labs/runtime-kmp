package dev.deviceai.llm

/**
 * Configuration for LLM engine initialization.
 *
 * @param contextSize Maximum context window in tokens (default 2048)
 * @param maxThreads CPU threads for inference (default 4)
 * @param nGpuLayers Number of model layers to offload to GPU.
 *   0 = CPU-only; 99 (default) = offload all layers — llama.cpp clamps to
 *   the actual layer count, so 99 is safe for any model size.
 */
data class LlmInitConfig(
    val contextSize: Int = 2048,
    val maxThreads: Int = 4,
    val nGpuLayers: Int = 99
)
