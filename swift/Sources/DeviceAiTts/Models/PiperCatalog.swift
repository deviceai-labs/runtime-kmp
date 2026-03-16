import DeviceAiCore

/// Piper / Kokoro voice descriptor. Conforms to `ModelInfo` — `TtsModelManager` handles download.
public struct PiperModelInfo: ModelInfo {
    public let id: String
    public let displayName: String
    public let sizeBytes: Int64
    public let repoId: String
    public let filename: String
    /// Path to `voices.bin` inside the same HuggingFace repo (Kokoro only; nil = VITS).
    public let voicesFilename: String?
    public let tokensFilename: String
    public let tier: String
}

/// Curated Piper / Kokoro voices. Mirrors `PiperCatalog` in kotlin/speech.
public enum PiperCatalog {
    public static let enUSAmy = PiperModelInfo(
        id:              "piper-en-us-amy",
        displayName:     "Amy (US English)",
        sizeBytes:       63 * 1024 * 1024,
        repoId:          "rhasspy/piper-voices",
        filename:        "en/en_US/amy/medium/en_US-amy-medium.onnx",
        voicesFilename:  nil,
        tokensFilename:  "en/en_US/amy/medium/en_US-amy-medium.onnx.json",
        tier:            "medium"
    )
    public static let enUSKokoro = PiperModelInfo(
        id:              "kokoro-en-us",
        displayName:     "Kokoro (US English)",
        sizeBytes:       310 * 1024 * 1024,
        repoId:          "hexgrad/Kokoro-82M",
        filename:        "kokoro-v0_19.onnx",
        voicesFilename:  "voices.bin",
        tokensFilename:  "tokens.txt",
        tier:            "high"
    )
    public static let all: [PiperModelInfo] = [enUSAmy, enUSKokoro]
}
