import Foundation

/// When to ask for an App Store rating: after a successful delete on the
/// third completed album, on at least the second distinct day, shown after
/// the user taps Back to Albums. Never after an error, a purchase or on
/// first run; at most once per 120 days.
public struct ReviewPromptPolicy: Equatable, Sendable {
    public enum Event: Sendable { case deleteSucceeded, deleteFailed, purchased, launched }

    public static let albumsNeeded = 3
    public static let daysNeeded = 2
    public static let cooldownDays = 120

    private(set) var completedAlbums = 0
    private(set) var distinctDays = 0
    private(set) var lastDay: Date?
    private(set) var lastPrompt: Date?

    public init() {}
    init(completedAlbums: Int, distinctDays: Int, lastDay: Date?, lastPrompt: Date?) {
        self.completedAlbums = completedAlbums
        self.distinctDays = distinctDays
        self.lastDay = lastDay
        self.lastPrompt = lastPrompt
    }

    /// Call once an album ends with a confirmed deletion.
    public mutating func recordCompletedAlbum(now: Date, calendar: Calendar = .current) {
        completedAlbums += 1
        if let lastDay, calendar.isDate(lastDay, inSameDayAs: now) { return }
        lastDay = calendar.startOfDay(for: now)
        distinctDays += 1
    }

    public func shouldPrompt(after event: Event, now: Date, calendar: Calendar = .current) -> Bool {
        guard event == .deleteSucceeded else { return false }
        guard completedAlbums >= Self.albumsNeeded, distinctDays >= Self.daysNeeded else { return false }
        if let lastPrompt {
            let days = calendar.dateComponents([.day], from: lastPrompt, to: now).day ?? 0
            if days < Self.cooldownDays { return false }
        }
        return true
    }

    public mutating func markPrompted(now: Date) { lastPrompt = now }
}

/// UserDefaults keys `review.*` — never rename without a migration.
public struct ReviewPromptStore: Sendable {
    nonisolated(unsafe) private let defaults: UserDefaults
    public init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    public func load() -> ReviewPromptPolicy {
        ReviewPromptPolicy(completedAlbums: defaults.integer(forKey: "review.albums"),
                           distinctDays: defaults.integer(forKey: "review.days"),
                           lastDay: defaults.object(forKey: "review.lastDay") as? Date,
                           lastPrompt: defaults.object(forKey: "review.lastPrompt") as? Date)
    }

    public func save(_ p: ReviewPromptPolicy) {
        defaults.set(p.completedAlbums, forKey: "review.albums")
        defaults.set(p.distinctDays, forKey: "review.days")
        defaults.set(p.lastDay, forKey: "review.lastDay")
        defaults.set(p.lastPrompt, forKey: "review.lastPrompt")
    }
}
