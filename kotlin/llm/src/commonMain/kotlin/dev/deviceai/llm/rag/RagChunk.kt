package dev.deviceai.llm.rag

/**
 * A single retrieved text snippet from a [RagRetriever].
 *
 * @param text    The raw document chunk text that will be injected into the prompt.
 * @param source  Optional identifier for where this chunk came from (file name, URL, etc.).
 * @param score   Relevance score assigned by the retriever (higher = more relevant).
 */
data class RagChunk(val text: String, val source: String? = null, val score: Float = 0f)
