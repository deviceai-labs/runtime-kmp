import Foundation

/// Unified error taxonomy for the DeviceAI SDK.
///
/// Every `async throws` function in this SDK throws `DeviceAiError`.
/// One error type, one catch block, associated values carry the reason.
///
/// ## Kotlin parity
///
/// | Swift                          | Kotlin                    |
/// |-------------------------------|---------------------------|
/// | `.modelNotFound(path:)`        | `modelNotFound`           |
/// | `.modelLoadFailed(reason:)`    | `initFailed`              |
/// | `.tokenizationFailed(reason:)` | —                         |
/// | `.inferenceFailed(reason:)`    | `inferenceFailed`         |
/// | `.cancelled`                   | `downloadCancelled`       |
/// | `.ioFailed(reason:)`           | —                         |
/// | `.downloadFailed(reason:)`     | `downloadFailed`          |
/// | `.microphonePermissionDenied`  | —                         |
/// | `.sessionClosed`               | —                         |
/// | `.versionMismatch`             | —                         |
/// | `.notInitialised`              | implicit                  |
public enum DeviceAiError: Error, LocalizedError, Equatable, Sendable {

    // ── Model lifecycle ───────────────────────────────────────────────────────

    /// No file exists at `path`. Check the path and ensure the model is downloaded.
    case modelNotFound(path: String)

    /// The native engine failed to load the model.
    /// `reason` is the message from the underlying C++ library.
    case modelLoadFailed(reason: String)

    /// Tokenization of the input failed before inference began.
    case tokenizationFailed(reason: String)

    /// Inference failed after the model was loaded successfully.
    case inferenceFailed(reason: String)

    // ── Control flow ──────────────────────────────────────────────────────────

    /// The operation was cancelled by calling `cancel()` or via Swift Task cancellation.
    case cancelled

    /// A method was called on a session after `close()` was called.
    /// All sessions are closed after `close()` — create a new session to continue.
    case sessionClosed

    /// `DeviceAI.configure()` was not called before using a feature module.
    case notInitialised

    // ── I/O ───────────────────────────────────────────────────────────────────

    /// A file system operation failed (read, write, move, delete).
    case ioFailed(reason: String)

    /// A model download failed. `reason` describes the HTTP error or network issue.
    case downloadFailed(reason: String)

    // ── Platform ──────────────────────────────────────────────────────────────

    /// Microphone access was denied. Direct the user to Settings → Privacy → Microphone.
    case microphonePermissionDenied

    // ── ABI compatibility ─────────────────────────────────────────────────────

    /// A feature binary was compiled against a different Core version.
    /// Reinstall the SDK package to ensure all binaries are in sync.
    case versionMismatch(core: SDKVersion, feature: SDKVersion)

    // ── LocalizedError ────────────────────────────────────────────────────────

    public var errorDescription: String? {
        switch self {
        case .modelNotFound(let path):
            return "Model not found at: \(path)"
        case .modelLoadFailed(let reason):
            return "Model load failed: \(reason)"
        case .tokenizationFailed(let reason):
            return "Tokenization failed: \(reason)"
        case .inferenceFailed(let reason):
            return "Inference failed: \(reason)"
        case .cancelled:
            return "Operation cancelled."
        case .sessionClosed:
            return "This session has been closed. Create a new session to continue."
        case .notInitialised:
            return "DeviceAI is not configured. Call DeviceAI.configure() at app startup."
        case .ioFailed(let reason):
            return "I/O error: \(reason)"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .microphonePermissionDenied:
            return "Microphone permission denied. Enable it in Settings → Privacy → Microphone."
        case .versionMismatch(let core, let feature):
            return "Version mismatch: Core \(core) is incompatible with feature binary \(feature). Reinstall the SDK."
        }
    }
}
