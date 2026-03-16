/// Internal contract for STT engines. `WhisperEngine` is the only production conformer.
protocol Transcribing: AnyObject, Sendable {
    func load(modelPath: String) async throws
    func transcribe(audioPath: String, config: TranscriptionConfig) async throws -> TranscriptionResult
    func transcribe(samples: [Float],  config: TranscriptionConfig) async throws -> TranscriptionResult
    func transcribeStream(samples: [Float], config: TranscriptionConfig) -> AsyncThrowingStream<String, Error>
    func cancel()
    func close() async
}
