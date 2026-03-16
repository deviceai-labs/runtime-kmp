import Foundation

/// Engine init-time parameters. Mirrors `LlmInitConfig` in kotlin/llm.
struct LlmInitConfig {
    var contextSize: Int  = 4096
    var maxThreads:  Int  = max(1, ProcessInfo.processInfo.processorCount / 2)
    var useGpu:      Bool = true
}
