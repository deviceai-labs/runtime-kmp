import DeviceAiCore

/// Metadata for a downloadable GGUF model file.
/// Conforms to `ModelInfo` — `ModelManager<LlmModelInfo>` handles download/cache/delete.
public struct LlmModelInfo: ModelInfo {
    public let id: String
    public let displayName: String
    public let sizeBytes: Int64
    public let repoId: String
    public let filename: String
    public let parameters: String
    public let quantization: String
    public let description: String

    public init(id: String, displayName: String, sizeBytes: Int64, repoId: String,
                filename: String, parameters: String, quantization: String, description: String) {
        self.id = id; self.displayName = displayName; self.sizeBytes = sizeBytes
        self.repoId = repoId; self.filename = filename; self.parameters = parameters
        self.quantization = quantization; self.description = description
    }
}
