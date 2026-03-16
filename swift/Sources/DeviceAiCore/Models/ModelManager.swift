import Foundation

/// Generic model lifecycle manager: download, cache, delete.
///
/// `SttModelManager`, `TtsModelManager`, and `LlmModelManager` are thin
/// wrappers around this — all download logic lives here, never duplicated.
///
/// ## Kotlin parallel
/// Mirrors the generic `ModelManager<T: ModelInfo>` pattern in kotlin/core.
public final class ModelManager<T: ModelInfo>: Sendable {

    private let storage:      any ModelStorage
    private let metadataStore: ModelMetadataStore
    private let downloader:   any Downloading

    public init(
        storage:    any ModelStorage   = FileSystemStorage.shared,
        downloader: any Downloading    = URLSessionDownloader.shared
    ) {
        self.storage       = storage
        self.metadataStore = ModelMetadataStore(storage: storage)
        self.downloader    = downloader
    }

    // ── Public API ────────────────────────────────────────────────────────────

    public func isDownloaded(_ model: T) async -> Bool {
        await metadataStore.isDownloaded(id: model.id, at: localPath(for: model))
    }

    /// Absolute path where the model file will live once downloaded.
    public func localPath(for model: T) -> URL {
        storage.modelDirectory.appendingPathComponent(model.filename)
    }

    /// Download `model` if not already cached. Returns a progress stream.
    /// Calling this on an already-downloaded model immediately completes the stream.
    @discardableResult
    public func download(_ model: T) -> AsyncThrowingStream<DownloadProgress, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    if await self.isDownloaded(model) {
                        continuation.finish(); return
                    }
                    let dest = self.localPath(for: model)
                    let temp = self.storage.tempDirectory.appendingPathComponent(model.filename)

                    for try await progress in self.downloader.download(url: model.downloadURL, to: temp) {
                        continuation.yield(progress)
                    }

                    let fm = FileManager.default
                    if fm.fileExists(atPath: dest.path) { try fm.removeItem(at: dest) }
                    try fm.moveItem(at: temp, to: dest)

                    await self.metadataStore.markDownloaded(
                        id: model.id, path: dest, sizeBytes: model.sizeBytes)
                    DeviceAiLogger.info("ModelManager",
                        "Downloaded \(model.displayName) → \(dest.lastPathComponent)")
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Delete the model file and remove it from the metadata index.
    public func delete(_ model: T) async throws {
        let path = localPath(for: model)
        if FileManager.default.fileExists(atPath: path.path) {
            do { try FileManager.default.removeItem(at: path) }
            catch { throw DeviceAiError.ioFailed(reason: error.localizedDescription) }
        }
        await metadataStore.remove(id: model.id)
        DeviceAiLogger.info("ModelManager", "Deleted \(model.displayName)")
    }
}
