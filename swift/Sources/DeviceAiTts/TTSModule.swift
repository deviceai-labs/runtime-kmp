import DeviceAiCore

/// Entry point for TTS operations. Obtain via `DeviceAI.tts`.
///
/// ```swift
/// let session = try DeviceAI.tts.session(
///     modelPath:  voicePath,
///     tokensPath: tokensPath
/// )
/// let audio = try await session.synthesize(text: "Hello, world!")
/// ```
public final class TTSModule: @unchecked Sendable {

    static let shared = TTSModule()
    private init() {}

    // MARK: - Session factory

    /// Create a new TTS session.
    ///
    /// - Parameters:
    ///   - modelPath:   Absolute path to a Piper/Kokoro `.onnx` model file.
    ///   - tokensPath:  Absolute path to the phoneme tokens JSON (Piper) or `tokens.txt` (Kokoro).
    ///   - voicesPath:  Absolute path to `voices.bin` — required for Kokoro, omit for VITS/Piper.
    /// - Throws: `DeviceAiError.notInitialised` if `DeviceAI.configure()` has not been called.
    public func session(
        modelPath:  String,
        tokensPath: String,
        voicesPath: String? = nil
    ) throws -> TtsSession {
        try DeviceAI.assertConfigured()
        return TtsSession(modelPath: modelPath, tokensPath: tokensPath, voicesPath: voicesPath)
    }

    // MARK: - Model management

    /// Typed model manager for Piper/Kokoro voices.
    public var modelManager: TtsModelManager { .shared }
}
