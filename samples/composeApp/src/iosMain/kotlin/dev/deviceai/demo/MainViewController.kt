package dev.deviceai.demo

import androidx.compose.runtime.remember
import androidx.compose.ui.window.ComposeUIViewController
import dev.deviceai.core.DeviceAIRuntime
import dev.deviceai.core.Environment
import platform.UIKit.UIViewController

fun MainViewController(): UIViewController = ComposeUIViewController {
    // Configure once per process. Switch to PRODUCTION for release builds.
    remember { DeviceAIRuntime.configure(Environment.DEVELOPMENT) }
    App()
}
