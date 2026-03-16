/// Injects retrieved chunks into the messages array before sending to the engine.
/// Pure function — originals untouched. Mirrors `RagAugmentor` in kotlin/llm.
public enum RagAugmentor {

    public static func augment(messages: [LlmMessage], with chunks: [RagChunk]) -> [LlmMessage] {
        guard !chunks.isEmpty else { return messages }
        let context = "\n\nContext:\n" + chunks.map(\.text).joined(separator: "\n\n---\n\n")

        if let i = messages.firstIndex(where: { $0.role == .system }) {
            var m = messages
            m[i] = LlmMessage(role: .system, content: m[i].content + context)
            return m
        }
        return [LlmMessage(role: .system, content: "You are a helpful assistant." + context)] + messages
    }
}
