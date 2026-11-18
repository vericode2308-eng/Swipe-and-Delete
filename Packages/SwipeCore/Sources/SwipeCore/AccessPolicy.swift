import Foundation

/// The only place that decides free vs Pro (R-11, R-13).
public struct AccessPolicy: Sendable {
    public let isPro: Bool
    public let allowance: DeletionAllowance

    public init(isPro: Bool, allowance: DeletionAllowance) {
        self.isPro = isPro
        self.allowance = allowance
    }

    /// How many of the marked photos may be deleted right now.
    public func deletable(marked: Int, now: Date, calendar: Calendar = .current) -> Int {
        isPro ? marked : min(marked, allowance.remaining(now: now, calendar: calendar))
    }

    public func needsPaywall(marked: Int, now: Date, calendar: Calendar = .current) -> Bool {
        !isPro && marked > allowance.remaining(now: now, calendar: calendar)
    }
}
