# flutter/speech

> **Status: planned**

Native Dart SDK for on-device Speech-to-Text and Text-to-Speech in Flutter apps. Calls
whisper.cpp and piper via FFI on both Android and iOS — no platform channel overhead,
no dependency on the Kotlin or Swift SDKs.

## What it will provide

- `DeviceAISpeech` Dart class with `startListening()`, `stopListening()`, `speak()` APIs
- Stream-based transcription results
- Distributed via [pub.dev](https://pub.dev) as `deviceai_speech`

## Installation

```yaml
# pubspec.yaml
dependencies:
  deviceai_speech: ^0.1.0
```

## Architecture

```
Your Flutter App  (Dart)
    │
    ▼
flutter/speech  (Dart SDK + dart:ffi)
    │
    ▼
whisper.cpp + piper  (C++ — same engines as kotlin/speech and ios/speech)
```

The Dart SDK calls the native C++ engines directly via `dart:ffi`, compiled as a shared
library for Android (`.so`) and a static framework for iOS.

## Contributing

Implementation PRs welcome. See the root [ARCHITECTURE.md](../../ARCHITECTURE.md) for
the native engine details.
