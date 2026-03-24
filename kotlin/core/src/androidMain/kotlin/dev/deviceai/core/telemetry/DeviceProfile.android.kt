package dev.deviceai.core.telemetry

import android.os.Build
import dev.deviceai.core.InternalDeviceAiApi

@InternalDeviceAiApi
@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
actual object DeviceProfile {
    actual val osName: String = "android"
    actual val osVersion: String = Build.VERSION.RELEASE

    actual val totalMemoryMb: Long by lazy {
        try {
            java.io.File("/proc/meminfo")
                .readLines()
                .firstOrNull { it.startsWith("MemTotal:") }
                ?.split("\\s+".toRegex())
                ?.getOrNull(1)
                ?.toLongOrNull()
                ?.let { it / 1024 } // kB → MB
                ?: -1L
        } catch (_: Exception) {
            -1L
        }
    }
}
