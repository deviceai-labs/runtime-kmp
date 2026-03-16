import DeviceAiCore

public extension DeviceAI {
    /// Access TTS operations.
    ///
    /// ```swift
    /// DeviceAI.configure()
    /// let session = try DeviceAI.tts.session(modelPath: modelPath, tokensPath: tokensPath)
    /// let audio   = try await session.synthesize(text: "Hello, world!")
    /// ```
    static var tts: TTSModule { TTSModule.shared }
}
