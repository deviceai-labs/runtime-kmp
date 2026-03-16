/// A single message in a conversation.
/// Mirrors `LlmMessage` + `LlmRole` in kotlin/llm — identical structure.
public struct LlmMessage: Sendable, Codable, Equatable {
    public let role: LlmRole
    public let content: String

    public init(role: LlmRole, content: String) {
        self.role = role; self.content = content
    }

    public static func system(_ content: String)    -> LlmMessage { .init(role: .system,    content: content) }
    public static func user(_ content: String)      -> LlmMessage { .init(role: .user,      content: content) }
    public static func assistant(_ content: String) -> LlmMessage { .init(role: .assistant, content: content) }
}

/// Role of a message sender.
/// Mirrors `LlmRole` in kotlin/llm — identical cases.
public enum LlmRole: String, Sendable, Codable, CaseIterable {
    case system, user, assistant
}
