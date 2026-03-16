import Foundation

/// A progress snapshot for an in-flight model download.
public struct DownloadProgress: Sendable {
    public let bytesWritten: Int64
    /// `nil` when the server did not send Content-Length.
    public let totalBytes: Int64?

    /// 0.0–1.0. `nil` when total is unknown.
    public var fraction: Double? {
        guard let total = totalBytes, total > 0 else { return nil }
        return Double(bytesWritten) / Double(total)
    }

    public var description: String {
        let w = ByteCountFormatter.string(fromByteCount: bytesWritten, countStyle: .file)
        guard let total = totalBytes else { return w }
        return "\(w) / \(ByteCountFormatter.string(fromByteCount: total, countStyle: .file))"
    }
}
