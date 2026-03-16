/// Why generation stopped. Mirrors `FinishReason` in kotlin/llm — identical cases.
public enum FinishReason: String, Sendable, Codable {
    case stop
    case maxTokens = "max_tokens"
    case cancelled
    case error
}
