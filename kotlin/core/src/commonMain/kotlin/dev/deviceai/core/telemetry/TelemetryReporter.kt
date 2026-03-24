package dev.deviceai.core.telemetry

import dev.deviceai.core.CoreSDKLogger
import dev.deviceai.core.DeviceAI
import dev.deviceai.core.InternalDeviceAiApi
import dev.deviceai.core.Telemetry

/**
 * Buffers [InferenceEvent]s and flushes them to the DeviceAI backend.
 *
 * Active only when [Telemetry.Enabled] is set in [DeviceAI.initialize].
 * No data is collected or buffered in [Telemetry.Disabled] (default).
 *
 * What is sent: model ID, token counts, latency, tokens/sec, OS, RAM.
 * What is never sent: prompt text, response text, user identifiers.
 */
@InternalDeviceAiApi
object TelemetryReporter {

    private const val TAG = "Telemetry"
    private const val MAX_BUFFER = 100

    private val buffer = mutableListOf<InferenceEvent>()

    /**
     * Record one inference event. No-op if telemetry is disabled.
     */
    fun record(event: InferenceEvent) {
        if (DeviceAI.cloudConfig?.telemetry != Telemetry.Enabled) return
        if (buffer.size >= MAX_BUFFER) buffer.removeAt(0)
        buffer.add(event)
        CoreSDKLogger.debug(TAG,
            "model=${event.modelId} " +
            "in=${event.inputTokens}tok out=${event.outputTokens}tok " +
            "${String.format("%.1f", event.tokensPerSecond)}tok/s " +
            "${event.totalMs}ms success=${event.success}"
        )
        // TODO: flush to ${DeviceAI.cloudConfig?.baseUrl}/api/v1/sdk/telemetry
        //       batch with DeviceProfile snapshot on first flush
    }

    /**
     * Flush buffered events to the backend. No-op if telemetry is disabled or
     * the backend is not yet connected.
     *
     * Called automatically on Wi-Fi + charging (Phase 2).
     */
    fun flush() {
        if (DeviceAI.cloudConfig?.telemetry != Telemetry.Enabled) return
        if (buffer.isEmpty()) return
        val snapshot = buffer.toList()
        buffer.clear()
        CoreSDKLogger.debug(TAG,
            "flush ${snapshot.size} events " +
            "os=${DeviceProfile.osName}/${DeviceProfile.osVersion} " +
            "ram=${DeviceProfile.totalMemoryMb}MB — backend not yet connected"
        )
        // TODO: POST snapshot + DeviceProfile to ${DeviceAI.cloudConfig?.baseUrl}/api/v1/sdk/telemetry
    }
}
