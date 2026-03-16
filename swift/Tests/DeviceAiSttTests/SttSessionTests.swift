import XCTest
@testable import DeviceAiCore
@testable import DeviceAiStt

final class SttSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DeviceAI.reset()
        DeviceAI.configure()
    }

    // MARK: - Session factory

    func test_sessionCreatesSuccessfully() async throws {
        let session = try DeviceAI.stt.session(modelPath: "/fake/ggml-tiny.bin")
        let closed = await session.isClosed
        XCTAssertFalse(closed)
    }

    func test_sessionThrowsWhenNotConfigured() {
        DeviceAI.reset()
        XCTAssertThrowsError(
            try DeviceAI.stt.session(modelPath: "/fake/ggml-tiny.bin")
        ) { error in
            XCTAssertEqual(error as? DeviceAiError, .notInitialised)
        }
    }

    // MARK: - Transcription (stub returns empty result)

    func test_transcribeSamplesReturnsResult() async throws {
        let session = try DeviceAI.stt.session(modelPath: "/fake/ggml-tiny.bin")
        let result = try await session.transcribe(samples: Array(repeating: 0, count: 1_600))
        XCTAssertNotNil(result)
    }

    func test_transcribeStreamCompletesWithoutError() async throws {
        let session = try DeviceAI.stt.session(modelPath: "/fake/ggml-tiny.bin")
        var tokens: [String] = []
        for try await token in await session.transcribeStream(samples: [0.0, 0.1, 0.2]) {
            tokens.append(token)
        }
        XCTAssertTrue(tokens.isEmpty) // stub emits nothing — finishes cleanly
    }

    // MARK: - Lifecycle

    func test_closeIsIdempotent() async throws {
        let session = try DeviceAI.stt.session(modelPath: "/fake/ggml-tiny.bin")
        await session.close()
        await session.close() // must not crash
        let closed = await session.isClosed
        XCTAssertTrue(closed)
    }

    func test_transcribeThrowsAfterClose() async throws {
        let session = try DeviceAI.stt.session(modelPath: "/fake/ggml-tiny.bin")
        await session.close()
        do {
            _ = try await session.transcribe(samples: [0.0])
            XCTFail("Expected DeviceAiError.sessionClosed")
        } catch DeviceAiError.sessionClosed {
            // pass
        }
    }

    func test_streamThrowsSessionClosedAfterClose() async throws {
        let session = try DeviceAI.stt.session(modelPath: "/fake/ggml-tiny.bin")
        await session.close()
        do {
            for try await _ in await session.transcribeStream(samples: [0.0]) {}
            XCTFail("Expected DeviceAiError.sessionClosed")
        } catch DeviceAiError.sessionClosed {
            // pass
        }
    }
}
