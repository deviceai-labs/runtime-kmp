import XCTest
@testable import DeviceAiCore

final class SDKVersionTests: XCTestCase {

    func test_coreVersionIsNotZero() {
        XCTAssertGreaterThan(SDKVersion.core, SDKVersion(0, 0, 0))
    }

    func test_comparison() {
        XCTAssertLessThan(SDKVersion(1, 0, 0), SDKVersion(2, 0, 0))
        XCTAssertLessThan(SDKVersion(1, 2, 0), SDKVersion(1, 3, 0))
        XCTAssertLessThan(SDKVersion(1, 2, 3), SDKVersion(1, 2, 4))
        XCTAssertEqual(SDKVersion(1, 2, 3), SDKVersion(1, 2, 3))
    }

    func test_description() {
        XCTAssertEqual(SDKVersion(1, 2, 3).description, "1.2.3")
    }
}
