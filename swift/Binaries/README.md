# Binaries

This directory contains pre-compiled XCFramework binaries for the DeviceAI Swift SDK.

## Contents (to be built)

| File                      | C++ library  | Used by        |
|--------------------------|--------------|----------------|
| `CLlama.xcframework`     | llama.cpp    | DeviceAILLM    |
| `CWhisper.xcframework`   | whisper.cpp  | DeviceAISTT    |
| `CSherpaOnnx.xcframework`| sherpa-onnx  | DeviceAITTS    |

## Building

Run from the repo root:

```bash
scripts/build-xcframeworks.sh
```

This script:
1. Builds each C++ library for `arm64-apple-ios`, `arm64-apple-ios-simulator`, `x86_64-apple-ios-simulator`
2. Packages them into fat `.xcframework` bundles
3. Places them here

The C++ source is in the monorepo submodules:
- `cpp/llama.cpp/`
- `cpp/whisper.cpp/`
- `cpp/sherpa-onnx/`

## Stub mode

Until the XCFrameworks are built, all engine files operate in **stub mode**:
- `LlamaEngine.swift` — returns empty `AsyncThrowingStream`
- `WhisperEngine.swift` — returns `TranscriptionResult(text: "", ...)`
- `PiperEngine.swift` — returns `AudioSegment(samples: [], sampleRate: 22050)`

This lets the SDK compile and unit tests run on CI without requiring the native libraries.
