package io.github.nikhilbhutani.demo

/**
 * Cross-platform microphone recorder.
 * Records 16 kHz mono PCM audio and returns normalized float samples.
 */
@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
expect class AudioRecorder() {
    /**
     * Begins capturing audio at 16 kHz, mono, 16-bit PCM.
     * No-op if already recording.
     */
    fun startRecording()

    /**
     * Stops capture and returns all accumulated samples as a
     * FloatArray normalized to [-1.0, 1.0] at 16 kHz mono.
     * Returns an empty array if not recording.
     */
    fun stopRecording(): FloatArray
}
