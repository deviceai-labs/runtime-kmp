/// Internal contract for TTS engines. `PiperEngine` is the only production conformer.
protocol Synthesizing: AnyObject, Sendable {
    func load(modelPath: String, tokensPath: String, voicesPath: String?) async throws
    func synthesize(text: String, config: SynthesisConfig) async throws -> AudioSegment
    func synthesizeStream(text: String, config: SynthesisConfig) -> AsyncThrowingStream<AudioSegment, Error>
    func cancel()
    func close() async
}
