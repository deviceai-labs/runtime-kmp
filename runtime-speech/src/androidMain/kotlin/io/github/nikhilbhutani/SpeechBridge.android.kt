package io.github.nikhilbhutani

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.platform.LocalContext
import java.io.File

@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual object SpeechBridge {

    init {
        System.loadLibrary("speech_jni")
    }

    // ══════════════════════════════════════════════════════════════
    //                    SPEECH-TO-TEXT (STT)
    // ══════════════════════════════════════════════════════════════

    actual fun initStt(modelPath: String, config: SttConfig): Boolean =
        nativeInitStt(
            modelPath,
            config.language,
            config.translateToEnglish,
            config.maxThreads,
            config.useGpu,
            config.useVad,
            config.singleSegment,
            config.noContext
        )

    actual fun transcribe(audioPath: String): String =
        nativeTranscribe(audioPath)

    actual fun transcribeDetailed(audioPath: String): TranscriptionResult =
        nativeTranscribeDetailed(audioPath)

    actual fun transcribeAudio(samples: FloatArray): String =
        nativeTranscribeAudio(samples)

    actual fun transcribeStream(samples: FloatArray, callback: SttStream) =
        nativeTranscribeStream(samples, callback)

    actual fun cancelStt() = nativeCancelStt()

    actual fun shutdownStt() = nativeShutdownStt()

    // ══════════════════════════════════════════════════════════════
    //                    TEXT-TO-SPEECH (TTS)
    // ══════════════════════════════════════════════════════════════

    actual fun initTts(modelPath: String, configPath: String, config: TtsConfig): Boolean =
        nativeInitTts(
            modelPath,
            configPath,
            config.espeakDataPath ?: "",
            config.speakerId ?: -1,
            config.speechRate,
            config.sampleRate,
            config.sentenceSilence
        )

    actual fun synthesize(text: String): ShortArray =
        nativeSynthesize(text)

    actual fun synthesizeToFile(text: String, outputPath: String): Boolean =
        nativeSynthesizeToFile(text, outputPath)

    actual fun synthesizeStream(text: String, callback: TtsStream) =
        nativeSynthesizeStream(text, callback)

    actual fun cancelTts() = nativeCancelTts()

    actual fun shutdownTts() = nativeShutdownTts()

    // ══════════════════════════════════════════════════════════════
    //                         UTILITIES
    // ══════════════════════════════════════════════════════════════

    @Composable
    actual fun getModelPath(modelFileName: String): String {
        val context = LocalContext.current
        val outFile = File(context.cacheDir, modelFileName)
        if (!outFile.exists()) {
            context.assets.open(modelFileName).use { input ->
                outFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
        }
        return outFile.absolutePath
    }

    actual fun shutdown() {
        shutdownStt()
        shutdownTts()
    }

    // ══════════════════════════════════════════════════════════════
    //                    NATIVE DECLARATIONS
    // ══════════════════════════════════════════════════════════════

    // STT
    private external fun nativeInitStt(
        modelPath: String,
        language: String,
        translate: Boolean,
        maxThreads: Int,
        useGpu: Boolean,
        useVad: Boolean,
        singleSegment: Boolean,
        noContext: Boolean
    ): Boolean

    private external fun nativeTranscribe(audioPath: String): String
    private external fun nativeTranscribeDetailed(audioPath: String): TranscriptionResult
    private external fun nativeTranscribeAudio(samples: FloatArray): String
    private external fun nativeTranscribeStream(samples: FloatArray, callback: SttStream)
    private external fun nativeCancelStt()
    private external fun nativeShutdownStt()

    // TTS
    private external fun nativeInitTts(
        modelPath: String,
        configPath: String,
        espeakDataPath: String,
        speakerId: Int,
        speechRate: Float,
        sampleRate: Int,
        sentenceSilence: Float
    ): Boolean

    private external fun nativeSynthesize(text: String): ShortArray
    private external fun nativeSynthesizeToFile(text: String, outputPath: String): Boolean
    private external fun nativeSynthesizeStream(text: String, callback: TtsStream)
    private external fun nativeCancelTts()
    private external fun nativeShutdownTts()
}
