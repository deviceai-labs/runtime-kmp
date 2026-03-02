# ios/speech

> **Status: planned**

Native Swift SDK for on-device Speech-to-Text and Text-to-Speech on iOS. Built directly on
whisper.cpp and piper — no Kotlin, no KMP, no bridging layer. A first-class Swift dependency
for iOS-only teams.

## What it will provide

- `SpeechRecognizer` and `SpeechSynthesizer` Swift types with `async`/`await` interfaces
- Combine publishers for streaming transcription results
- Distributed via [Swift Package Index](https://swiftpackageindex.com)

## Installation

```swift
// Package.swift
.package(url: "https://github.com/deviceai-labs/deviceai", from: "0.1.0")
```

## Architecture

```
Your Swift App
    │
    ▼
ios/speech  (Swift SDK)
    │
    ▼
whisper.cpp + piper  (C++ — same engines as kotlin/speech)
```

The Swift SDK links whisper.cpp and piper directly as a Swift Package binary target —
no XCFramework wrapping, no Kotlin runtime dependency.

## Contributing

Implementation PRs welcome. See the root [ARCHITECTURE.md](../../ARCHITECTURE.md) for
the native engine details.
