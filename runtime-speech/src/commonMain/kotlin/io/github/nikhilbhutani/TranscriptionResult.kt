package io.github.nikhilbhutani

/**
 * Detailed result from speech-to-text transcription.
 */
data class TranscriptionResult(
    /**
     * Full transcribed text.
     */
    val text: String,

    /**
     * Individual segments with timing information.
     */
    val segments: List<Segment>,

    /**
     * Detected or specified language code.
     */
    val language: String,

    /**
     * Total audio duration in milliseconds.
     */
    val durationMs: Long
)

/**
 * A timed segment of transcribed text.
 */
data class Segment(
    /**
     * Transcribed text for this segment.
     */
    val text: String,

    /**
     * Start time in milliseconds from audio start.
     */
    val startMs: Long,

    /**
     * End time in milliseconds from audio start.
     */
    val endMs: Long
)
