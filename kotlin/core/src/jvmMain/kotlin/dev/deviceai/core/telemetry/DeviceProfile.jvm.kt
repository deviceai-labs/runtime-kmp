package dev.deviceai.core.telemetry

import dev.deviceai.core.InternalDeviceAiApi

@InternalDeviceAiApi
@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual object DeviceProfile {
    actual val osName: String = System.getProperty("os.name")?.lowercase() ?: "jvm"
    actual val osVersion: String = System.getProperty("os.version") ?: "unknown"
    actual val totalMemoryMb: Long = Runtime.getRuntime().maxMemory() / 1024 / 1024
}
