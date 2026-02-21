package io.github.nikhilbhutani.models

import io.ktor.client.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.serialization.json.Json

/**
 * Central registry for discovering, downloading, and managing Whisper and Piper models.
 *
 * Models are fetched from HuggingFace public repos (no API key required):
 * - Whisper: ggerganov/whisper.cpp (GGML .bin files)
 * - Piper: rhasspy/piper-voices (ONNX .onnx + .json files)
 *
 * Usage:
 * ```kotlin
 * // On Android, initialize storage first:
 * // PlatformStorage.initialize(context)
 *
 * ModelRegistry.initialize()
 *
 * // Discover models
 * val whisperModels = ModelRegistry.getWhisperModels()
 * val piperVoices = ModelRegistry.getPiperVoices(language = "en")
 *
 * // Download with progress
 * val tiny = whisperModels.first { it.size == WhisperSize.TINY }
 * val local = ModelRegistry.download(tiny) { progress ->
 *     println("${progress.percentComplete}%")
 * }.getOrThrow()
 *
 * // Use with SpeechBridge
 * SpeechBridge.initStt(local.modelPath, SttConfig())
 * ```
 */
object ModelRegistry {
    private var initialized = false
    private var config = RegistryConfig()
    private lateinit var client: HttpClient
    private lateinit var whisperCatalog: WhisperCatalog
    private lateinit var piperCatalog: PiperCatalog
    private lateinit var downloader: ModelDownloader

    /**
     * Initialize the registry with optional configuration.
     * Must be called before any other methods.
     *
     * On Android, call [PlatformStorage.initialize] with a Context first.
     */
    fun initialize(config: RegistryConfig = RegistryConfig()) {
        this.config = config
        this.client = HttpClient {
            install(ContentNegotiation) {
                json(Json { ignoreUnknownKeys = true })
            }
        }
        this.whisperCatalog = WhisperCatalog(client, config)
        this.piperCatalog = PiperCatalog(client, config)
        this.downloader = ModelDownloader(client, config)
        initialized = true
    }

    private fun requireInitialized() {
        if (!initialized) throw IllegalStateException(
            "ModelRegistry not initialized. Call ModelRegistry.initialize() first."
        )
    }

    // ══════════════════════════════════════════════════════════════
    //                         DISCOVERY
    // ══════════════════════════════════════════════════════════════

    /**
     * Fetch available Whisper GGML models from HuggingFace.
     * Results are cached for the duration specified in [RegistryConfig].
     */
    suspend fun getWhisperModels(): List<WhisperModelInfo> {
        requireInitialized()
        return whisperCatalog.fetchModels()
    }

    /**
     * Fetch available Piper TTS voices from HuggingFace.
     *
     * @param language Filter by language code prefix (e.g. "en", "en_US"). Null returns all.
     * @param quality Filter by quality tier. Null returns all.
     */
    suspend fun getPiperVoices(
        language: String? = null,
        quality: PiperQuality? = null
    ): List<PiperVoiceInfo> {
        requireInitialized()
        return piperCatalog.fetchVoices(language, quality)
    }

    // ══════════════════════════════════════════════════════════════
    //                         DOWNLOAD
    // ══════════════════════════════════════════════════════════════

    /**
     * Download a model to local storage.
     *
     * Supports resume (partial downloads are preserved) and cancellation.
     * Returns a [LocalModel] with paths ready for use with [SpeechBridge].
     *
     * @param model The model or voice to download
     * @param onProgress Called with download progress updates
     * @return [Result] containing the [LocalModel] on success
     */
    suspend fun download(
        model: ModelInfo,
        onProgress: (DownloadProgress) -> Unit = {}
    ): Result<LocalModel> {
        requireInitialized()

        // Check if already downloaded
        val existing = MetadataStore.getModel(model.id)
        if (existing != null && PlatformStorage.fileExists(existing.modelPath)) {
            onProgress(DownloadProgress.completed(PlatformStorage.fileSize(existing.modelPath)))
            return Result.success(existing)
        }

        return try {
            val localModel = when (model) {
                is WhisperModelInfo -> downloader.downloadWhisperModel(model, onProgress)
                is PiperVoiceInfo -> downloader.downloadPiperVoice(model, onProgress)
            }
            Result.success(localModel)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    /**
     * Cancel an in-progress download.
     */
    fun cancelDownload(modelId: String) {
        requireInitialized()
        downloader.cancelDownload(modelId)
    }

    // ══════════════════════════════════════════════════════════════
    //                      LOCAL MANAGEMENT
    // ══════════════════════════════════════════════════════════════

    /**
     * Get all models that have been downloaded to local storage.
     */
    fun getDownloadedModels(): List<LocalModel> {
        requireInitialized()
        return MetadataStore.loadDownloadedModels().filter {
            PlatformStorage.fileExists(it.modelPath)
        }
    }

    /**
     * Get a specific downloaded model by ID, or null if not found.
     */
    fun getLocalModel(modelId: String): LocalModel? {
        requireInitialized()
        val model = MetadataStore.getModel(modelId) ?: return null
        return if (PlatformStorage.fileExists(model.modelPath)) model else null
    }

    /**
     * Delete a downloaded model and its files.
     *
     * @return true if the model was found and deleted
     */
    fun deleteModel(modelId: String): Boolean {
        requireInitialized()
        val model = MetadataStore.getModel(modelId) ?: return false

        // Delete model file
        PlatformStorage.deleteFile(model.modelPath)

        // Delete config file if present (Piper)
        model.configPath?.let { PlatformStorage.deleteFile(it) }

        // For Piper, try deleting the voice directory too
        if (model.modelType == LocalModelType.PIPER) {
            val voiceDir = model.modelPath.substringBeforeLast('/')
            PlatformStorage.deleteFile(voiceDir)
        }

        MetadataStore.removeModel(modelId)
        return true
    }

    // ══════════════════════════════════════════════════════════════
    //                           CACHE
    // ══════════════════════════════════════════════════════════════

    /**
     * Force re-fetch of all catalogs from HuggingFace, ignoring cache.
     */
    suspend fun refreshCatalog() {
        requireInitialized()
        whisperCatalog.clearCache()
        piperCatalog.clearCache()
        // Trigger fresh fetches
        whisperCatalog.fetchModels()
        piperCatalog.fetchVoices()
    }

    /**
     * Clear cached catalog data. Next call to getWhisperModels/getPiperVoices will re-fetch.
     */
    fun clearCatalogCache() {
        requireInitialized()
        whisperCatalog.clearCache()
        piperCatalog.clearCache()
    }
}
