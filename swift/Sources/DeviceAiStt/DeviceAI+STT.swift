import DeviceAiCore

public extension DeviceAI {
    /// Access STT operations.
    ///
    /// ```swift
    /// DeviceAI.configure()
    /// let session = try DeviceAI.stt.session(modelPath: modelPath)
    /// let result  = try await session.transcribe(samples: pcm)
    /// ```
    static var stt: STTModule { STTModule.shared }
}
