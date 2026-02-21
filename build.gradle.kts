plugins {
    alias(libs.plugins.kotlinMultiplatform) apply false
    alias(libs.plugins.compose.multiplatform) apply false
    alias(libs.plugins.compose.compiler) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.android.application) apply false
}

allprojects {
    group = "io.github.nikhilbhutani"
    version = System.getenv("RELEASE_VERSION") ?: "0.1.0-SNAPSHOT"
}
