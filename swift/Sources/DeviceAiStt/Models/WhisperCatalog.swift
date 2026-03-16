import DeviceAiCore

/// Whisper model descriptor. Conforms to `ModelInfo` — `SttModelManager` handles download.
public struct WhisperModelInfo: ModelInfo {
    public let id: String
    public let displayName: String
    public let sizeBytes: Int64
    public let repoId: String
    public let filename: String
    public let tier: String
}

/// Curated Whisper models. Mirrors `WhisperCatalog` in kotlin/speech.
public enum WhisperCatalog {
    public static let tiny = WhisperModelInfo(
        id: "whisper-tiny", displayName: "Whisper Tiny",
        sizeBytes: 77 * 1024 * 1024,
        repoId: "ggerganov/whisper.cpp", filename: "ggml-tiny.bin", tier: "tiny"
    )
    public static let base = WhisperModelInfo(
        id: "whisper-base", displayName: "Whisper Base",
        sizeBytes: 148 * 1024 * 1024,
        repoId: "ggerganov/whisper.cpp", filename: "ggml-base.bin", tier: "base"
    )
    public static let small = WhisperModelInfo(
        id: "whisper-small", displayName: "Whisper Small",
        sizeBytes: 488 * 1024 * 1024,
        repoId: "ggerganov/whisper.cpp", filename: "ggml-small.bin", tier: "small"
    )
    public static let all: [WhisperModelInfo] = [tiny, base, small]
}
