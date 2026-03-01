# DeviceAI Runtime · KMP

**On-device AI runtime for Kotlin Multiplatform. Ship speech recognition and synthesis on Android, iOS, and Desktop — no cloud, no latency, no privacy risk.**

[![Build](https://github.com/deviceai-labs/runtime-kmp/actions/workflows/ci.yml/badge.svg)](https://github.com/deviceai-labs/runtime-kmp/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)
[![Maven Central](https://img.shields.io/maven-central/v/dev.deviceai/runtime-speech)](https://central.sonatype.com/artifact/dev.deviceai/runtime-speech)
[![Kotlin](https://img.shields.io/badge/Kotlin-2.2-blueviolet?logo=kotlin)](https://kotlinlang.org)
[![KMP](https://img.shields.io/badge/Kotlin_Multiplatform-Android%20%7C%20iOS%20%7C%20Desktop-blue)](https://www.jetbrains.com/kotlin-multiplatform/)

---

## Why DeviceAI Runtime?

Mobile AI is broken for most teams:

- **Fragmented SDKs** — separate wrappers for Android, iOS, and desktop that never stay in sync
- **Cloud dependency** — latency, cost, and user data leaving the device
- **Model loading is messy** — threading, memory pressure, cold-start, and caching reinvented every time
- **Every team writes the same wrapper** — from scratch, badly

DeviceAI Runtime gives you a single Kotlin Multiplatform API: one integration, all platforms, fully local.

---

## Benchmarks

Real numbers on real hardware.

| Device | Chip | Model | Audio | Inference | RTF |
|--------|------|-------|-------|-----------|-----|
| Redmi Note 9 Pro | Snapdragon 720G | whisper-tiny | 5.4s | 746ms | **0.14x** |

> RTF < 1.0 = faster than real-time. 0.14x = ~7× faster than real-time on a mid-range Android phone.

---

## Architecture

```
Your App
    │
    ▼
DeviceAIRuntime.configure(Environment.DEVELOPMENT)   ← one-time SDK init
    │
    ├── runtime-core   (dev.deviceai:runtime-core)
    │       CoreSDKLogger — structured, environment-aware logging
    │       ModelRegistry — model discovery, download, local management
    │       PlatformStorage — cross-platform file I/O
    │
    └── runtime-speech  (dev.deviceai:runtime-speech)
            SpeechBridge — unified STT + TTS Kotlin API
            ModelRegistry — Whisper + Piper model catalog from HuggingFace
                │
                ├── Android / Desktop
                │       JNI → libspeech_jni.so / libspeech_jni.dylib
                │
                └── iOS
                        C Interop → libspeech_merged.a
                            │
                            ├── whisper.cpp  (STT)
                            └── piper + ONNX  (TTS)
```

---

## Features

| Feature | Status |
|---------|--------|
| Speech-to-Text (Whisper) | ✅ Android, iOS, Desktop |
| Text-to-Speech (Piper) | ✅ Android, iOS, Desktop |
| Auto model download (HuggingFace) | ✅ |
| GPU acceleration (Metal / Vulkan) | ✅ |
| Streaming transcription | ✅ |
| Environment-aware logging | ✅ |
| Offline — zero cloud dependency | ✅ |
| LLM inference | 🗓 Planned |

---

## Integration — 5 minutes to first transcription

### Step 1 — Add dependencies

```kotlin
// build.gradle.kts (your module)
implementation("dev.deviceai:runtime-core:0.1.0")
implementation("dev.deviceai:runtime-speech:0.1.0")
```

No extra repository config needed — both artifacts are on Maven Central.

---

### Step 2 — Initialize the SDK

Call `DeviceAIRuntime.configure()` **once**, before any other SDK call. This sets the log verbosity for the environment you're running in.

#### Android — `Application.onCreate()` or `MainActivity.onCreate()`

```kotlin
import dev.deviceai.core.DeviceAIRuntime
import dev.deviceai.core.Environment
import dev.deviceai.models.PlatformStorage

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // 1. Configure environment (switch to PRODUCTION for release builds)
        DeviceAIRuntime.configure(Environment.DEVELOPMENT)

        // 2. Android needs a Context for file storage — must come after configure()
        PlatformStorage.initialize(this)

        setContent { App() }
    }
}
```

#### iOS — `MainViewController.kt`

```kotlin
import dev.deviceai.core.DeviceAIRuntime
import dev.deviceai.core.Environment

fun MainViewController(): UIViewController = ComposeUIViewController {
    remember { DeviceAIRuntime.configure(Environment.DEVELOPMENT) }
    App()
}
```

> **Info.plist** — add the microphone usage description and ProMotion key:
> ```xml
> <key>NSMicrophoneUsageDescription</key>
> <string>Used for on-device speech recognition.</string>
> <key>CADisableMinimumFrameDurationOnPhone</key>
> <true/>
> ```

#### Desktop — `main.kt`

```kotlin
import dev.deviceai.core.DeviceAIRuntime
import dev.deviceai.core.Environment

fun main() = application {
    DeviceAIRuntime.configure(Environment.DEVELOPMENT)
    Window(onCloseRequest = ::exitApplication, title = "My App") { App() }
}
```

---

### Step 3 — Download a model

`ModelRegistry` fetches the catalog from HuggingFace and downloads models to local storage. Downloads resume automatically on interruption.

```kotlin
import dev.deviceai.models.ModelRegistry

// Returns immediately if already downloaded, otherwise streams from HuggingFace
val model = ModelRegistry.getOrDownload("ggml-tiny.en.bin") { progress ->
    println("${progress.percentComplete.toInt()}% — ${progress.bytesDownloaded / 1_000_000}MB")
}
```

> **whisper-tiny.en** (75MB) is the recommended starting point — it runs 7× faster than real-time on mid-range Android hardware.

---

### Step 4 — Transcribe speech

```kotlin
import dev.deviceai.SpeechBridge
import dev.deviceai.SttConfig

// Initialize the STT engine with the downloaded model
SpeechBridge.initStt(model.modelPath, SttConfig(language = "en", useGpu = true))

// Transcribe a FloatArray of 16kHz mono PCM samples
val text: String = SpeechBridge.transcribeAudio(samples)

// Or transcribe a WAV file directly
val text: String = SpeechBridge.transcribe("/path/to/audio.wav")

// Clean up when done
SpeechBridge.shutdownStt()
```

---

### Step 5 — Synthesize speech (optional)

```kotlin
import dev.deviceai.SpeechBridge
import dev.deviceai.TtsConfig

SpeechBridge.initTts(
    modelPath  = voice.modelPath,
    configPath = voice.configPath!!,
    config     = TtsConfig(speechRate = 1.0f)
)

val pcm: ShortArray = SpeechBridge.synthesize("Hello from DeviceAI.")
// Play pcm with AudioTrack (Android), AVAudioEngine (iOS), or javax.sound (Desktop)

SpeechBridge.shutdownTts()
```

---

## Logging

`DeviceAIRuntime.configure()` sets the log verbosity automatically:

| Environment | Min level | What you see |
|-------------|-----------|--------------|
| `DEVELOPMENT` | `DEBUG` | Everything — debug, info, warnings, errors |
| `PRODUCTION` | `WARN` | Warnings and errors only |

You can forward SDK logs to your own backend (Crashlytics, Datadog, Sentry, etc.):

```kotlin
DeviceAIRuntime.configure(
    environment = Environment.PRODUCTION,
    logHandler  = { event ->
        Crashlytics.log("${event.level} [${event.tag}] ${event.message}")
        event.throwable?.let { Crashlytics.recordException(it) }
    }
)
```

---

## Models

### Whisper (STT) — via [ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp)

| Model | Size | Speed | Best for |
|-------|------|-------|----------|
| `ggml-tiny.en.bin` | 75 MB | 7× real-time | English, mobile-first |
| `ggml-base.bin` | 142 MB | Fast | Multilingual, balanced |
| `ggml-small.bin` | 466 MB | Medium | Higher accuracy |
| `ggml-medium.bin` | 1.5 GB | Slow | Desktop / server |

### Piper (TTS) — via [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices)

| Voice | Size | Language |
|-------|------|----------|
| `en_US-lessac-medium` | 60 MB | English (US) |
| `en_GB-alba-medium` | 55 MB | English (UK) |
| `de_DE-thorsten-medium` | 65 MB | German |

Browse all voices via `ModelRegistry.getPiperVoices()` — filters by language and quality.

---

## Platform Support

| Platform | STT | TTS | Sample App |
|----------|-----|-----|------------|
| Android (API 24+) | ✅ | ✅ | ✅ |
| iOS 16+ | ✅ | ✅ | ✅ |
| macOS Desktop | ✅ | ✅ | ✅ |
| Linux | 🚧 | 🚧 | — |
| Windows | 🚧 | 🚧 | — |

---

## Building from Source

**Prerequisites:** CMake 3.22+, Android NDK r26+, Xcode 16+ (iOS), Kotlin 2.2+

```bash
git clone --recursive https://github.com/deviceai-labs/runtime-kmp.git
cd runtime-kmp

# Compile checks
./gradlew :runtime-core:compileKotlinJvm
./gradlew :runtime-speech:compileKotlinJvm
./gradlew :runtime-speech:compileDebugKotlinAndroid

# Run the desktop sample app
./gradlew :samples:composeApp:run
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a deep-dive on the native layer, CMake setup, and module structure.

---

## Roadmap

DeviceAI Runtime is modular — each AI modality is an independent, independently-versioned module.

### `runtime-core` — Shared Infrastructure ✅
- [x] `ModelInfo`, `LocalModel`, `PlatformStorage`, `MetadataStore`
- [x] `CoreSDKLogger` — structured, environment-aware logging
- [x] `DeviceAIRuntime` — unified SDK entry point with `Environment` config
- [x] Maven Central (`dev.deviceai:runtime-core:0.1.0`)

### `runtime-speech` — Speech ✅
- [x] STT via whisper.cpp
- [x] TTS via Piper + ONNX
- [x] Model auto-download from HuggingFace
- [x] KMP: Android, iOS, Desktop
- [x] Maven Central (`dev.deviceai:runtime-speech:0.1.0`)
- [ ] Streaming TTS
- [ ] Voice activity detection (VAD)

### `runtime-llm` — Large Language Models 🗓
- [ ] Local LLM inference via llama.cpp
- [ ] GGUF model support
- [ ] Streaming token generation

### `runtime-vlm` — Vision-Language Models 🗓
- [ ] Image + text inference on-device
- [ ] Camera feed integration

### `runtime-kmp` — Meta-package 🗓
- [ ] Single dependency that re-exports all modules

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs welcome.

---

## Sample App

`samples/composeApp/` is a working Compose Multiplatform demo — auto-downloads whisper-tiny on first launch, records audio, and shows transcription with live latency. Runs on Android, iOS, and Desktop.

```bash
# Desktop
./gradlew :samples:composeApp:run

# Android — open in Android Studio and run on device/emulator

# iOS — open samples/iosApp/iosApp.xcodeproj in Xcode and run
```
