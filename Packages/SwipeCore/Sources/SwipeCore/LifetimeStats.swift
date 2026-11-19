import Foundation

/// Running totals shown on Settings (D-24): how much space and how many photos
/// the user has cleared since installing. Only confirmed deletes are counted.
public struct LifetimeStats: Equatable, Sendable {
    public private(set) var freedBytes: Int64
    public private(set) var deleted: Int

    public init() { freedBytes = 0; deleted = 0 }
    init(freedBytes: Int64, deleted: Int) {
        self.freedBytes = max(0, freedBytes)
        self.deleted = max(0, deleted)
    }

    public var isEmpty: Bool { deleted == 0 }

    /// `bytes` is 0 when PhotoKit gave no sizes; the count still grows.
    public mutating func record(deleted count: Int, bytes: Int64) {
        guard count > 0 else { return }
        deleted += count
        freedBytes += max(0, bytes)
    }
}

/// UserDefaults keys `stats.bytes` and `stats.deleted` — never rename without a migration.
public struct LifetimeStatsStore: Sendable {
    nonisolated(unsafe) private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() -> LifetimeStats {
        LifetimeStats(freedBytes: Int64(defaults.integer(forKey: "stats.bytes")),
                      deleted: defaults.integer(forKey: "stats.deleted"))
    }

    public func save(_ stats: LifetimeStats) {
        defaults.set(stats.freedBytes, forKey: "stats.bytes")
        defaults.set(stats.deleted, forKey: "stats.deleted")
    }
}
