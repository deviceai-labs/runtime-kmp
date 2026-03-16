/// Per-request generation parameters. Mirrors `LlmGenConfig` in kotlin/llm.
public struct LlmGenConfig: Sendable {
    public var maxTokens:     Int    = 512
    public var temperature:   Float  = 0.7
    public var topP:          Float  = 0.9
    public var topK:          Int    = 40
    public var repeatPenalty: Float  = 1.1
    public var ragStore:      (any Retrieving)? = nil
    public var ragTopK:       Int    = 3

    public init(maxTokens: Int = 512, temperature: Float = 0.7, topP: Float = 0.9,
                topK: Int = 40, repeatPenalty: Float = 1.1,
                ragStore: (any Retrieving)? = nil, ragTopK: Int = 3) {
        self.maxTokens = maxTokens; self.temperature = temperature
        self.topP = topP; self.topK = topK; self.repeatPenalty = repeatPenalty
        self.ragStore = ragStore; self.ragTopK = ragTopK
    }
}
