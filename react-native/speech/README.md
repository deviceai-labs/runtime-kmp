# react-native/speech

> **Status: planned**

Native TypeScript SDK for on-device Speech-to-Text and Text-to-Speech in React Native apps.
Calls whisper.cpp and piper via JSI on both Android and iOS — no dependency on the Kotlin
or Swift SDKs.

## What it will provide

- `startListening()`, `stopListening()`, `speak()` TypeScript APIs with full type definitions
- Event-based transcription callbacks
- Distributed via npm as `react-native-deviceai-speech`

## Installation

```sh
npm install react-native-deviceai-speech
# or
yarn add react-native-deviceai-speech
```

## Architecture

```
Your React Native App  (TypeScript)
    │
    ▼
react-native/speech  (TypeScript SDK + JSI / New Architecture)
    │
    ▼
whisper.cpp + piper  (C++ — same engines as kotlin/speech and ios/speech)
```

The TypeScript SDK uses React Native's New Architecture (JSI) to call the C++ engines
directly — compiled as a shared library for Android (`.so`) and a static framework for iOS.

## Contributing

Implementation PRs welcome. See the root [ARCHITECTURE.md](../../ARCHITECTURE.md) for
the native engine details.
