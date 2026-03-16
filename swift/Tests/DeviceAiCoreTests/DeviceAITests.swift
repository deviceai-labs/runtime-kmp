import XCTest
@testable import DeviceAiCore

final class DeviceAITests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Reset SDK state between tests (white-box via internal setter).
        DeviceAI.reset()
    }

    // MARK: - configure()

    func test_configure_setsIsConfigured() {
        XCTAssertFalse(DeviceAI.isConfigured)
        DeviceAI.configure()
        XCTAssertTrue(DeviceAI.isConfigured)
    }

    func test_configure_defaultEnvironmentIsDevelopment() {
        DeviceAI.configure()
        XCTAssertEqual(DeviceAI.environment, .development)
    }

    func test_configure_productionEnvironment() {
        DeviceAI.configure(environment: .production(apiKey: "test-key"))
        guard case .production(let k) = DeviceAI.environment else {
            return XCTFail("Expected .production")
        }
        XCTAssertEqual(k, "test-key")
    }

    func test_configure_isIdempotent() {
        // Second call must not crash and must keep first value.
        DeviceAI.configure(environment: .production(apiKey: "key-A"))
        DeviceAI.configure(environment: .production(apiKey: "key-B"))
        guard case .production(let k) = DeviceAI.environment else {
            return XCTFail("Expected .production")
        }
        XCTAssertEqual(k, "key-A")
    }

    // MARK: - assertConfigured()

    func test_assertConfigured_throwsWhenNotConfigured() {
        XCTAssertThrowsError(try DeviceAI.assertConfigured()) { error in
            XCTAssertEqual(error as? DeviceAiError, .notInitialised)
        }
    }

    func test_assertConfigured_doesNotThrowWhenConfigured() {
        DeviceAI.configure()
        XCTAssertNoThrow(try DeviceAI.assertConfigured())
    }
}
