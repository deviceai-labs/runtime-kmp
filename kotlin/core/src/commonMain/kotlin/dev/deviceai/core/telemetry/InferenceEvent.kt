package dev.deviceai.core.telemetry

import dev.deviceai.core.InternalDeviceAiApi

/**
 * Telemetry snapshot for a single LLM inference call.
 *
 * Never contains prompt text, response text, or any user-identifiable content.
 */
@InternalDeviceAiApi
data class InferenceEvent(
    /** Unique ID for this generation call. */
    val generationId: String,
    /** Model filename without extension, e.g. "llama-3.2-1b-instruct-q4_k_m". */
    val modelId: String,
    /** Estimated input token count (prompt chars / 4). */
    val inputTokens: Int,
    /** Output token count — exact for streaming, word-approximated for blocking. */
    val outputTokens: Int,
    /** Wall-clock duration from first token request to last token received, ms. */
    val totalMs: Long,
    /** Output tokens per second. */
    val tokensPerSecond: Float,
    /** Whether the call completed without error. */
    val success: Boolean,
    /** Unix timestamp of the call, ms. */
    val timestampMs: Long,
)
