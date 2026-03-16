import XCTest
@testable import DeviceAiCore

final class DeviceAiErrorTests: XCTestCase {

    func test_allCasesHaveNonEmptyDescription() {
        let cases: [DeviceAiError] = [
            .modelNotFound(path: "x"),
            .modelLoadFailed(reason: "x"),
            .tokenizationFailed(reason: "x"),
            .inferenceFailed(reason: "x"),
            .cancelled,
            .sessionClosed,
            .notInitialised,
            .ioFailed(reason: "x"),
            .downloadFailed(reason: "x"),
            .microphonePermissionDenied,
            .versionMismatch(core: SDKVersion(0, 1, 0), feature: SDKVersion(0, 2, 0)),
        ]
        for error in cases {
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true,
                           "\(error) has empty errorDescription")
        }
    }

    func test_equality() {
        XCTAssertEqual(DeviceAiError.cancelled, DeviceAiError.cancelled)
        XCTAssertEqual(DeviceAiError.sessionClosed, DeviceAiError.sessionClosed)
        XCTAssertEqual(DeviceAiError.modelNotFound(path: "a"), DeviceAiError.modelNotFound(path: "a"))
        XCTAssertNotEqual(DeviceAiError.modelNotFound(path: "a"), DeviceAiError.modelNotFound(path: "b"))
    }
}
