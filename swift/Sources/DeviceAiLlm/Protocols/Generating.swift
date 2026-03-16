/// Internal contract for LLM inference backends.
/// `LlamaEngine` is the only production conformer — never exposed publicly.
/// Tests inject a mock without needing a GGUF model.
protocol Generating: AnyObject, Sendable {
    func load(modelPath: String, config: ChatConfig) async throws
    func generate(messages: [LlmMessage], config: LlmGenConfig) async throws -> LlmResult
    func generateStream(messages: [LlmMessage], config: LlmGenConfig) -> AsyncThrowingStream<String, Error>
    func cancel()
    func close() async
}
