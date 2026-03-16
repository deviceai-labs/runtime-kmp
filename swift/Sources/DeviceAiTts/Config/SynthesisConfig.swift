import Foundation

/// TTS configuration. Mirrors `TtsConfig` in kotlin/speech — identical fields and defaults.
public final class SynthesisConfig: @unchecked Sendable {
    /// Speaker ID for multi-speaker models (0 = default).
    public var speakerId:   Int    = 0
    /// Speaking rate multiplier (1.0 = normal, 0.5 = half speed, 2.0 = double speed).
    public var speakingRate: Float = 1.0
    /// Noise scale for VITS vocoder (0.667 is the piper default).
    public var noiseScale:   Float = 0.667
    /// Noise width for VITS vocoder (0.8 is the piper default).
    public var noiseW:       Float = 0.8
    /// Maximum threads (nil = ProcessInfo.processorCount / 2, minimum 1).
    public var maxThreads:   Int   = max(1, ProcessInfo.processInfo.processorCount / 2)
    public init() {}
}
