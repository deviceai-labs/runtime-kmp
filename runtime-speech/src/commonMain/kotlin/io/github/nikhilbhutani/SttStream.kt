package io.github.nikhilbhutani

/**
 * Callback interface for streaming speech-to-text.
 */
interface SttStream {
    /**
     * Called with intermediate transcription results.
     * Text may change as more audio is processed.
     */
    fun onPartialResult(text: String)

    /**
     * Called when transcription is complete.
     */
    fun onFinalResult(result: TranscriptionResult)

    /**
     * Called if an error occurs during transcription.
     */
    fun onError(message: String)
}
