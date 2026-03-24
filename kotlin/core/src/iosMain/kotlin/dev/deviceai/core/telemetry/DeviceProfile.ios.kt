package dev.deviceai.core.telemetry

import dev.deviceai.core.InternalDeviceAiApi
import kotlinx.cinterop.ExperimentalForeignApi
import platform.Foundation.NSProcessInfo

@InternalDeviceAiApi
@Suppress("EXPECT_ACTUAL_CLASSIFIERS_ARE_IN_BETA_WARNING")
@OptIn(ExperimentalForeignApi::class)
actual object DeviceProfile {
    actual val osName: String = "ios"
    actual val osVersion: String = NSProcessInfo.processInfo.operatingSystemVersionString
    actual val totalMemoryMb: Long =
        (NSProcessInfo.processInfo.physicalMemory / 1024u / 1024u).toLong()
}
