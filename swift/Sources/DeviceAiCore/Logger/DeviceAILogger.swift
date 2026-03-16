import os.log

/// OSLog-backed logger for the DeviceAI SDK.
///
/// All logs are filterable in Console.app and Xcode's log stream:
///   Subsystem: dev.deviceai   Category: <module name>
///
/// ## Kotlin parallel
///
/// Mirrors `CoreSDKLogger` in kotlin/core.
/// Android uses `android.util.Log` with tag-based filtering.
/// OSLog is Apple's equivalent — subsystem + category replaces tag.
///
/// ## Usage
///
/// ```swift
/// DeviceAiLogger.debug("LlamaEngine", "Model loaded in \(ms)ms")
/// DeviceAiLogger.error("WhisperEngine", "Init failed: \(reason)")
/// ```
public enum DeviceAiLogger {

    private static let subsystem = "dev.deviceai"

    public static func debug(_ category: String, _ message: String) {
        Logger(subsystem: subsystem, category: category).debug("\(message, privacy: .public)")
    }

    public static func info(_ category: String, _ message: String) {
        Logger(subsystem: subsystem, category: category).info("\(message, privacy: .public)")
    }

    public static func warning(_ category: String, _ message: String) {
        Logger(subsystem: subsystem, category: category).warning("\(message, privacy: .public)")
    }

    public static func error(_ category: String, _ message: String) {
        Logger(subsystem: subsystem, category: category).error("\(message, privacy: .public)")
    }
}
