/// Public contract for RAG retrieval backends.
/// `BM25Store` is built-in. Any embedding store, vector DB, or FTS5 store
/// can conform without changing `ChatSession` or `LlamaEngine`.
public protocol Retrieving: Sendable {
    func retrieve(query: String, topK: Int) -> [RagChunk]
}
