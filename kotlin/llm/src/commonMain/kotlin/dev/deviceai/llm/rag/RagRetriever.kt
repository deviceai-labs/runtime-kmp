package dev.deviceai.llm.rag

/**
 * Retrieves relevant text chunks from a knowledge base given a user query.
 *
 * Implement this interface to plug in any retrieval backend:
 * - [BM25RagStore] — built-in keyword search, no extra model needed
 * - Semantic embedding store — embed query + cosine similarity
 * - SQLite FTS5 — persistent full-text search
 * - Remote vector DB — for server-side retrieval
 */
interface RagRetriever {

    /**
     * Retrieve the most relevant chunks for the given query.
     *
     * @param query  The user's question or search term.
     * @param topK   Maximum number of chunks to return.
     * @return Chunks sorted by descending relevance score.
     */
    fun retrieve(query: String, topK: Int): List<RagChunk>
}
