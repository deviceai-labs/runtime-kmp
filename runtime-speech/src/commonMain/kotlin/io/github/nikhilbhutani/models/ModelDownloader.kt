package io.github.nikhilbhutani.models

import io.ktor.client.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.utils.io.*
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlin.coroutines.coroutineContext

/**
 * Downloads model files from HuggingFace with progress reporting, resume, and cancellation.
 *
 * Downloads go to a temp file first, then get renamed on completion (atomic).
 * Partial downloads can be resumed via HTTP Range headers.
 */
internal class ModelDownloader(
    private val client: HttpClient,
    private val config: RegistryConfig
) {
    private val activeDownloads = mutableMapOf<String, Job>()

    /**
     * Download a single file from [url] to [destPath].
     *
     * @param url Source URL
     * @param destPath Final destination path
     * @param onProgress Called with download progress updates
     */
    suspend fun downloadFile(
        url: String,
        destPath: String,
        onProgress: (DownloadProgress) -> Unit = {}
    ) {
        val destDir = destPath.substringBeforeLast('/')
        PlatformStorage.ensureDirectoryExists(destDir)

        val tempPath = "$destPath.tmp"
        val existingBytes = PlatformStorage.fileSize(tempPath).let { if (it > 0) it else 0L }

        onProgress(DownloadProgress.pending())

        val response = client.prepareGet(url) {
            if (existingBytes > 0) {
                header(HttpHeaders.Range, "bytes=$existingBytes-")
            }
        }.execute { httpResponse ->
            val statusCode = httpResponse.status.value
            val isResuming = statusCode == 206 && existingBytes > 0

            val contentLength = httpResponse.contentLength() ?: 0L
            val totalBytes = if (isResuming) contentLength + existingBytes else contentLength

            val channel: ByteReadChannel = httpResponse.bodyAsChannel()
            val buffer = ByteArray(config.downloadBufferSize)
            var bytesDownloaded = if (isResuming) existingBytes else 0L

            // If server doesn't support range and we have a partial file, start over
            if (!isResuming && existingBytes > 0) {
                PlatformStorage.deleteFile(tempPath)
            }

            while (!channel.isClosedForRead) {
                coroutineContext.ensureActive()

                val bytesRead = channel.readAvailable(buffer, 0, buffer.size)
                if (bytesRead <= 0) break

                appendToFile(tempPath, buffer, bytesRead)
                bytesDownloaded += bytesRead

                val percent = if (totalBytes > 0) {
                    (bytesDownloaded.toFloat() / totalBytes * 100f).coerceIn(0f, 100f)
                } else 0f

                onProgress(
                    DownloadProgress(
                        bytesDownloaded = bytesDownloaded,
                        totalBytes = totalBytes,
                        percentComplete = percent,
                        state = DownloadState.DOWNLOADING
                    )
                )
            }

            bytesDownloaded
        }

        // Move temp file to final destination
        PlatformStorage.deleteFile(destPath) // Remove old version if exists
        if (!PlatformStorage.moveFile(tempPath, destPath)) {
            throw RuntimeException("Failed to move downloaded file to $destPath")
        }

        val finalSize = PlatformStorage.fileSize(destPath)
        onProgress(DownloadProgress.completed(finalSize))
    }

    /**
     * Download a Whisper model.
     */
    suspend fun downloadWhisperModel(
        model: WhisperModelInfo,
        onProgress: (DownloadProgress) -> Unit = {}
    ): LocalModel {
        val modelDir = "${PlatformStorage.getModelsDir()}/whisper"
        PlatformStorage.ensureDirectoryExists(modelDir)
        val destPath = "$modelDir/${model.id}"

        // Track active download
        val job = coroutineContext[Job]
        if (job != null) {
            activeDownloads[model.id] = job
        }

        try {
            downloadFile(model.downloadUrl, destPath, onProgress)
        } catch (e: CancellationException) {
            onProgress(DownloadProgress.cancelled())
            throw e
        } catch (e: Exception) {
            onProgress(DownloadProgress.failed())
            throw e
        } finally {
            activeDownloads.remove(model.id)
        }

        val localModel = LocalModel(
            modelId = model.id,
            modelType = LocalModelType.WHISPER,
            modelPath = destPath,
            downloadedAt = currentTimeMillis()
        )
        MetadataStore.addModel(localModel)
        return localModel
    }

    /**
     * Download a Piper voice model (both .onnx and .onnx.json).
     */
    suspend fun downloadPiperVoice(
        voice: PiperVoiceInfo,
        onProgress: (DownloadProgress) -> Unit = {}
    ): LocalModel {
        val voiceDir = "${PlatformStorage.getModelsDir()}/piper/${voice.id}"
        PlatformStorage.ensureDirectoryExists(voiceDir)

        val modelFileName = voice.modelUrl.substringAfterLast('/')
        val configFileName = voice.configUrl.substringAfterLast('/')
        val modelPath = "$voiceDir/$modelFileName"
        val configPath = "$voiceDir/$configFileName"

        val job = coroutineContext[Job]
        if (job != null) {
            activeDownloads[voice.id] = job
        }

        try {
            // Download config first (small file)
            downloadFile(voice.configUrl, configPath)

            // Download model with progress tracking
            downloadFile(voice.modelUrl, modelPath, onProgress)
        } catch (e: CancellationException) {
            onProgress(DownloadProgress.cancelled())
            throw e
        } catch (e: Exception) {
            onProgress(DownloadProgress.failed())
            throw e
        } finally {
            activeDownloads.remove(voice.id)
        }

        val localModel = LocalModel(
            modelId = voice.id,
            modelType = LocalModelType.PIPER,
            modelPath = modelPath,
            configPath = configPath,
            downloadedAt = currentTimeMillis()
        )
        MetadataStore.addModel(localModel)
        return localModel
    }

    /**
     * Cancel an active download by model ID.
     */
    fun cancelDownload(modelId: String) {
        activeDownloads[modelId]?.cancel()
        activeDownloads.remove(modelId)
    }
}

/**
 * Platform-specific file append operation for streaming downloads.
 */
internal expect fun appendToFile(path: String, data: ByteArray, length: Int)
