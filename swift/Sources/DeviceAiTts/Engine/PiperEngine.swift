import Foundation
import DeviceAiCore

// ── CSherpaOnnx interop ───────────────────────────────────────────────────────
// When CSherpaOnnx.xcframework is linked, uncomment the import below.
// The framework exposes the sherpa-onnx C API (SherpaOnnxOfflineTts).
// Matches the C API already used in the Kotlin bridge (piper_jni.cpp).
//
// import CSherpaOnnx
//
// VITS init (Amy):
//   var cfg = SherpaOnnxOfflineTtsConfig()
//   cfg.model.vits.model  = modelPath
//   cfg.model.vits.tokens = tokensPath
//   cfg.rule_fsts = ""
//   tts = SherpaOnnxCreateOfflineTts(&cfg)
//
// Kokoro init (add voices.bin):
//   cfg.model.vits.data_dir = dataDir
//   cfg.model.vits.model    = modelPath
//   (voices.bin sits alongside the .onnx — sherpa-onnx finds it automatically)
//
// Synthesis:
//   let audio = SherpaOnnxOfflineTtsGenerate(tts, text, speakerId, speakingRate)
//   defer { SherpaOnnxDestroyOfflineTtsGeneratedAudio(audio) }
//   let samples = Array(UnsafeBufferPointer(start: audio!.pointee.samples, count: Int(audio!.pointee.n)))
//   let sr      = Int(audio!.pointee.sample_rate)
// ─────────────────────────────────────────────────────────────────────────────

/// Internal Piper/Kokoro inference driver backed by sherpa-onnx.
///
/// Not thread-safe on its own — calls are serialized by `TtsSession`.
///
/// ## ABI version check (CSherpaOnnx)
/// When the binary is linked, guard:
/// ```swift
/// let binaryMin = SDKVersion(SherpaOnnxAbiVersion())
/// guard binaryMin >= SDKVersion.core else {
///     throw DeviceAiError.versionMismatch("CSherpaOnnx \(binaryMin) < core \(SDKVersion.core)")
/// }
/// ```
final class PiperEngine: Synthesizing, @unchecked Sendable {

    private let queue = DispatchQueue(
        label: "dev.deviceai.tts.piper",
        qos: .userInitiated
    )
    // Stub mode: start as loaded (no real binary to load).
    // When CSherpaOnnx is linked: change to false and gate on load() completing.
    private var modelLoaded  = true
    private var isCancelled  = false
    private var isClosed     = false

    // MARK: - Lifecycle

    func load(modelPath: String, tokensPath: String, voicesPath: String?) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            queue.async {
                // ── STUB ──
                // Replace with SherpaOnnxCreateOfflineTts(&cfg) call (see header above).
                DeviceAiLogger.info("PiperEngine", "load() stub — model not actually loaded")
                self.modelLoaded = true
                cont.resume()
            }
        }
    }

    func close() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            queue.async {
                // ── STUB ──
                // Replace with: SherpaOnnxDestroyOfflineTts(self.tts); self.tts = nil
                self.modelLoaded = false
                self.isClosed    = true
                cont.resume()
            }
        }
    }

    func cancel() {
        isCancelled = true
        // sherpa-onnx synthesis is single-shot; flag is checked between sentences.
    }

    // MARK: - Synthesis

    func synthesize(text: String, config: SynthesisConfig) async throws -> AudioSegment {
        try await withCheckedThrowingContinuation { cont in
            queue.async {
                self.isCancelled = false
                guard self.modelLoaded else {
                    cont.resume(throwing: DeviceAiError.modelLoadFailed(reason: "Piper model not loaded"))
                    return
                }
                // ── STUB ──
                // Replace with:
                //   let audio = SherpaOnnxOfflineTtsGenerate(
                //       tts, text, Int32(config.speakerId), config.speakingRate)
                //   defer { SherpaOnnxDestroyOfflineTtsGeneratedAudio(audio) }
                //   let samples = Array(UnsafeBufferPointer(start: audio!.pointee.samples,
                //                                           count: Int(audio!.pointee.n)))
                //   cont.resume(returning: AudioSegment(samples: samples,
                //                                       sampleRate: Int(audio!.pointee.sample_rate)))
                DeviceAiLogger.info("PiperEngine", "synthesize() stub — text='\(text)'")
                cont.resume(returning: AudioSegment(samples: [], sampleRate: 22_050))
            }
        }
    }

    // MARK: - Streaming

    func synthesizeStream(
        text: String,
        config: SynthesisConfig
    ) -> AsyncThrowingStream<AudioSegment, Error> {
        AsyncThrowingStream { continuation in
            queue.async {
                self.isCancelled = false
                guard self.modelLoaded else {
                    continuation.finish(throwing: DeviceAiError.modelLoadFailed(reason: "Piper model not loaded"))
                    return
                }
                // ── STUB ──
                // sherpa-onnx processes text sentence-by-sentence in the GenerateWithCallback API:
                //   SherpaOnnxOfflineTtsGenerateWithCallback(tts, text, speakerId, rate) { audio, _ in
                //       guard !self.isCancelled else { return 0 }   // 0 = abort
                //       let samples = Array(UnsafeBufferPointer(start: audio!.pointee.samples,
                //                                               count: Int(audio!.pointee.n)))
                //       continuation.yield(AudioSegment(samples: samples, sampleRate: sr))
                //       return 1   // 1 = continue
                //   }
                //   continuation.finish()
                DeviceAiLogger.info("PiperEngine", "synthesizeStream() stub — text='\(text)'")
                continuation.finish()
            }
        }
    }
}
