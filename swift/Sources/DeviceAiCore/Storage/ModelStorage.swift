import Foundation

/// Defines where the SDK reads and writes model files.
///
/// Conform to this to control storage location — useful for App Groups (widget extensions),
/// custom sandboxes, or test mocks.
///
/// ## Kotlin parallel
/// Mirrors the `StoragePaths` interface in kotlin/core.
public protocol ModelStorage: Sendable {
    /// Directory where downloaded models are stored permanently.
    var modelDirectory: URL { get }
    /// Directory for in-progress downloads. Cleared on cancellation or failure.
    var tempDirectory: URL { get }
}
