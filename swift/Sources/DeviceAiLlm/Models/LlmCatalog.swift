/// Curated on-device LLM models. Mirrors `LlmCatalog` in kotlin/llm exactly.
/// Ordered smallest → largest — right default for a model picker.
public enum LlmCatalog {

    public static let smolLM2_135M = LlmModelInfo(
        id: "smollm2-135m-q4", displayName: "SmolLM2 135M",
        sizeBytes: 90 * 1024 * 1024,
        repoId: "HuggingFaceTB/smollm2-135m-instruct-q4-gguf",
        filename: "smollm2-135m-instruct-q4_k_m.gguf",
        parameters: "135M", quantization: "Q4_K_M",
        description: "Fastest, lowest RAM. Good for simple completions."
    )
    public static let smolLM2_360M = LlmModelInfo(
        id: "smollm2-360m-q4", displayName: "SmolLM2 360M",
        sizeBytes: 240 * 1024 * 1024,
        repoId: "HuggingFaceTB/smollm2-360m-instruct-q4-gguf",
        filename: "smollm2-360m-instruct-q4_k_m.gguf",
        parameters: "360M", quantization: "Q4_K_M",
        description: "Step up from 135M. Better reasoning, still very fast."
    )
    public static let qwen25_05B = LlmModelInfo(
        id: "qwen25-0.5b-q4", displayName: "Qwen 2.5 0.5B",
        sizeBytes: 400 * 1024 * 1024,
        repoId: "Qwen/Qwen2.5-0.5B-Instruct-GGUF",
        filename: "qwen2.5-0.5b-instruct-q4_k_m.gguf",
        parameters: "0.5B", quantization: "Q4_K_M",
        description: "Strong multilingual support."
    )
    public static let llama32_1B = LlmModelInfo(
        id: "llama32-1b-q4", displayName: "Llama 3.2 1B",
        sizeBytes: 770 * 1024 * 1024,
        repoId: "bartowski/Llama-3.2-1B-Instruct-GGUF",
        filename: "Llama-3.2-1B-Instruct-Q4_K_M.gguf",
        parameters: "1B", quantization: "Q4_K_M",
        description: "Recommended default for most apps."
    )
    public static let llama32_3B = LlmModelInfo(
        id: "llama32-3b-q4", displayName: "Llama 3.2 3B",
        sizeBytes: 1900 * 1024 * 1024,
        repoId: "bartowski/Llama-3.2-3B-Instruct-GGUF",
        filename: "Llama-3.2-3B-Instruct-Q4_K_M.gguf",
        parameters: "3B", quantization: "Q4_K_M",
        description: "Strong reasoning. Requires 6 GB RAM device."
    )
    public static let gemma2_2B = LlmModelInfo(
        id: "gemma2-2b-q4", displayName: "Gemma 2 2B",
        sizeBytes: 1600 * 1024 * 1024,
        repoId: "bartowski/gemma-2-2b-it-GGUF",
        filename: "gemma-2-2b-it-Q4_K_M.gguf",
        parameters: "2B", quantization: "Q4_K_M",
        description: "Google's efficient 2B. Good instruction following."
    )
    public static let phi35Mini = LlmModelInfo(
        id: "phi35-mini-q4", displayName: "Phi 3.5 Mini",
        sizeBytes: 2300 * 1024 * 1024,
        repoId: "bartowski/Phi-3.5-mini-instruct-GGUF",
        filename: "Phi-3.5-mini-instruct-Q4_K_M.gguf",
        parameters: "3.8B", quantization: "Q4_K_M",
        description: "Best coding + math in this size range."
    )

    /// All models, smallest first. Use for a model picker UI.
    public static let all: [LlmModelInfo] = [
        smolLM2_135M, smolLM2_360M, qwen25_05B,
        llama32_1B, llama32_3B, gemma2_2B, phi35Mini,
    ]
}
