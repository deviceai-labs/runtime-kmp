import DeviceAiCore

/// Extends the `DeviceAI` namespace with the `.llm` entry point.
/// This extension lives in `DeviceAiLlm` — only compiled when the app adds that product.
///
/// ## Kotlin parallel
/// ```kotlin
/// val DeviceAI.llm: LlmModule get() = LlmModule   // in :llm module
/// ```
extension DeviceAI {
    public static var llm: LLMModule { .shared }
}

// ── LLMModule ─────────────────────────────────────────────────────────────────

/// LLM inference namespace. Access via `DeviceAI.llm`.
public final class LLMModule: Sendable {

    static let shared = LLMModule()
    private init() {}

    /// Create a new `ChatSession`.
    ///
    /// ```swift
    /// // Minimal
    /// let session = DeviceAI.llm.chat(modelPath: "/path/to/model.gguf")
    ///
    /// // Configured
    /// let session = DeviceAI.llm.chat(modelPath: "/path/to/model.gguf") {
    ///     $0.systemPrompt = "You are a helpful assistant."
    ///     $0.temperature  = 0.8
    ///     $0.maxTokens    = 512
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - modelPath: Absolute path to a `.gguf` model file.
    ///   - configure: Optional closure to customise `ChatConfig`.
    public func chat(
        modelPath: String,
        configure: ((ChatConfig) -> Void)? = nil
    ) -> ChatSession {
        let config = ChatConfig()
        configure?(config)
        return ChatSession(modelPath: modelPath, config: config)
    }
}
