# DeviceAI Runtime · KMP

**On-device AI runtime for mobile. Run speech recognition and synthesis locally — no cloud, no latency, no privacy risk.**

[![Build](https://github.com/NikhilBhutani/deviceai-runtime-kmp/actions/workflows/ci.yml/badge.svg)](https://github.com/NikhilBhutani/deviceai-runtime-kmp/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue)](LICENSE)
[![Maven Central](https://img.shields.io/maven-central/v/com.nikhilbhutani/runtime-speech)](https://central.sonatype.com/artifact/com.nikhilbhutani/runtime-speech)
[![Kotlin](https://img.shields.io/badge/Kotlin-2.2-blueviolet?logo=kotlin)](https://kotlinlang.org)
[![KMP](https://img.shields.io/badge/Kotlin_Multiplatform-Android%20%7C%20iOS%20%7C%20Desktop-blue)](https://www.jetbrains.com/kotlin-multiplatform/)

---

## Why DeviceAI Runtime?

Mobile AI is broken for most teams:

- **Fragmented SDKs** — separate wrappers for Android, iOS, desktop
- **Cloud dependency** — latency, cost, and user data leaving the device
- **Model loading is messy** — threading, memory pressure, cold-start problems
- **Every team reinvents inference wrappers** — from scratch, badly

DeviceAI Runtime solves this with a single Kotlin Multiplatform library: one API, all platforms, fully local.

---

## Benchmarks

Real numbers on real hardware. No marketing RTF.

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
DeviceAI Runtime  (com.nikhilbhutani)
    │   SpeechBridge — unified Kotlin API
    │   ModelRegistry — auto-download from HuggingFace
    │
    ├── Android / Desktop
    │       JNI  →  libspeech_jni.so
    │
    └── iOS
            C Interop  →  speech_ios framework
                │
                ▼
        Native Inference
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
| Voice activity detection | ✅ |
| Offline — zero cloud dependency | ✅ |
| LLM inference | 🗓 Planned |

---

## Quick Start

### 1. Add the dependency

**Via Maven Central:**

```kotlin
// build.gradle.kts
implementation("com.nikhilbhutani:runtime-speech:0.1.1")
```

No repository configuration needed — Maven Central is included by default in Android and KMP projects.

**Or use as a local module** (clone and include directly):

```kotlin
// settings.gradle.kts
include(":runtime-speech")
project(":runtime-speech").projectDir = File("path/to/deviceai-runtime-kmp/runtime-speech")

// build.gradle.kts
implementation(project(":runtime-speech"))
```

### 2. Speech-to-Text

```kotlin
import com.nikhilbhutani.SpeechBridge
import com.nikhilbhutani.SttConfig
import com.nikhilbhutani.models.ModelRegistry

// Download model on first run (whisper-tiny = 75MB)
val model = ModelRegistry.getOrDownload("ggml-tiny.en.bin")

// Initialize
SpeechBridge.initStt(model.path, SttConfig(language = "en"))

// Transcribe audio samples (FloatArray, 16kHz mono)
val text = SpeechBridge.transcribeAudio(samples)

// Or transcribe a file
val text = SpeechBridge.transcribe("/path/to/audio.wav")

// Cleanup
SpeechBridge.shutdownStt()
```

### 3. Text-to-Speech

```kotlin
import com.nikhilbhutani.SpeechBridge
import com.nikhilbhutani.TtsConfig

SpeechBridge.initTts(
    modelPath = "/path/to/voice.onnx",
    configPath = "/path/to/voice.json",
    config = TtsConfig(speechRate = 1.0f)
)

val samples: ShortArray = SpeechBridge.synthesize("Hello, world!")

SpeechBridge.shutdownTts()
```

### Android — initialize storage before models

```kotlin
// In Application.onCreate() or MainActivity
PlatformStorage.initialize(context)
```

---

## Models

### Whisper (STT) — via [ggerganov/whisper.cpp](https://github.com/ggerganov/whisper.cpp)

| Model | Size | Best for |
|-------|------|----------|
| tiny.en | 75 MB | Fast, English-only |
| base | 142 MB | Balanced |
| small | 466 MB | High accuracy |

### Piper (TTS) — via [rhasspy/piper-voices](https://huggingface.co/rhasspy/piper-voices)

| Voice | Size | Language |
|-------|------|----------|
| en_US-lessac-medium | 60 MB | English (US) |
| en_GB-alba-medium | 55 MB | English (UK) |
| de_DE-thorsten-medium | 65 MB | German |

Models are downloaded automatically via `ModelRegistry` on first use.

---

## Platform Support

| Platform | STT | TTS | Sample App |
|----------|-----|-----|------------|
| Android | ✅ | ✅ | ✅ |
| iOS | ✅ | ✅ | ✅ |
| macOS (Desktop) | ✅ | ✅ | ✅ |
| Linux | 🚧 | 🚧 | — |
| Windows | 🚧 | 🚧 | — |

---

## Building from Source

**Prerequisites:** CMake 3.22+, Android NDK r26+, Xcode 15+ (for iOS), Kotlin 2.0+

```bash
git clone --recursive https://github.com/NikhilBhutani/deviceai-runtime-kmp.git
cd deviceai-runtime-kmp

# Compile check
./gradlew :runtime-speech:compileKotlinJvm
./gradlew :runtime-speech:compileDebugKotlinAndroid

# Run the desktop sample
./gradlew :samples:composeApp:run
```

---

## Roadmap

- [x] STT via whisper.cpp
- [x] TTS via Piper + ONNX
- [x] Model auto-download from HuggingFace
- [x] KMP: Android, iOS, Desktop
- [x] Maven Central release (`com.nikhilbhutani:runtime-speech:0.1.1`)
- [ ] LLM inference module (`runtime-llm`)
- [ ] Cloud fallback layer
- [ ] Streaming TTS

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Issues and PRs are welcome.

---

## Sample App

The `samples/composeApp` directory contains a working Compose Multiplatform demo — downloads whisper-tiny on first launch, records audio, shows transcription with live latency.
