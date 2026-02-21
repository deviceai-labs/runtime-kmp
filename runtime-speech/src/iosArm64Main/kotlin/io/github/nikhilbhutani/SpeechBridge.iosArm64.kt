package io.github.nikhilbhutani

import androidx.compose.runtime.Composable
import io.github.nikhilbhutani.native.*
import kotlinx.cinterop.*
import platform.Foundation.*

@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
@OptIn(ExperimentalForeignApi::class)
actual object SpeechBridge {

    // ══════════════════════════════════════════════════════════════
    //                    SPEECH-TO-TEXT (STT)
    // ══════════════════════════════════════════════════════════════

    actual fun initStt(modelPath: String, config: SttConfig): Boolean {
        return speech_stt_init(
            modelPath,
            config.language,
            config.translateToEnglish,
            config.maxThreads,
            config.useGpu,
            config.useVad
        )
    }

    actual fun transcribe(audioPath: String): String {
        val result = speech_stt_transcribe(audioPath)
        return result?.toKString()?.also { speech_free_string(result) } ?: ""
    }

    actual fun transcribeDetailed(audioPath: String): TranscriptionResult {
        val jsonResult = speech_stt_transcribe_detailed(audioPath)
        val jsonStr = jsonResult?.toKString()?.also { speech_free_string(jsonResult) } ?: "{}"
        return parseTranscriptionResult(jsonStr)
    }

    actual fun transcribeAudio(samples: FloatArray): String {
        memScoped {
            val nativeSamples = allocArray<FloatVar>(samples.size)
            samples.forEachIndexed { index, value -> nativeSamples[index] = value }
            val result = speech_stt_transcribe_audio(nativeSamples, samples.size)
            return result?.toKString()?.also { speech_free_string(result) } ?: ""
        }
    }

    actual fun transcribeStream(samples: FloatArray, callback: SttStream) {
        memScoped {
            val nativeSamples = allocArray<FloatVar>(samples.size)
            samples.forEachIndexed { index, value -> nativeSamples[index] = value }

            val ref = StableRef.create(callback)

            val onPartial = staticCFunction { text: CPointer<ByteVar>?, userData: COpaquePointer? ->
                val cb = userData!!.asStableRef<SttStream>().get()
                cb.onPartialResult(text?.toKString() ?: "")
            }

            val onFinal = staticCFunction { jsonResult: CPointer<ByteVar>?, userData: COpaquePointer? ->
                val cb = userData!!.asStableRef<SttStream>().get()
                val jsonStr = jsonResult?.toKString() ?: "{}"
                cb.onFinalResult(parseTranscriptionResult(jsonStr))
            }

            val onError = staticCFunction { message: CPointer<ByteVar>?, userData: COpaquePointer? ->
                val cb = userData!!.asStableRef<SttStream>().get()
                cb.onError(message?.toKString() ?: "Unknown error")
            }

            speech_stt_transcribe_stream(
                nativeSamples,
                samples.size,
                onPartial,
                onFinal,
                onError,
                ref.asCPointer()
            )

            ref.dispose()
        }
    }

    actual fun cancelStt() {
        speech_stt_cancel()
    }

    actual fun shutdownStt() {
        speech_stt_shutdown()
    }

    // ══════════════════════════════════════════════════════════════
    //                    TEXT-TO-SPEECH (TTS)
    // ══════════════════════════════════════════════════════════════

    actual fun initTts(modelPath: String, configPath: String, config: TtsConfig): Boolean {
        return speech_tts_init(
            modelPath,
            configPath,
            config.espeakDataPath ?: "",
            config.speakerId ?: -1,
            config.speechRate,
            config.sampleRate,
            config.sentenceSilence
        )
    }

    actual fun synthesize(text: String): ShortArray {
        memScoped {
            val outLength = alloc<IntVar>()
            val result = speech_tts_synthesize(text, outLength.ptr)
            if (result == null) return shortArrayOf()

            val length = outLength.value
            val samples = ShortArray(length) { result[it] }
            speech_free_audio(result)
            return samples
        }
    }

    actual fun synthesizeToFile(text: String, outputPath: String): Boolean {
        return speech_tts_synthesize_to_file(text, outputPath)
    }

    actual fun synthesizeStream(text: String, callback: TtsStream) {
        val ref = StableRef.create(callback)

        val onChunk = staticCFunction { samples: CPointer<ShortVar>?, nSamples: Int, userData: COpaquePointer? ->
            val cb = userData!!.asStableRef<TtsStream>().get()
            if (samples != null && nSamples > 0) {
                val chunk = ShortArray(nSamples) { samples[it] }
                cb.onAudioChunk(chunk)
            }
        }

        val onComplete = staticCFunction { userData: COpaquePointer? ->
            val cb = userData!!.asStableRef<TtsStream>().get()
            cb.onComplete()
        }

        val onError = staticCFunction { message: CPointer<ByteVar>?, userData: COpaquePointer? ->
            val cb = userData!!.asStableRef<TtsStream>().get()
            cb.onError(message?.toKString() ?: "Unknown error")
        }

        speech_tts_synthesize_stream(text, onChunk, onComplete, onError, ref.asCPointer())

        ref.dispose()
    }

    actual fun cancelTts() {
        speech_tts_cancel()
    }

    actual fun shutdownTts() {
        speech_tts_shutdown()
    }

    // ══════════════════════════════════════════════════════════════
    //                         UTILITIES
    // ══════════════════════════════════════════════════════════════

    @Composable
    actual fun getModelPath(modelFileName: String): String {
        // Try to find in bundle resources first
        val bundle = NSBundle.mainBundle
        val resourcePath = bundle.pathForResource(
            modelFileName.substringBeforeLast("."),
            modelFileName.substringAfterLast(".")
        )
        if (resourcePath != null) return resourcePath

        // Fallback to documents directory
        val fileManager = NSFileManager.defaultManager
        val urls = fileManager.URLsForDirectory(NSDocumentDirectory, NSUserDomainMask)
        @Suppress("UNCHECKED_CAST")
        val documentsUrl = (urls as List<NSURL>).firstOrNull()
        if (documentsUrl != null) {
            val filePath = documentsUrl.path + "/$modelFileName"
            if (fileManager.fileExistsAtPath(filePath)) {
                return filePath
            }
        }

        // Fallback to caches directory
        val cacheUrls = fileManager.URLsForDirectory(NSCachesDirectory, NSUserDomainMask)
        @Suppress("UNCHECKED_CAST")
        val cacheUrl = (cacheUrls as List<NSURL>).firstOrNull()
        if (cacheUrl != null) {
            val cachePath = cacheUrl.path + "/$modelFileName"
            if (fileManager.fileExistsAtPath(cachePath)) {
                return cachePath
            }
        }

        // Return filename as-is if not found
        return modelFileName
    }

    actual fun shutdown() {
        speech_shutdown_all()
    }

    // ══════════════════════════════════════════════════════════════
    //                    HELPER FUNCTIONS
    // ══════════════════════════════════════════════════════════════

    private fun parseTranscriptionResult(json: String): TranscriptionResult {
        // Simple JSON parsing - in production, use kotlinx.serialization
        // Expected format: {"text":"...", "segments":[...], "language":"...", "durationMs":...}
        return try {
            val text = extractJsonString(json, "text") ?: ""
            val language = extractJsonString(json, "language") ?: "en"
            val durationMs = extractJsonLong(json, "durationMs") ?: 0L
            val segments = parseSegments(json)
            TranscriptionResult(text, segments, language, durationMs)
        } catch (e: Exception) {
            TranscriptionResult("", emptyList(), "en", 0L)
        }
    }

    private fun extractJsonString(json: String, key: String): String? {
        val pattern = "\"$key\"\\s*:\\s*\"([^\"]*)\""
        val regex = Regex(pattern)
        return regex.find(json)?.groupValues?.getOrNull(1)
    }

    private fun extractJsonLong(json: String, key: String): Long? {
        val pattern = "\"$key\"\\s*:\\s*(\\d+)"
        val regex = Regex(pattern)
        return regex.find(json)?.groupValues?.getOrNull(1)?.toLongOrNull()
    }

    private fun parseSegments(json: String): List<Segment> {
        // Simple parsing for segments array
        val segmentsPattern = "\"segments\"\\s*:\\s*\\[([^\\]]*)\\]"
        val segmentsMatch = Regex(segmentsPattern).find(json) ?: return emptyList()
        val segmentsStr = segmentsMatch.groupValues.getOrNull(1) ?: return emptyList()

        val segments = mutableListOf<Segment>()
        val segmentPattern = "\\{[^}]*\"text\"\\s*:\\s*\"([^\"]*)\"[^}]*\"startMs\"\\s*:\\s*(\\d+)[^}]*\"endMs\"\\s*:\\s*(\\d+)[^}]*\\}"
        Regex(segmentPattern).findAll(segmentsStr).forEach { match ->
            val text = match.groupValues.getOrNull(1) ?: ""
            val startMs = match.groupValues.getOrNull(2)?.toLongOrNull() ?: 0L
            val endMs = match.groupValues.getOrNull(3)?.toLongOrNull() ?: 0L
            segments.add(Segment(text, startMs, endMs))
        }
        return segments
    }
}
