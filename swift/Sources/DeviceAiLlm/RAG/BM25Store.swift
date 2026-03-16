import Foundation

/// BM25 keyword retrieval. Mirrors `BM25RagStore` in kotlin/llm — same algorithm, same defaults.
///
/// k1 = 1.5 (term frequency saturation), b = 0.75 (length normalisation).
/// These are the Elasticsearch / Lucene standard defaults.
/// Lazy index: zero overhead until first `retrieve()` call.
public final class BM25Store: Retrieving, @unchecked Sendable {

    private let k1: Float = 1.5
    private let b:  Float = 0.75
    private let rawChunks: [(text: String, source: String?)]
    private var index: Index?
    private let lock = NSLock()

    public init(texts: [String], sources: [String?]? = nil) {
        rawChunks = texts.enumerated().map { i, t in (t, sources?[safe: i] ?? nil) }
    }

    public func retrieve(query: String, topK: Int) -> [RagChunk] {
        let idx   = buildIndex()
        let terms = tokenize(query)
        guard !terms.isEmpty else { return [] }

        return idx.termFrequencies.indices
            .map { i -> (Int, Float) in
                let score = terms.reduce(0 as Float) { $0 + bm25(term: $1, doc: i, idx: idx) }
                return (i, score)
            }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .prefix(topK)
            .map { i, score in RagChunk(text: rawChunks[i].text, source: rawChunks[i].source, score: score) }
    }

    private func bm25(term: String, doc: Int, idx: Index) -> Float {
        guard let df = idx.df[term], let tf = idx.termFrequencies[doc][term] else { return 0 }
        let n   = Float(idx.termFrequencies.count)
        let idf = log((n - Float(df) + 0.5) / (Float(df) + 0.5) + 1)
        let len = Float(idx.lengths[doc])
        let tfn = (Float(tf) * (k1 + 1)) / (Float(tf) + k1 * (1 - b + b * len / idx.avgLen))
        return idf * tfn
    }

    private func buildIndex() -> Index {
        lock.lock(); defer { lock.unlock() }
        if let i = index { return i }
        let docs = rawChunks.map { tokenize($0.text) }
        var df: [String: Int] = [:]
        let tfs: [[String: Int]] = docs.map { tokens in
            var tf: [String: Int] = [:]
            tokens.forEach { tf[$0, default: 0] += 1 }
            Set(tokens).forEach { df[$0, default: 0] += 1 }
            return tf
        }
        let lengths = docs.map { $0.count }
        let avg = lengths.isEmpty ? 1.0 : Float(lengths.reduce(0, +)) / Float(lengths.count)
        let built = Index(termFrequencies: tfs, df: df, lengths: lengths, avgLen: avg)
        index = built; return built
    }

    private func tokenize(_ text: String) -> [String] {
        text.lowercased().components(separatedBy: .alphanumerics.inverted).filter { $0.count > 1 }
    }

    private struct Index {
        let termFrequencies: [[String: Int]]
        let df: [String: Int]
        let lengths: [Int]
        let avgLen: Float
    }
}

private extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}
