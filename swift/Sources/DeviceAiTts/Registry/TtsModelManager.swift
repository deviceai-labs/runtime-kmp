import Foundation
import DeviceAiCore

/// Typed wrapper around `ModelManager` for Piper/Kokoro voices.
/// Mirrors `SpeechBridge.modelManager` / `ModelRegistry` in kotlin/speech.
///
/// ```swift
/// let manager = DeviceAI.tts.modelManager
/// let stream  = manager.download(PiperCatalog.enUSAmy)
/// for try await progress in stream {
///     print(progress.fractionCompleted)
/// }
/// let path = manager.localPath(for: PiperCatalog.enUSAmy)
/// ```
public final class TtsModelManager: Sendable {

    static let shared = TtsModelManager()
    private let manager: ModelManager<PiperModelInfo>
    private init() { manager = ModelManager<PiperModelInfo>() }

    // MARK: - Query

    /// `true` if `model` is fully downloaded and on disk.
    public func isDownloaded(_ model: PiperModelInfo) async -> Bool {
        await manager.isDownloaded(model)
    }

    /// Local URL of the cached model file. File may not yet exist if not downloaded.
    public func localPath(for model: PiperModelInfo) -> URL {
        manager.localPath(for: model)
    }

    // MARK: - Download / delete

    /// Stream download progress. Completes when the file is fully cached.
    public func download(
        _ model: PiperModelInfo
    ) -> AsyncThrowingStream<DownloadProgress, Error> {
        manager.download(model)
    }

    /// Remove the cached model from disk.
    public func delete(_ model: PiperModelInfo) async throws {
        try await manager.delete(model)
    }
}
