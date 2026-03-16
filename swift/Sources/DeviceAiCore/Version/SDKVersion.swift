/// Semantic version for ABI compatibility checks between Core and feature binaries.
///
/// Each XCFramework binary embeds a `minimumCoreVersion` it was compiled against.
/// At session creation time, Core verifies compatibility and throws
/// `DeviceAiError.versionMismatch` before any C++ code is touched.
///
/// This prevents silent crashes from mismatched binary + source combinations —
/// a common pain point with SDK distributions that mix binary and source targets.
public struct SDKVersion: Comparable, CustomStringConvertible, Sendable {

    public let major: Int
    public let minor: Int
    public let patch: Int

    public init(_ major: Int, _ minor: Int, _ patch: Int) {
        self.major = major
        self.minor = minor
        self.patch = patch
    }

    /// The current DeviceAiCore version. Bumped on every release.
    public static let core = SDKVersion(0, 1, 0)

    public var description: String { "\(major).\(minor).\(patch)" }

    public static func < (lhs: SDKVersion, rhs: SDKVersion) -> Bool {
        if lhs.major != rhs.major { return lhs.major < rhs.major }
        if lhs.minor != rhs.minor { return lhs.minor < rhs.minor }
        return lhs.patch < rhs.patch
    }
}
