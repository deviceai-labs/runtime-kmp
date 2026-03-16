import Foundation

/// Result of a completed generation. Mirrors `LlmResult` in kotlin/llm.
///
/// Note: `promptTokenCount` is `Int?` here (not `Int`).
/// The Kotlin side hardcodes `0` on iOS — that's a lie.
/// `nil` means "not available from this engine", which is honest.
public struct LlmResult: Sendable {
    public let text: String
    public let tokenCount: Int
    /// `nil` when the engine does not report prompt token count.
    public let promptTokenCount: Int?
    public let finishReason: FinishReason
    public let generationTimeMs: Int64

    public var tokensPerSecond: Double? {
        guard generationTimeMs > 0 else { return nil }
        return Double(tokenCount) / (Double(generationTimeMs) / 1000)
    }
}
