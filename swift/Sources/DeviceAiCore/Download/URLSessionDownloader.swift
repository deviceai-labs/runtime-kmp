import Foundation

/// URLSession-backed downloader. Moves the completed file to `destination`.
public final class URLSessionDownloader: Downloading, @unchecked Sendable {

    public static let shared = URLSessionDownloader()
    private let session: URLSession

    public init(session: URLSession = .shared) { self.session = session }

    public func download(url: URL, to destination: URL) -> AsyncThrowingStream<DownloadProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let (tempURL, response) = try await session.download(from: url)

                    guard let http = response as? HTTPURLResponse,
                          (200...299).contains(http.statusCode) else {
                        let code = (response as? HTTPURLResponse)?.statusCode ?? 0
                        throw DeviceAiError.downloadFailed(reason: "HTTP \(code)")
                    }

                    let fileSize = (try? FileManager.default
                        .attributesOfItem(atPath: tempURL.path)[.size] as? Int64) ?? 0
                    continuation.yield(DownloadProgress(bytesWritten: fileSize, totalBytes: fileSize))

                    let fm = FileManager.default
                    if fm.fileExists(atPath: destination.path) {
                        try fm.removeItem(at: destination)
                    }
                    try fm.moveItem(at: tempURL, to: destination)
                    continuation.finish()

                } catch let e as DeviceAiError {
                    continuation.finish(throwing: e)
                } catch is CancellationError {
                    continuation.finish(throwing: DeviceAiError.cancelled)
                } catch {
                    continuation.finish(throwing: DeviceAiError.downloadFailed(reason: error.localizedDescription))
                }
            }
        }
    }
}
