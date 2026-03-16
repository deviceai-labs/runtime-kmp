import Foundation

/// Common interface for all downloadable model descriptors.
///
/// `ModelManager<T: ModelInfo>` handles download/cache/delete generically
/// for any conforming type — Whisper models, Piper voices, GGUF files.
///
/// ## Kotlin parallel
/// Mirrors `ModelInfo` in kotlin/core — same fields, same HuggingFace URL pattern.
public protocol ModelInfo: Sendable, Identifiable, Hashable where ID == String {
    var id: String { get }
    var displayName: String { get }
    var sizeBytes: Int64 { get }
    var repoId: String { get }
    var filename: String { get }
}

public extension ModelInfo {
    /// Default HuggingFace download URL — centralised so no module needs to know the pattern.
    var downloadURL: URL {
        URL(string: "https://huggingface.co/\(repoId)/resolve/main/\(filename)")!
    }
}
