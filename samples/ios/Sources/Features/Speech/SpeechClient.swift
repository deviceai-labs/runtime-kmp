import ComposableArchitecture
import AVFoundation
import DeviceAiStt

// MARK: - Dependency

struct SpeechClient: Sendable {
    var startRecording: @Sendable () async -> Void
    var stopRecording:  @Sendable () async -> [Float]
    /// Transcribe PCM samples using the model at `modelPath`.
    var transcribe:     @Sendable ([Float], String) async throws -> TranscriptionResult
}

extension SpeechClient: DependencyKey {
    static let liveValue: SpeechClient = {
        let recorder     = AudioRecorder()
        let sessionCache = SttSessionCache()

        return SpeechClient(
            startRecording: { await recorder.start() },
            stopRecording:  { await recorder.stop() },
            transcribe: { samples, modelPath in
                let session = try await sessionCache.session(for: modelPath)
                return try await session.transcribe(samples: samples)
            }
        )
    }()

    static let previewValue = SpeechClient(
        startRecording: { },
        stopRecording:  { Array(repeating: 0, count: 16_000) },
        transcribe:     { _, _ in
            TranscriptionResult(
                text: "Preview transcription — runs fully on-device with Whisper.",
                segments: [],
                language: "en",
                durationMs: 1000
            )
        }
    )
}

extension DependencyValues {
    var speechClient: SpeechClient {
        get { self[SpeechClient.self] }
        set { self[SpeechClient.self] = newValue }
    }
}

// MARK: - Session cache (re-uses session while model path is unchanged)

private actor SttSessionCache {
    private var session: SttSession?
    private var currentPath: String?

    func session(for path: String) throws -> SttSession {
        if currentPath == path, let s = session { return s }
        let s = try DeviceAI.stt.session(modelPath: path)
        session     = s
        currentPath = path
        return s
    }
}

// MARK: - Audio recorder (AVAudioEngine-based, 16 kHz mono float32)

private actor AudioRecorder {
    private var engine:     AVAudioEngine?
    private var samples:    [Float] = []
    private let sampleRate: Double  = 16_000

    func start() {
        samples = []
        let eng   = AVAudioEngine()
        engine    = eng
        let input = eng.inputNode
        let fmt   = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate:   sampleRate,
            channels:     1,
            interleaved:  false
        )!

        input.installTap(onBus: 0, bufferSize: 4096, format: fmt) { [weak self] buf, _ in
            guard let ch = buf.floatChannelData?[0] else { return }
            let frame = Array(UnsafeBufferPointer(start: ch, count: Int(buf.frameLength)))
            Task { await self?.append(frame) }
        }

        try? eng.start()
    }

    func stop() -> [Float] {
        engine?.inputNode.removeTap(onBus: 0)
        engine?.stop()
        engine = nil
        return samples
    }

    private func append(_ frame: [Float]) { samples.append(contentsOf: frame) }
}

// MARK: - localPath helper

private extension WhisperModelInfo {
    var localPathString: String {
        DeviceAI.stt.modelManager.localPath(for: self).path
    }
}
