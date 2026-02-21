package io.github.nikhilbhutani

/**
 * Callback interface for streaming text-to-speech.
 */
interface TtsStream {
    /**
     * Called with audio chunks as they are generated.
     * @param samples PCM audio (16-bit signed, 22050Hz, mono)
     */
    fun onAudioChunk(samples: ShortArray)

    /**
     * Called when synthesis is complete.
     */
    fun onComplete()

    /**
     * Called if an error occurs during synthesis.
     */
    fun onError(message: String)
}
