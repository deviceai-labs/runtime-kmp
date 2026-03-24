package dev.deviceai.core.telemetry

import dev.deviceai.core.InternalDeviceAiApi

/**
 * Static hardware + OS snapshot collected once at SDK initialization.
 * No personally identifiable information is included.
 */
@InternalDeviceAiApi
expect object DeviceProfile {
    /** Platform name: "android", "ios", or the JVM os.name lowercased. */
    val osName: String
    /** OS version string, e.g. "15.0", "14", "13.1". */
    val osVersion: String
    /** Total physical RAM in megabytes. */
    val totalMemoryMb: Long
}
