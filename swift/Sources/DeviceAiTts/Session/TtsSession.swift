import Foundation
import DeviceAiCore

/// A loaded Piper/Kokoro TTS session.
///
/// Create via `DeviceAI.tts.session(modelPath:tokensPath:voicesPath:)` —
/// never instantiate directly.
///
/// ## Concurrency contract
///
/// - `TtsSession` is an `actor` — synthesis calls are serialized.
/// - `cancel()` is `nonisolated` — callable from any thread without `await`.
/// - `close()` is idempotent — safe to call multiple times.
/// - `deinit` calls `close()` automatically.
/// - All methods throw `DeviceAiError.sessionClosed` after `close()`.
///
/// ## Kotlin parallel
/// Mirrors the `SpeechBridge` TTS API with typed errors and async/await
/// replacing the callback + Boolean pattern.
public actor TtsSession {

    private let engine: PiperEngine
    private var closed = false

    init(modelPath: String, tokensPath: String, voicesPath: String?) {
        engine = PiperEngine()
        Task { try? await self.engine.load(
            modelPath:  modelPath,
            tokensPath: tokensPath,
            voicesPath: voicesPath
        )}
    }

    public var isClosed: Bool { closed }

    // ── Synthesis ──────────────────────────────────────────────────────────────

    /// Synthesise `text` and return the full audio buffer.
    /// Mirrors `SpeechBridge.synthesize(text:)` in kotlin/speech.
    public func synthesize(
        text: String,
        config: SynthesisConfig = SynthesisConfig()
    ) async throws -> AudioSegment {
        try assertOpen()
        return try await engine.synthesize(text: text, config: config)
    }

    /// Stream synthesised audio sentence-by-sentence.
    /// Mirrors `SpeechBridge.synthesizeStream(text:callback:)` with callbacks
    /// replaced by `AsyncThrowingStream`.
    public func synthesizeStream(
        text: String,
        config: SynthesisConfig = SynthesisConfig()
    ) -> AsyncThrowingStream<AudioSegment, Error> {
        guard !closed else {
            return AsyncThrowingStream { $0.finish(throwing: DeviceAiError.sessionClosed) }
        }
        return engine.synthesizeStream(text: text, config: config)
    }

    // ── Lifecycle ──────────────────────────────────────────────────────────────

    /// Cancel any in-progress synthesis. `nonisolated` — callable from any thread.
    public nonisolated func cancel() { engine.cancel() }

    /// Unload the Piper model and release all resources. Idempotent.
    public func close() async {
        guard !closed else { return }
        closed = true
        await engine.close()
        DeviceAiLogger.info("TtsSession", "Closed.")
    }

    deinit { engine.cancel() }  // synchronous; engine.deinit releases C++ resources

    private func assertOpen() throws {
        guard !closed else { throw DeviceAiError.sessionClosed }
    }
}
