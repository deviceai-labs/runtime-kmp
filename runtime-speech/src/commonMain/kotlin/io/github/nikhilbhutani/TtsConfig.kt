package io.github.nikhilbhutani

/**
 * Configuration for text-to-speech.
 */
data class TtsConfig(
    /**
     * Speaker ID for multi-speaker models. null = default speaker.
     */
    val speakerId: Int? = null,

    /**
     * Speech rate multiplier. 1.0 = normal, 0.5 = slow, 2.0 = fast.
     */
    val speechRate: Float = 1.0f,

    /**
     * Output sample rate in Hz.
     */
    val sampleRate: Int = 22050,

    /**
     * Seconds of silence between sentences.
     */
    val sentenceSilence: Float = 0.2f,

    /**
     * Path to espeak-ng-data directory.
     * Required for phonemization. On Android/iOS this is extracted from assets.
     */
    val espeakDataPath: String? = null
)
