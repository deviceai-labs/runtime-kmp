import Foundation
import DeviceAiCore

/// A loaded Whisper STT session.
///
/// Create via `DeviceAI.stt.session(modelPath:)` — never instantiate directly.
///
/// ## Concurrency contract
///
/// - `SttSession` is an `actor` — transcription calls are serialized.
/// - `cancel()` is `nonisolated` — callable from any thread without `await`.
/// - `close()` is idempotent — safe to call multiple times.
/// - `deinit` calls `close()` automatically.
/// - All methods throw `DeviceAiError.sessionClosed` after `close()`.
///
/// ## Kotlin parallel
/// Mirrors the `SpeechBridge` STT API with typed errors and async/await
/// replacing the Boolean-init + empty-string-on-failure pattern.
public actor SttSession {

    private let engine: WhisperEngine
    private var closed = false

    init(modelPath: String) {
        engine = WhisperEngine()
        Task { try? await self.engine.load(modelPath: modelPath) }
    }

    public var isClosed: Bool { closed }

    // ── Transcription ─────────────────────────────────────────────────────────

    /// Transcribe a WAV file (16kHz, mono, 16-bit PCM).
    /// Mirrors `SpeechBridge.transcribeDetailed(audioPath:)` in kotlin/speech.
    public func transcribe(
        audioPath: String,
        config: TranscriptionConfig = TranscriptionConfig()
    ) async throws -> TranscriptionResult {
        try assertOpen()
        return try await engine.transcribe(audioPath: audioPath, config: config)
    }

    /// Transcribe raw PCM float samples (16kHz, mono, normalised –1.0…1.0).
    /// Mirrors `SpeechBridge.transcribeAudio(samples:)` in kotlin/speech.
    public func transcribe(
        samples: [Float],
        config: TranscriptionConfig = TranscriptionConfig()
    ) async throws -> TranscriptionResult {
        try assertOpen()
        return try await engine.transcribe(samples: samples, config: config)
    }

    /// Stream partial transcription tokens as the audio is processed.
    /// Mirrors `SpeechBridge.transcribeStream(samples:callback:)` with callbacks
    /// replaced by `AsyncThrowingStream`.
    public func transcribeStream(
        samples: [Float],
        config: TranscriptionConfig = TranscriptionConfig()
    ) -> AsyncThrowingStream<String, Error> {
        guard !closed else {
            return AsyncThrowingStream { $0.finish(throwing: DeviceAiError.sessionClosed) }
        }
        return engine.transcribeStream(samples: samples, config: config)
    }

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    /// Cancel any in-progress transcription. `nonisolated` — callable from any thread.
    public nonisolated func cancel() { engine.cancel() }

    /// Unload the Whisper model and release all resources. Idempotent.
    public func close() async {
        guard !closed else { return }
        closed = true
        await engine.close()
        DeviceAiLogger.info("SttSession", "Closed.")
    }

    deinit { engine.cancel() }  // synchronous; engine.deinit releases C++ resources

    private func assertOpen() throws {
        guard !closed else { throw DeviceAiError.sessionClosed }
    }
}
