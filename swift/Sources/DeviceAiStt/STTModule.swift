import DeviceAiCore

/// Entry point for STT operations. Obtain via `DeviceAI.stt`.
///
/// ```swift
/// let session = try DeviceAI.stt.session(modelPath: path)
/// let result  = try await session.transcribe(samples: pcm)
/// ```
public final class STTModule: @unchecked Sendable {

    static let shared = STTModule()
    private init() {}

    // MARK: - Session factory

    /// Create a new STT session with a pre-downloaded Whisper model.
    ///
    /// The model is loaded asynchronously in the background — the first
    /// `transcribe` call will block until loading completes.
    ///
    /// - Parameter modelPath: Absolute path to a ggml-format `.bin` file.
    /// - Returns: A ready-to-use `SttSession` actor.
    /// - Throws: `DeviceAiError.notInitialised` if `DeviceAI.configure()` has not been called.
    public func session(modelPath: String) throws -> SttSession {
        try DeviceAI.assertConfigured()
        return SttSession(modelPath: modelPath)
    }

    // MARK: - Model management

    /// Typed model manager for Whisper models. Mirrors `SpeechBridge.modelManager` in Kotlin.
    public var modelManager: SttModelManager { .shared }
}
