import io.gitlab.arturbosch.detekt.extensions.DetektExtension
import org.jlleitschuh.gradle.ktlint.KtlintExtension

plugins {
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.compose.multiplatform) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.ktlint) apply false
    alias(libs.plugins.detekt) apply false
}

allprojects {
    group = "dev.deviceai"
    version = System.getenv("RELEASE_VERSION") ?: "0.1.0-SNAPSHOT"
}

subprojects {
    apply(plugin = "org.jlleitschuh.gradle.ktlint")
    apply(plugin = "io.gitlab.arturbosch.detekt")

    configure<KtlintExtension> {
        // 1.3.1 bundles Kotlin 1.9 parser — compatible with our Kotlin 2.2.21 syntax
        // (1.5.x parser fails on some KMP/cinterop patterns)
        version.set("1.3.1")
        android.set(true)
        outputToConsole.set(true)
        ignoreFailures.set(false)
        filter {
            // Only lint our own source — skip generated files and build scripts
            exclude("**/generated/**")
            exclude("**/build/**")
            exclude("**/*.kts")
        }
    }

    configure<DetektExtension> {
        config.setFrom("$rootDir/config/detekt/detekt.yml")
        buildUponDefaultConfig = true
        // Suppress existing violations via a baseline so new code is still enforced
        baseline = file("$rootDir/config/detekt/baseline.xml")
        // Include all KMP source sets
        source.setFrom(
            "src/commonMain/kotlin",
            "src/androidMain/kotlin",
            "src/jvmMain/kotlin",
            "src/iosMain/kotlin",
            "src/jvmCommonMain/kotlin"
        )
    }
}
