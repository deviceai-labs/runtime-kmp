/// Full transcription result. Mirrors `TranscriptionResult` + `Segment` in kotlin/speech exactly.
public struct TranscriptionResult: Sendable {
    public let text:      String
    public let segments:  [TranscriptionSegment]
    public let language:  String
    public let durationMs: Int64
}

public struct TranscriptionSegment: Sendable {
    public let text:    String
    public let startMs: Int64
    public let endMs:   Int64
}
