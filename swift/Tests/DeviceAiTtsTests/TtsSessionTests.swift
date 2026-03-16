import XCTest
@testable import DeviceAiCore
@testable import DeviceAiTts

final class TtsSessionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        DeviceAI.reset()
        DeviceAI.configure()
    }

    // MARK: - Session factory

    func test_sessionCreatesSuccessfully() async throws {
        let session = try DeviceAI.tts.session(
            modelPath:  "/fake/voice.onnx",
            tokensPath: "/fake/tokens.json"
        )
        let closed = await session.isClosed
        XCTAssertFalse(closed)
    }

    func test_sessionThrowsWhenNotConfigured() {
        DeviceAI.reset()
        XCTAssertThrowsError(
            try DeviceAI.tts.session(modelPath: "/fake/voice.onnx", tokensPath: "/fake/tokens.json")
        ) { error in
            XCTAssertEqual(error as? DeviceAiError, .notInitialised)
        }
    }

    // MARK: - Synthesis (stub returns empty audio)

    func test_synthesizeReturnsAudioSegment() async throws {
        let session = try DeviceAI.tts.session(
            modelPath:  "/fake/voice.onnx",
            tokensPath: "/fake/tokens.json"
        )
        let audio = try await session.synthesize(text: "Hello world")
        XCTAssertEqual(audio.sampleRate, 22_050)
    }

    func test_synthesizeStreamCompletesWithoutError() async throws {
        let session = try DeviceAI.tts.session(
            modelPath:  "/fake/voice.onnx",
            tokensPath: "/fake/tokens.json"
        )
        var segments: [AudioSegment] = []
        for try await segment in await session.synthesizeStream(text: "Hello") {
            segments.append(segment)
        }
        XCTAssertTrue(segments.isEmpty) // stub emits nothing — finishes cleanly
    }

    // MARK: - Lifecycle

    func test_closeIsIdempotent() async throws {
        let session = try DeviceAI.tts.session(
            modelPath:  "/fake/voice.onnx",
            tokensPath: "/fake/tokens.json"
        )
        await session.close()
        await session.close()
        let closed = await session.isClosed
        XCTAssertTrue(closed)
    }

    func test_synthesizeThrowsAfterClose() async throws {
        let session = try DeviceAI.tts.session(
            modelPath:  "/fake/voice.onnx",
            tokensPath: "/fake/tokens.json"
        )
        await session.close()
        do {
            _ = try await session.synthesize(text: "Hello")
            XCTFail("Expected DeviceAiError.sessionClosed")
        } catch DeviceAiError.sessionClosed {
            // pass
        }
    }

    func test_streamThrowsSessionClosedAfterClose() async throws {
        let session = try DeviceAI.tts.session(
            modelPath:  "/fake/voice.onnx",
            tokensPath: "/fake/tokens.json"
        )
        await session.close()
        do {
            for try await _ in await session.synthesizeStream(text: "Hello") {}
            XCTFail("Expected DeviceAiError.sessionClosed")
        } catch DeviceAiError.sessionClosed {
            // pass
        }
    }
}
