rootProject.name = "deviceai-runtime-kmp"

pluginManagement {
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

include(":kotlin:core")
include(":kotlin:speech")
include(":kotlin:llm")
include(":samples:composeApp")
