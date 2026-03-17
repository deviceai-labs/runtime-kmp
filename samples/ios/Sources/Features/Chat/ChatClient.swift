import ComposableArchitecture
import DeviceAiLlm

// MARK: - Dependency

struct ChatClient: Sendable {
    /// Send `text` to the model at `modelPath`; returns a token stream.
    var send:   @Sendable (String, String) async -> AsyncThrowingStream<String, Error>
    var cancel: @Sendable () async -> Void
    var clear:  @Sendable () async -> Void
}

extension ChatClient: DependencyKey {
    static let liveValue: ChatClient = {
        let sessionCache = ChatSessionCache()

        return ChatClient(
            send: { text, modelPath in
                await sessionCache.send(text, modelPath: modelPath)
            },
            cancel: { await sessionCache.cancel() },
            clear:  { await sessionCache.clearHistory() }
        )
    }()

    static let previewValue = ChatClient(
        send: { text, _ in
            AsyncThrowingStream { c in
                Task {
                    let words = "I'm a preview response for: \(text)".split(separator: " ")
                    for word in words {
                        try? await Task.sleep(for: .milliseconds(80))
                        c.yield(String(word) + " ")
                    }
                    c.finish()
                }
            }
        },
        cancel: { },
        clear:  { }
    )
}

extension DependencyValues {
    var chatClient: ChatClient {
        get { self[ChatClient.self] }
        set { self[ChatClient.self] = newValue }
    }
}

// MARK: - Session cache (re-creates session when model changes)

private actor ChatSessionCache {
    private var session: ChatSession?
    private var currentPath: String?

    private func getSession(for path: String) -> ChatSession {
        if currentPath == path, let s = session { return s }
        let s = DeviceAI.llm.chat(modelPath: path) {
            $0.systemPrompt = "You are a helpful on-device AI assistant. Be concise."
            $0.maxTokens    = 512
            $0.temperature  = 0.7
        }
        session     = s
        currentPath = path
        return s
    }

    func send(_ text: String, modelPath: String) -> AsyncThrowingStream<String, Error> {
        let s = getSession(for: modelPath)
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    for try await token in await s.send(text) {
                        continuation.yield(token)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func cancel() {
        session?.cancel()
    }

    func clearHistory() async {
        await session?.clearHistory()
    }
}
