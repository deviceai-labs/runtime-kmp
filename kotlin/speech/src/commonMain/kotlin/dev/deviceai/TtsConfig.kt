package dev.deviceai

/**
 * Configuration for text-to-speech (sherpa-onnx backend).
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
     * Path to the espeak-ng-data directory bundled inside sherpa-onnx.
     * On Android: extract from assets to cacheDir and pass the absolute path.
     * On iOS: use the path inside the app bundle.
     */
    val dataDir: String = "",

    /**
     * Path to voices.bin — required for Kokoro models, leave empty for VITS.
     */
    val voicesPath: String = ""
)
