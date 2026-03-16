/// A retrieved text chunk. Mirrors `RagChunk` in kotlin/llm.
public struct RagChunk: Sendable {
    public let text:   String
    public let source: String?
    public let score:  Float

    public init(text: String, source: String? = nil, score: Float) {
        self.text = text; self.source = source; self.score = score
    }
}
