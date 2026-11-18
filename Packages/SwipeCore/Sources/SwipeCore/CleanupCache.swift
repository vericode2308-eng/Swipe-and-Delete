import Foundation

/// Analysis results kept in Application Support (`cleanup-v1.bin`) so the scan
/// does not repeat on every launch (D-21). Holds no swipe progress (D-02).
public struct CleanupCacheStore: Sendable {
    public let url: URL
    public init(url: URL) { self.url = url }

    public static func standard() -> CleanupCacheStore {
        let base = (try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask,
                                                 appropriateFor: nil, create: true))
            ?? FileManager.default.temporaryDirectory
        return CleanupCacheStore(url: base.appendingPathComponent("cleanup-v1.bin"))
    }

    /// Empty when there is no file. A file that cannot be read is deleted.
    public func load() -> [String: PhotoTraits] {
        guard let data = try? Data(contentsOf: url) else { return [:] }
        guard let list = try? PropertyListDecoder().decode([PhotoTraits].self, from: data) else {
            try? FileManager.default.removeItem(at: url)
            return [:]
        }
        return Dictionary(list.map { ($0.id, $0) }, uniquingKeysWith: { _, new in new })
    }

    public func save(_ entries: [String: PhotoTraits]) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        guard let data = try? encoder.encode(Array(entries.values)) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        #if os(iOS)
        let options: Data.WritingOptions = [.atomic, .completeFileProtection]
        #else
        let options: Data.WritingOptions = [.atomic]
        #endif
        try? data.write(to: url, options: options)
    }
}
