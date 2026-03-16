import Foundation

/// STT configuration. Mirrors `SttConfig` in kotlin/speech — identical fields and defaults.
public final class TranscriptionConfig: @unchecked Sendable {
    public var language:           String?  = nil      // nil = autodetect
    public var translateToEnglish: Bool     = false
    public var maxThreads:         Int      = max(1, ProcessInfo.processInfo.processorCount / 2)
    public var useGpu:             Bool     = true
    public var useVad:             Bool     = true
    public var singleSegment:      Bool     = true
    public var noContext:          Bool     = true
    public init() {}
}
