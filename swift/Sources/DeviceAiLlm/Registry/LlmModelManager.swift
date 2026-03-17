import Foundation
import DeviceAiCore

/// Downloads, caches, and deletes GGUF model files.
/// Thin wrapper around `ModelManager<LlmModelInfo>` — all logic lives in Core.
///
/// ```swift
/// let manager = LlmModelManager()
/// for try await progress in manager.download(LlmCatalog.llama32_1B) {
///     print(progress.description)
/// }
/// let path = manager.localPath(for: LlmCatalog.llama32_1B)
/// ```
public final class LlmModelManager: Sendable {

    static let shared = LlmModelManager()

    private let inner: ModelManager<LlmModelInfo>

    public init(
        storage:    any ModelStorage   = FileSystemStorage.shared,
        downloader: any Downloading    = URLSessionDownloader.shared
    ) {
        inner = ModelManager(storage: storage, downloader: downloader)
    }

    public func isDownloaded(_ model: LlmModelInfo) async -> Bool  { await inner.isDownloaded(model) }
    public func localPath(for model: LlmModelInfo) -> URL          { inner.localPath(for: model) }

    @discardableResult
    public func download(_ model: LlmModelInfo) -> AsyncThrowingStream<DownloadProgress, Error> {
        inner.download(model)
    }

    public func delete(_ model: LlmModelInfo) async throws { try await inner.delete(model) }
}
