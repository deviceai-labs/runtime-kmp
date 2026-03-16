/// A synthesised audio chunk. Mirrors `AudioSegment` in kotlin/speech.
///
/// `samples` are 32-bit float PCM, normalised –1.0…1.0.
/// `sampleRate` is typically 22 050 Hz for VITS / Kokoro models.
public struct AudioSegment: Sendable {
    /// Raw PCM float samples (mono, 32-bit float, normalised –1.0…1.0).
    public let samples: [Float]
    /// Sample rate in Hz (e.g. 22 050).
    public let sampleRate: Int
    /// Duration derived from `samples.count / sampleRate` (seconds).
    public var durationSeconds: Double {
        sampleRate > 0 ? Double(samples.count) / Double(sampleRate) : 0
    }
}
