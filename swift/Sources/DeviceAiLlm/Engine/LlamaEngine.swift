import Foundation
import DeviceAiCore

/// LLM inference engine backed by llama.cpp via CLlama.xcframework.
///
/// Internal — never exposed publicly. `ChatSession` is the developer-facing API.
///
/// ## C interop pattern
///
/// `CLlama.xcframework` exposes `llama.h`. When the binary is linked:
/// ```swift
/// import CLlama
/// var params = llama_context_default_params()
/// params.n_ctx        = Int32(contextSize)
/// params.n_threads    = Int32(threads)
/// params.n_gpu_layers = useGpu ? 99 : 0
/// let model = llama_load_model_from_file(path, params)
/// let ctx   = llama_new_context_with_model(model, params)
/// ```
///
/// ## Thread safety
///
/// All llama.cpp C calls happen on a dedicated serial `DispatchQueue`.
/// Swift `actor` isolation in `ChatSession` ensures only one `generate`
/// call is in flight at a time — the queue gives us deterministic thread pinning
/// for the C layer which is not thread-safe internally.
///
/// ## Stub mode
///
/// Until `CLlama.xcframework` is linked, the engine operates in stub mode —
/// it logs a warning and returns a placeholder response. This lets the Swift
/// layer compile, test, and be used in the sample app without the binary.
final class LlamaEngine: @unchecked Sendable {

    private let queue = DispatchQueue(label: "dev.deviceai.llm.inference", qos: .userInitiated)
    private var isCancelled = false
    private var isLoaded    = false
    private var isClosed    = false

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    func load(modelPath: String, config: ChatConfig) async throws {
        guard !isClosed else { throw DeviceAiError.sessionClosed }

        // ABI version check — each binary embeds its minimum Core version.
        // Uncomment when CLlama is linked:
        // guard SDKVersion.core >= CLlama.minimumCoreVersion else {
        //     throw DeviceAiError.versionMismatch(core: SDKVersion.core, feature: CLlama.version)
        // }

        // File existence check is only meaningful when CLlama is linked.
        // In stub mode the path is ignored — uncomment when binary is available:
        // guard FileManager.default.fileExists(atPath: modelPath) else {
        //     throw DeviceAiError.modelNotFound(path: modelPath)
        // }

        return try await withCheckedThrowingContinuation { continuation in
            queue.async {
                // ── CLlama linked (production) ────────────────────────────────
                // var p = llama_context_default_params()
                // p.n_ctx        = Int32(config.contextSize)
                // p.n_threads    = Int32(config.threads)
                // p.n_gpu_layers = config.useGpu ? 99 : 0
                // let model = llama_load_model_from_file(modelPath, p)
                // guard model != nil else {
                //     continuation.resume(throwing: DeviceAiError.modelLoadFailed(reason: "llama_load_model_from_file returned nil"))
                //     return
                // }
                // self.ctx = llama_new_context_with_model(model, p)
                // ── Stub mode ─────────────────────────────────────────────────
                DeviceAiLogger.warning("LlamaEngine", "CLlama.xcframework not linked — stub mode active.")
                self.isLoaded = true
                continuation.resume()
            }
        }
    }

    func close() async {
        guard !isClosed else { return }
        isClosed = true
        // llama_free(ctx); llama_free_model(model)
        DeviceAiLogger.info("LlamaEngine", "Closed.")
    }

    // ── Generating ────────────────────────────────────────────────────────────

    func generate(messages: [LlmMessage], config: LlmGenConfig) async throws -> LlmResult {
        let start = Date()
        var full = ""
        var count = 0
        for try await token in generateStream(messages: messages, config: config) {
            full += token; count += 1
        }
        return LlmResult(
            text: full, tokenCount: count, promptTokenCount: nil,
            finishReason: isCancelled ? .cancelled : .stop,
            generationTimeMs: Int64(Date().timeIntervalSince(start) * 1000)
        )
    }

    func generateStream(messages: [LlmMessage], config: LlmGenConfig) -> AsyncThrowingStream<String, Error> {
        let augmented: [LlmMessage] = config.ragStore.map { store in
            RagAugmentor.augment(messages: messages,
                                 with: store.retrieve(query: messages.last?.content ?? "", topK: config.ragTopK))
        } ?? messages
        _ = augmented  // will be passed to native generate call when CLlama is linked

        return AsyncThrowingStream { continuation in
            self.isCancelled = false
            self.queue.async {
                guard !self.isClosed  else { continuation.finish(throwing: DeviceAiError.sessionClosed); return }
                guard self.isLoaded   else { continuation.finish(throwing: DeviceAiError.notInitialised); return }

                // ── CLlama linked (production) ────────────────────────────────
                // let prompt = self.buildPrompt(from: augmented)
                // 1. llama_tokenize(ctx, prompt, tokens, maxTokens, true)
                // 2. llama_eval(ctx, tokens, n, 0, config.maxThreads)
                // 3. loop: sample → yield text → eval single token
                //
                // ── Stub mode ─────────────────────────────────────────────────
                let stub = ["[", "stub", " — ", "CLlama", ".xcframework", " not", " linked", "]"]
                for token in stub {
                    guard !self.isCancelled else { break }
                    continuation.yield(token)
                    Thread.sleep(forTimeInterval: 0.04)
                }
                continuation.finish()
            }
        }
    }

    func cancel() { isCancelled = true }

    // ── Private ───────────────────────────────────────────────────────────────

    private func buildPrompt(from messages: [LlmMessage]) -> String {
        messages.map { m in
            switch m.role {
            case .system:    return "<|system|>\n\(m.content)\n"
            case .user:      return "<|user|>\n\(m.content)\n"
            case .assistant: return "<|assistant|>\n\(m.content)\n"
            }
        }.joined() + "<|assistant|>\n"
    }
}
