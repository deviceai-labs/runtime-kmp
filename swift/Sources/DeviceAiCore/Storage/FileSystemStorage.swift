import Foundation

/// Default `ModelStorage` — writes to `<Documents>/DeviceAI/`.
///
/// Models are excluded from iCloud backup (large files, re-downloadable).
public struct FileSystemStorage: ModelStorage {

    public static let shared = FileSystemStorage()
    private init() {}

    public var modelDirectory: URL { root.appendingPathComponent("models", isDirectory: true) }
    public var tempDirectory:  URL { root.appendingPathComponent("tmp",    isDirectory: true) }

    private var root: URL {
        let dir = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeviceAI", isDirectory: true)
        [dir, dir.appendingPathComponent("models"), dir.appendingPathComponent("tmp")]
            .forEach(createExcludingBackup)
        return dir
    }

    private func createExcludingBackup(_ url: URL) {
        guard !FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            var u = url; try u.setResourceValues(values)
        } catch {
            DeviceAiLogger.error("FileSystemStorage", "Failed to create \(url.lastPathComponent): \(error)")
        }
    }
}
