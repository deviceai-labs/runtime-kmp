package io.github.nikhilbhutani.models

import io.ktor.client.*
import io.ktor.client.call.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.*

/**
 * Fetches and parses available Piper TTS voices from HuggingFace.
 *
 * Source: rhasspy/piper-voices/resolve/main/voices.json
 * Each voice has a .onnx model and .onnx.json config file.
 * Download base: https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/
 */
internal class PiperCatalog(
    private val client: HttpClient,
    private val config: RegistryConfig
) {
    private val json = Json { ignoreUnknownKeys = true }

    private var cachedVoices: List<PiperVoiceInfo>? = null
    private var cacheTimestamp: Long = 0

    suspend fun fetchVoices(
        language: String? = null,
        quality: PiperQuality? = null
    ): List<PiperVoiceInfo> {
        val allVoices = fetchAllVoices()

        return allVoices.filter { voice ->
            (language == null || voice.language.code.startsWith(language, ignoreCase = true)) &&
            (quality == null || voice.quality == quality)
        }
    }

    private suspend fun fetchAllVoices(): List<PiperVoiceInfo> {
        val now = currentTimeMillis()
        cachedVoices?.let { cached ->
            if (now - cacheTimestamp < config.catalogCacheDurationMs) return cached
        }

        val voices = try {
            fetchFromApi()
        } catch (e: Exception) {
            loadCachedFromDisk() ?: throw e
        }

        cachedVoices = voices
        cacheTimestamp = now
        saveCacheToDisk(voices)
        return voices
    }

    private suspend fun fetchFromApi(): List<PiperVoiceInfo> {
        val response: HttpResponse = client.get(
            "${config.huggingFaceBaseUrl}/rhasspy/piper-voices/resolve/main/voices.json"
        )
        val body: String = response.body()
        return parseVoicesJson(body)
    }

    /**
     * Parse the voices.json manifest.
     *
     * Format is a map of voice key -> voice object:
     * {
     *   "en_US-amy-low": {
     *     "key": "en_US-amy-low",
     *     "name": "amy",
     *     "language": { "code": "en_US", "family": "en", "region": "US", ... },
     *     "quality": "low",
     *     "num_speakers": 1,
     *     "speaker_id_map": {},
     *     "files": {
     *       "en/en_US/amy/low/en_US-amy-low.onnx": { "size_bytes": 123, "md5_digest": "..." },
     *       "en/en_US/amy/low/en_US-amy-low.onnx.json": { "size_bytes": 456, "md5_digest": "..." }
     *     }
     *   }
     * }
     */
    internal fun parseVoicesJson(jsonStr: String): List<PiperVoiceInfo> {
        val root = json.parseToJsonElement(jsonStr).jsonObject
        val voices = mutableListOf<PiperVoiceInfo>()

        for ((key, value) in root) {
            try {
                val obj = value.jsonObject
                val voiceKey = obj["key"]?.jsonPrimitive?.content ?: key

                // Parse language
                val langObj = obj["language"]?.jsonObject ?: continue
                val languageInfo = LanguageInfo(
                    code = langObj["code"]?.jsonPrimitive?.content ?: "",
                    family = langObj["family"]?.jsonPrimitive?.content ?: "",
                    region = langObj["region"]?.jsonPrimitive?.content ?: "",
                    nameNative = langObj["name_native"]?.jsonPrimitive?.content ?: "",
                    nameEnglish = langObj["name_english"]?.jsonPrimitive?.content ?: "",
                    countryEnglish = langObj["country_english"]?.jsonPrimitive?.content ?: ""
                )

                // Parse quality
                val qualityStr = obj["quality"]?.jsonPrimitive?.content ?: "medium"
                val quality = PiperQuality.fromString(qualityStr) ?: PiperQuality.MEDIUM

                // Parse speaker info
                val numSpeakers = obj["num_speakers"]?.jsonPrimitive?.int ?: 1
                val speakerMap = mutableMapOf<String, Int>()
                obj["speaker_id_map"]?.jsonObject?.forEach { (name, id) ->
                    speakerMap[name] = id.jsonPrimitive.int
                }

                // Parse files to get model + config URLs and total size
                val filesObj = obj["files"]?.jsonObject ?: continue
                var modelPath: String? = null
                var configPath: String? = null
                var totalSize = 0L

                for ((filePath, fileInfo) in filesObj) {
                    val fileSize = fileInfo.jsonObject["size_bytes"]?.jsonPrimitive?.long ?: 0L
                    totalSize += fileSize
                    when {
                        filePath.endsWith(".onnx") && !filePath.endsWith(".onnx.json") -> modelPath = filePath
                        filePath.endsWith(".onnx.json") -> configPath = filePath
                    }
                }

                if (modelPath == null || configPath == null) continue

                val downloadBase = "${config.huggingFaceBaseUrl}/rhasspy/piper-voices/resolve/v1.0.0"
                val name = obj["name"]?.jsonPrimitive?.content ?: voiceKey

                // Build display name: "Amy (US English, Low)"
                val displayName = buildString {
                    append(name.replaceFirstChar { it.uppercase() })
                    append(" (")
                    if (languageInfo.countryEnglish.isNotEmpty()) {
                        append(languageInfo.countryEnglish)
                        append(" ")
                    }
                    append(languageInfo.nameEnglish)
                    append(", ")
                    append(qualityStr.replaceFirstChar { it.uppercase() })
                    append(")")
                }

                voices.add(
                    PiperVoiceInfo(
                        id = voiceKey,
                        displayName = displayName,
                        sizeBytes = totalSize,
                        language = languageInfo,
                        quality = quality,
                        numSpeakers = numSpeakers,
                        speakerIdMap = speakerMap,
                        modelUrl = "$downloadBase/$modelPath",
                        configUrl = "$downloadBase/$configPath"
                    )
                )
            } catch (_: Exception) {
                // Skip malformed entries
            }
        }

        return voices.sortedBy { it.id }
    }

    private fun loadCachedFromDisk(): List<PiperVoiceInfo>? {
        val cachePath = "${PlatformStorage.getModelsDir()}/piper_catalog_cache.json"
        val content = PlatformStorage.readText(cachePath) ?: return null
        return try {
            val cached = json.decodeFromString<CachedPiperCatalog>(content)
            cached.voices.map { it.toVoiceInfo() }
        } catch (_: Exception) {
            null
        }
    }

    private fun saveCacheToDisk(voices: List<PiperVoiceInfo>) {
        PlatformStorage.ensureDirectoryExists(PlatformStorage.getModelsDir())
        val cachePath = "${PlatformStorage.getModelsDir()}/piper_catalog_cache.json"
        val cached = CachedPiperCatalog(
            voices = voices.map { CachedPiperVoice.fromVoiceInfo(it) },
            cachedAt = currentTimeMillis()
        )
        PlatformStorage.writeText(cachePath, json.encodeToString(CachedPiperCatalog.serializer(), cached))
    }

    fun clearCache() {
        cachedVoices = null
        cacheTimestamp = 0
        val cachePath = "${PlatformStorage.getModelsDir()}/piper_catalog_cache.json"
        PlatformStorage.deleteFile(cachePath)
    }
}

@Serializable
private data class CachedPiperCatalog(
    val voices: List<CachedPiperVoice>,
    val cachedAt: Long
)

@Serializable
private data class CachedPiperVoice(
    val id: String,
    val displayName: String,
    val sizeBytes: Long,
    val language: LanguageInfo,
    val quality: String,
    val numSpeakers: Int,
    val speakerIdMap: Map<String, Int>,
    val modelUrl: String,
    val configUrl: String
) {
    fun toVoiceInfo() = PiperVoiceInfo(
        id = id,
        displayName = displayName,
        sizeBytes = sizeBytes,
        language = language,
        quality = PiperQuality.fromString(quality) ?: PiperQuality.MEDIUM,
        numSpeakers = numSpeakers,
        speakerIdMap = speakerIdMap,
        modelUrl = modelUrl,
        configUrl = configUrl
    )

    companion object {
        fun fromVoiceInfo(v: PiperVoiceInfo) = CachedPiperVoice(
            id = v.id,
            displayName = v.displayName,
            sizeBytes = v.sizeBytes,
            language = v.language,
            quality = v.quality.label,
            numSpeakers = v.numSpeakers,
            speakerIdMap = v.speakerIdMap,
            modelUrl = v.modelUrl,
            configUrl = v.configUrl
        )
    }
}
