import Foundation

/// Contract for downloading a remote file to a local URL.
///
/// Inject a mock in tests — no network required.
public protocol Downloading: Sendable {
    func download(url: URL, to destination: URL) -> AsyncThrowingStream<DownloadProgress, Error>
}
