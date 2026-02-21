package io.github.nikhilbhutani.models

import kotlinx.serialization.Serializable

/**
 * Common interface for all downloadable model types.
 */
sealed interface ModelInfo {
    val id: String
    val displayName: String
    val sizeBytes: Long
}

/**
 * Whisper model size tiers.
 */
enum class WhisperSize(val label: String) {
    TINY("tiny"),
    BASE("base"),
    SMALL("small"),
    MEDIUM("medium"),
    LARGE_V1("large-v1"),
    LARGE_V2("large-v2"),
    LARGE_V3("large-v3"),
    LARGE_V3_TURBO("large-v3-turbo");

    companion object {
        fun fromString(s: String): WhisperSize? = entries.find { it.label == s }
    }
}

/**
 * Quantization formats available for Whisper models.
 */
enum class Quantization(val label: String) {
    Q5_1("q5_1"),
    Q8_0("q8_0");

    companion object {
        fun fromString(s: String): Quantization? = entries.find { it.label == s }
    }
}

/**
 * Piper voice quality tiers.
 */
enum class PiperQuality(val label: String) {
    X_LOW("x_low"),
    LOW("low"),
    MEDIUM("medium"),
    HIGH("high");

    companion object {
        fun fromString(s: String): PiperQuality? = entries.find { it.label == s }
    }
}

/**
 * Language metadata for Piper voices.
 */
@Serializable
data class LanguageInfo(
    val code: String,
    val family: String,
    val region: String,
    val nameNative: String,
    val nameEnglish: String,
    val countryEnglish: String
)

/**
 * Whisper GGML model available on HuggingFace.
 *
 * Files are hosted at: huggingface.co/ggerganov/whisper.cpp/resolve/main/{id}
 */
data class WhisperModelInfo(
    override val id: String,
    override val displayName: String,
    override val sizeBytes: Long,
    val size: WhisperSize,
    val isEnglishOnly: Boolean,
    val quantization: Quantization?,
    val downloadUrl: String
) : ModelInfo

/**
 * Piper ONNX voice model available on HuggingFace.
 *
 * Each voice requires two files: .onnx model + .onnx.json config.
 */
data class PiperVoiceInfo(
    override val id: String,
    override val displayName: String,
    override val sizeBytes: Long,
    val language: LanguageInfo,
    val quality: PiperQuality,
    val numSpeakers: Int,
    val speakerIdMap: Map<String, Int>,
    val modelUrl: String,
    val configUrl: String
) : ModelInfo

/**
 * A model that has been downloaded and is available locally.
 */
@Serializable
data class LocalModel(
    val modelId: String,
    val modelType: LocalModelType,
    val modelPath: String,
    val configPath: String? = null,
    val downloadedAt: Long
)

/**
 * Type discriminator for local models.
 */
@Serializable
enum class LocalModelType {
    WHISPER,
    PIPER
}
