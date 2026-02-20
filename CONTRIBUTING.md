# Contributing to DeviceAI Runtime

Thanks for your interest. Here's how to get involved.

## Getting Started

1. Fork the repo and clone with submodules:
   ```bash
   git clone --recursive https://github.com/NikhilBhutani/deviceai-runtime-kmp.git
   ```
2. Open in Android Studio (Hedgehog or later) or IntelliJ IDEA.
3. Make sure CMake 3.22+ and Android NDK r26+ are installed.

## What to Work On

- Check [open issues](https://github.com/NikhilBhutani/deviceai-runtime-kmp/issues) — issues labeled `good first issue` are a good starting point.
- For larger changes, open an issue to discuss the approach before submitting a PR.

## Pull Requests

- Keep PRs focused — one logical change per PR.
- Run the compile checks before opening:
  ```bash
  ./gradlew :runtime-speech:compileKotlinJvm
  ./gradlew :runtime-speech:compileDebugKotlinAndroid
  ```
- Write a clear PR description: what changed and why.
- If you're adding a new API, update the README Quick Start section.

## Code Style

- Follow existing Kotlin conventions in the codebase.
- C++ code in `runtime-speech/src/commonMain/cpp/` — match the style of `whisper_jni.cpp`.
- No unnecessary abstractions — keep it simple.

## Reporting Bugs

Use the [bug report template](.github/ISSUE_TEMPLATE/bug_report.md). Include:
- Platform and device spec
- Kotlin / AGP / NDK versions
- Logcat or console output
- Steps to reproduce

## Questions

Open a [GitHub Discussion](https://github.com/NikhilBhutani/deviceai-runtime-kmp/discussions) — not an issue.
