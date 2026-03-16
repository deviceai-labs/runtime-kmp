import Foundation
import DeviceAiCore

/// Typed wrapper around `ModelManager` for Whisper models.
/// Mirrors `SpeechBridge.modelManager` / `ModelRegistry` in kotlin/speech.
///
/// ```swift
/// let manager = DeviceAI.stt.modelManager
/// let stream  = manager.download(WhisperCatalog.small)
/// for try await progress in stream {
///     print(progress.fractionCompleted)
/// }
/// let path = manager.localPath(for: WhisperCatalog.small)
/// ```
public final class SttModelManager: Sendable {

    static let shared = SttModelManager()
    private let manager: ModelManager<WhisperModelInfo>
    private init() { manager = ModelManager<WhisperModelInfo>() }

    // MARK: - Query

    /// `true` if `model` is fully downloaded and on disk.
    public func isDownloaded(_ model: WhisperModelInfo) async -> Bool {
        await manager.isDownloaded(model)
    }

    /// Local URL of the cached model file. File may not yet exist if not downloaded.
    public func localPath(for model: WhisperModelInfo) -> URL {
        manager.localPath(for: model)
    }

    // MARK: - Download / delete

    /// Stream download progress. Completes when the file is fully cached.
    public func download(
        _ model: WhisperModelInfo
    ) -> AsyncThrowingStream<DownloadProgress, Error> {
        manager.download(model)
    }

    /// Remove the cached model from disk.
    public func delete(_ model: WhisperModelInfo) async throws {
        try await manager.delete(model)
    }
}
