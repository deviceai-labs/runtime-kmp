import XCTest
@testable import DeviceAiCore
@testable import DeviceAiLlm

final class ChatSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DeviceAI.reset()
        DeviceAI.configure()
    }

    // MARK: - Session creation

    func test_sessionCreatesSuccessfully() async {
        let session = DeviceAI.llm.chat(modelPath: "/fake/model.gguf")
        let closed = await session.isClosed
        XCTAssertFalse(closed)
    }

    // MARK: - History

    func test_turnsEmptyOnCreation() async {
        let session = DeviceAI.llm.chat(modelPath: "/fake/model.gguf")
        let turns = await session.turns
        XCTAssertTrue(turns.isEmpty)
    }

    func test_sendAddsUserAndAssistantTurns() async throws {
        let session = DeviceAI.llm.chat(modelPath: "/fake/model.gguf")
        // Drain the stream (stub returns empty result immediately)
        for try await _ in await session.send("Hello") {}
        let turns = await session.turns
        XCTAssertEqual(turns.count, 2)
        XCTAssertEqual(turns.first?.role, .user)
        XCTAssertEqual(turns.last?.role,  .assistant)
    }

    func test_clearHistoryEmptiesTurns() async throws {
        let session = DeviceAI.llm.chat(modelPath: "/fake/model.gguf")
        for try await _ in await session.send("Hello") {}
        await session.clearHistory()
        let turns = await session.turns
        XCTAssertTrue(turns.isEmpty)
    }

    // MARK: - Lifecycle

    func test_closeIsIdempotent() async {
        let session = DeviceAI.llm.chat(modelPath: "/fake/model.gguf")
        await session.close()
        await session.close() // must not crash
        let closed = await session.isClosed
        XCTAssertTrue(closed)
    }

    func test_sendThrowsAfterClose() async throws {
        let session = DeviceAI.llm.chat(modelPath: "/fake/model.gguf")
        await session.close()
        do {
            for try await _ in await session.send("Hello") {}
            XCTFail("Expected DeviceAiError.sessionClosed")
        } catch DeviceAiError.sessionClosed {
            // pass
        }
    }
}
