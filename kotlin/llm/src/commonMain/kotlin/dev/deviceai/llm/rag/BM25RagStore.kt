package dev.deviceai.llm.rag

import kotlin.math.ln

/**
 * Offline keyword-based retriever using the BM25 ranking algorithm.
 *
 * The BM25 index is built **lazily** on the first [retrieve] call — construction
 * is cheap regardless of corpus size. If [LlmGenConfig.ragStore] is null the store
 * is never queried and the index is never built.
 *
 * @param rawChunks The raw text chunks that form your knowledge base.
 * @param sources   Optional parallel list of source identifiers (file names, URLs, etc.).
 */
class BM25RagStore(private val rawChunks: List<String>, private val sources: List<String?> = emptyList()) :
    RagRetriever {

    // BM25 hyper-parameters (Okapi BM25 standard defaults)
    private val k1 = 1.5f // term-frequency saturation
    private val b = 0.75f // length normalization strength

    private data class IndexedChunk(
        val text: String,
        val source: String?,
        val termFreq: Map<String, Int>,
        val length: Int,
    )

    private data class BM25Index(val chunks: List<IndexedChunk>, val idf: Map<String, Float>, val avgdl: Float)

    /**
     * The index is computed once on the first [retrieve] call.
     * Zero memory overhead until RAG is actually used.
     */
    private val index: BM25Index by lazy { buildIndex() }

    private fun buildIndex(): BM25Index {
        val indexed = rawChunks.mapIndexed { i, text ->
            val terms = tokenize(text)
            IndexedChunk(
                text = text,
                source = sources.getOrNull(i),
                termFreq = terms.groupingBy { it }.eachCount(),
                length = terms.size,
            )
        }

        val avgdl = if (indexed.isEmpty()) {
            1f
        } else {
            indexed.sumOf { it.length }.toFloat() / indexed.size
        }

        val df = mutableMapOf<String, Int>()
        for (chunk in indexed) {
            for (term in chunk.termFreq.keys) {
                df[term] = (df[term] ?: 0) + 1
            }
        }

        val n = indexed.size
        val idf = df.mapValues { (_, docFreq) ->
            ln((n - docFreq + 0.5f) / (docFreq + 0.5f) + 1f)
        }

        return BM25Index(indexed, idf, avgdl)
    }

    override fun retrieve(query: String, topK: Int): List<RagChunk> {
        val queryTerms = tokenize(query)
        val idx = index // triggers lazy build on first call

        if (queryTerms.isEmpty() || idx.chunks.isEmpty()) return emptyList()

        return idx.chunks
            .map { chunk ->
                var score = 0f
                for (term in queryTerms) {
                    val termIdf = idx.idf[term] ?: 0f
                    val tf = (chunk.termFreq[term] ?: 0).toFloat()
                    val dl = chunk.length.toFloat()
                    score += termIdf * tf * (k1 + 1f) / (tf + k1 * (1f - b + b * dl / idx.avgdl))
                }
                Pair(chunk, score)
            }
            .filter { it.second > 0f }
            .sortedByDescending { it.second }
            .take(topK)
            .map { (chunk, score) -> RagChunk(chunk.text, chunk.source, score) }
    }

    private fun tokenize(text: String): List<String> = text.lowercase()
        .split(Regex("[^a-z0-9]+"))
        .filter { it.length > 2 }

    companion object {
        fun fromTexts(texts: List<String>, sources: List<String?> = emptyList()): BM25RagStore =
            BM25RagStore(texts, sources)
    }
}
