import Foundation

/// A single turn in a conversation — role-based internally.
///
/// Using role + content + timestamp (not just `user`/`assistant` strings)
/// future-proofs for tool calls, multi-modal messages, and system injections
/// without any migration pain.
///
/// Convenience properties (`isUser`, `isAssistant`) keep the public API
/// readable without exposing raw role strings.
public struct ChatTurn: Sendable, Identifiable {
    public let id: UUID
    public let role: LlmRole
    public let content: String
    public let timestamp: Date

    public var isUser:      Bool { role == .user      }
    public var isAssistant: Bool { role == .assistant  }
    public var isSystem:    Bool { role == .system     }

    init(role: LlmRole, content: String) {
        self.id        = UUID()
        self.role      = role
        self.content   = content
        self.timestamp = Date()
    }
}
