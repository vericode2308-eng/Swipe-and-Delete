import Foundation

/// Free plan: 50 deletions per local calendar day (R-11).
/// Count only what iOS confirmed deleted.
public struct DeletionAllowance: Equatable, Sendable {
    public static let dailyFree = 50

    private(set) var day: Date?     // start of the local day the count belongs to
    private(set) var count: Int

    public init() { day = nil; count = 0 }
    init(day: Date?, count: Int) { self.day = day; self.count = max(0, count) }

    public func remaining(now: Date, calendar: Calendar = .current) -> Int {
        guard let day, calendar.isDate(day, inSameDayAs: now) else { return Self.dailyFree }
        return max(0, Self.dailyFree - count)
    }

    public mutating func record(_ deleted: Int, now: Date, calendar: Calendar = .current) {
        guard deleted > 0 else { return }
        if let day, calendar.isDate(day, inSameDayAs: now) {
            count += deleted
        } else {
            day = calendar.startOfDay(for: now)
            count = deleted
        }
    }
}

/// UserDefaults keys `allowance.date` and `allowance.count` — never rename
/// without a migration.
public struct AllowanceStore: Sendable {
    nonisolated(unsafe) private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() -> DeletionAllowance {
        DeletionAllowance(day: defaults.object(forKey: "allowance.date") as? Date,
                          count: defaults.integer(forKey: "allowance.count"))
    }

    public func save(_ allowance: DeletionAllowance) {
        defaults.set(allowance.day, forKey: "allowance.date")
        defaults.set(allowance.count, forKey: "allowance.count")
    }
}
