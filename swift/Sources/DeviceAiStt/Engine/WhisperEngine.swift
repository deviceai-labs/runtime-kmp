import Foundation
import DeviceAiCore

// ── CWhisper interop ──────────────────────────────────────────────────────────
// When CWhisper.xcframework is linked, uncomment the import below.
// The framework exposes the whisper.cpp C API — same header we already use
// in the Kotlin/JNI bridge (whisper_jni.cpp / whisper.h).
//
// import CWhisper
//
// Stub mode is used while the binary is not yet built.  All methods succeed
// immediately with empty / minimal results so the rest of the SDK compiles
// and unit tests run on CI without requiring the binary.
// ─────────────────────────────────────────────────────────────────────────────

/// Internal Whisper inference driver.
///
/// `WhisperEngine` is not thread-safe by itself — all calls must be
/// serialized by the owning `SttSession` actor.
///
/// ## Concurrency model
/// Heavy C++ work is dispatched to a private serial `DispatchQueue` via
/// `withCheckedThrowingContinuation`, keeping the actor queue free.
///
/// ## ABI version check (CWhisper)
/// When you link the real binary, add:
/// ```swift
/// let binaryMin = SDKVersion(whisper_abi_version())   // hypothetical C export
/// guard binaryMin >= SDKVersion.core else {
///     throw DeviceAiError.versionMismatch(
///         "CWhisper \(binaryMin) < core \(SDKVersion.core)")
/// }
/// ```
final class WhisperEngine: Transcribing, @unchecked Sendable {

    private let queue = DispatchQueue(
        label: "dev.deviceai.stt.whisper",
        qos: .userInitiated
    )
    // Stub mode: start as loaded (no real binary to load).
    // When CWhisper is linked: change to false and gate on load() completing.
    private var modelLoaded = true
    private var isCancelled = false
    private var isClosed    = false

    // MARK: - Lifecycle

    func load(modelPath: String) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                // ── STUB ──
                // Replace with:
                //   guard let ctx = whisper_init_from_file(modelPath) else {
                //       cont.resume(throwing: DeviceAiError.modelLoadFailed("whisper_init_from_file returned nil"))
                //       return
                //   }
                //   self.ctx = ctx
                DeviceAiLogger.info("WhisperEngine", "load(modelPath:) stub — model not actually loaded")
                self.modelLoaded = true
                cont.resume()
            }
        }
    }

    func close() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            queue.async {
                // ── STUB ──
                // Replace with: if let ctx = self.ctx { whisper_free(ctx); self.ctx = nil }
                self.modelLoaded = false
                self.isClosed    = true
                cont.resume()
            }
        }
    }

    func cancel() {
        isCancelled = true
        // ── STUB ──
        // Replace with: whisper_abort(ctx)  (whisper.cpp cancel support)
    }

    // MARK: - Transcription (file path)

    func transcribe(
        audioPath: String,
        config: TranscriptionConfig
    ) async throws -> TranscriptionResult {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                self.isCancelled = false
                guard self.modelLoaded else {
                    cont.resume(throwing: DeviceAiError.modelLoadFailed(reason: "Whisper model not loaded"))
                    return
                }
                // ── STUB ──
                // Replace with full whisper_full() invocation using audioPath.
                // 1. Load PCM samples from WAV via AudioFile / AVAudioFile
                // 2. Build whisper_full_params from TranscriptionConfig
                // 3. Call whisper_full(ctx, params, samples, n_samples)
                // 4. Iterate whisper_full_n_segments, whisper_full_get_segment_text
                // 5. Return populated TranscriptionResult
                DeviceAiLogger.info("WhisperEngine", "transcribe(audioPath:) stub")
                cont.resume(returning: .empty)
            }
        }
    }

    // MARK: - Transcription (raw samples)

    func transcribe(
        samples: [Float],
        config: TranscriptionConfig
    ) async throws -> TranscriptionResult {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                self.isCancelled = false
                guard self.modelLoaded else {
                    cont.resume(throwing: DeviceAiError.modelLoadFailed(reason: "Whisper model not loaded"))
                    return
                }
                // ── STUB ──
                // Replace with:
                //   let params = Self.makeParams(config: config, nSamples: samples.count)
                //   let rc = samples.withUnsafeBufferPointer { buf in
                //       whisper_full(ctx, params, buf.baseAddress, Int32(samples.count))
                //   }
                //   guard rc == 0 else { throw DeviceAiError.inferenceFailed("whisper_full rc=\(rc)") }
                //   cont.resume(returning: Self.collectResult(ctx: ctx))
                DeviceAiLogger.info("WhisperEngine", "transcribe(samples:) stub — \(samples.count) samples")
                cont.resume(returning: .empty)
            }
        }
    }

    // MARK: - Streaming

    func transcribeStream(
        samples: [Float],
        config: TranscriptionConfig
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            queue.async {
                self.isCancelled = false
                guard self.modelLoaded else {
                    continuation.finish(throwing: DeviceAiError.modelLoadFailed(reason: "Whisper model not loaded"))
                    return
                }
                // ── STUB ──
                // whisper.cpp processes audio in a single batch; streaming is simulated
                // by emitting each segment as it is decoded:
                //   for i in 0 ..< whisper_full_n_segments(ctx) {
                //       guard !self.isCancelled else { continuation.finish(throwing: DeviceAiError.cancelled); return }
                //       let text = String(cString: whisper_full_get_segment_text(ctx, i))
                //       continuation.yield(text)
                //   }
                //   continuation.finish()
                DeviceAiLogger.info("WhisperEngine", "transcribeStream(samples:) stub")
                continuation.finish()
            }
        }
    }

    // MARK: - Helpers

    // ── STUB ──
    // Replace with: build whisper_full_params from TranscriptionConfig
    // private static func makeParams(config: TranscriptionConfig, nSamples: Int) -> whisper_full_params { ... }
    //
    // Replace with: collect all segments + language + timing into TranscriptionResult
    // private static func collectResult(ctx: OpaquePointer) -> TranscriptionResult { ... }
}

// MARK: - Convenience

private extension TranscriptionResult {
    static let empty = TranscriptionResult(
        text: "",
        segments: [],
        language: "en",
        durationMs: 0
    )
}
