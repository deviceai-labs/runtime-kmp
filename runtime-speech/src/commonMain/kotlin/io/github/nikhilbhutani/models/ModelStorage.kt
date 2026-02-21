package io.github.nikhilbhutani.models

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

/**
 * Platform-specific model storage directories.
 */
expect object PlatformStorage {
    /**
     * Directory where downloaded models are stored.
     * Android: context.filesDir/speechkmp_models/
     * iOS: NSDocumentDirectory/speechkmp_models/
     * JVM: ~/.speechkmp/models/
     */
    fun getModelsDir(): String

    /**
     * Directory for temporary/in-progress downloads.
     * Android: context.cacheDir/speechkmp_tmp/
     * iOS: NSCachesDirectory/speechkmp_tmp/
     * JVM: System.tmpdir/speechkmp_tmp/
     */
    fun getTempDir(): String

    /**
     * Ensure a directory exists, creating it and parents if needed.
     */
    fun ensureDirectoryExists(path: String): Boolean

    /**
     * Check if a file exists at the given path.
     */
    fun fileExists(path: String): Boolean

    /**
     * Delete a file or directory at the given path.
     */
    fun deleteFile(path: String): Boolean

    /**
     * Rename/move a file atomically.
     */
    fun moveFile(from: String, to: String): Boolean

    /**
     * Get the size of a file in bytes, or -1 if not found.
     */
    fun fileSize(path: String): Long

    /**
     * Read text content from a file, or null if not found.
     */
    fun readText(path: String): String?

    /**
     * Write text content to a file.
     */
    fun writeText(path: String, content: String): Boolean
}

/**
 * Manages the registry metadata file that tracks downloaded models.
 */
internal object MetadataStore {
    private val json = Json { ignoreUnknownKeys = true; prettyPrint = true }

    private fun metadataPath(): String =
        "${PlatformStorage.getModelsDir()}/registry_metadata.json"

    fun loadDownloadedModels(): List<LocalModel> {
        val content = PlatformStorage.readText(metadataPath()) ?: return emptyList()
        return try {
            json.decodeFromString<List<LocalModel>>(content)
        } catch (_: Exception) {
            emptyList()
        }
    }

    fun saveDownloadedModels(models: List<LocalModel>) {
        PlatformStorage.ensureDirectoryExists(PlatformStorage.getModelsDir())
        val content = json.encodeToString(models)
        PlatformStorage.writeText(metadataPath(), content)
    }

    fun addModel(model: LocalModel) {
        val models = loadDownloadedModels().toMutableList()
        models.removeAll { it.modelId == model.modelId }
        models.add(model)
        saveDownloadedModels(models)
    }

    fun removeModel(modelId: String) {
        val models = loadDownloadedModels().toMutableList()
        models.removeAll { it.modelId == modelId }
        saveDownloadedModels(models)
    }

    fun getModel(modelId: String): LocalModel? =
        loadDownloadedModels().find { it.modelId == modelId }
}
