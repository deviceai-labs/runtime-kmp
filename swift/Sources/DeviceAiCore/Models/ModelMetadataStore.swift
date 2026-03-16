import Foundation

/// Persists downloaded model records to a JSON index file.
///
/// `actor` — Swift's built-in concurrency primitive for protecting mutable state.
/// Only one task accesses the store at a time; no locks needed.
///
/// ## Kotlin parallel
/// Mirrors `MetadataStore` in kotlin/core — injectable, JSON-backed, same contract.
public actor ModelMetadataStore {

    private let fileURL: URL
    private var cache: [String: Entry] = [:]
    private var loaded = false

    public init(storage: any ModelStorage) {
        fileURL = storage.modelDirectory.appendingPathComponent("metadata.json")
    }

    public func isDownloaded(id: String, at path: URL) -> Bool {
        loadIfNeeded()
        guard cache[id] != nil else { return false }
        return FileManager.default.fileExists(atPath: path.path)
    }

    public func markDownloaded(id: String, path: URL, sizeBytes: Int64) {
        loadIfNeeded()
        cache[id] = Entry(id: id, localPath: path.path, sizeBytes: sizeBytes, downloadedAt: Date())
        persist()
    }

    public func remove(id: String) {
        loadIfNeeded()
        cache.removeValue(forKey: id)
        persist()
    }

    public func allDownloadedIds() -> [String] {
        loadIfNeeded()
        return Array(cache.keys)
    }

    // ── Private ───────────────────────────────────────────────────────────────

    private func loadIfNeeded() {
        guard !loaded else { return }
        loaded = true
        guard let data = try? Data(contentsOf: fileURL) else { return }
        let entries = (try? JSONDecoder().decode([Entry].self, from: data)) ?? []
        cache = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(Array(cache.values)) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    private struct Entry: Codable {
        let id: String
        let localPath: String
        let sizeBytes: Int64
        let downloadedAt: Date
    }
}
