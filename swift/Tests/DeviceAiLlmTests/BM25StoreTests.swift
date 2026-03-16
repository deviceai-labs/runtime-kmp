import XCTest
@testable import DeviceAiLlm

final class BM25StoreTests: XCTestCase {

    func test_emptyCorpusReturnsNoResults() {
        let store = BM25Store(texts: [])
        let results = store.retrieve(query: "hello", topK: 5)
        XCTAssertTrue(results.isEmpty)
    }

    func test_searchReturnsRelevantChunk() {
        let store = BM25Store(texts: [
            "The quick brown fox jumps over the lazy dog",
            "Pack my box with five dozen liquor jugs",
        ])
        let results = store.retrieve(query: "fox dog", topK: 2)
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.text, "The quick brown fox jumps over the lazy dog")
    }

    func test_topKLimitsResults() {
        let texts = (0..<10).map { "chunk number \($0) about topic alpha" }
        let store = BM25Store(texts: texts)
        let results = store.retrieve(query: "topic alpha", topK: 3)
        XCTAssertLessThanOrEqual(results.count, 3)
    }

    func test_scoresArePositive() {
        let store = BM25Store(texts: ["swift concurrency actors", "async await task group"])
        let results = store.retrieve(query: "swift actors", topK: 5)
        for result in results {
            XCTAssertGreaterThan(result.score, 0)
        }
    }

    func test_sourceIsPreserved() {
        let store = BM25Store(
            texts:   ["sample text for retrieval"],
            sources: ["doc://source/1"]
        )
        let results = store.retrieve(query: "sample retrieval", topK: 1)
        XCTAssertEqual(results.first?.source, "doc://source/1")
    }
}
