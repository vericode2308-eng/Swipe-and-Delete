import Foundation

/// The one-time Pro product as the store describes it. The price is the store's own text.
public struct ProProduct: Equatable, Sendable {
    public let displayPrice: String
    public init(displayPrice: String) { self.displayPrice = displayPrice }
}

public enum PurchaseOutcome: Equatable, Sendable {
    case success, cancelled, pending, failed
}

/// StoreKit lives behind this protocol in the app target. Pro status comes only from here.
public protocol Purchases: Sendable {
    /// Display price from the store; throws when it cannot be loaded.
    func product() async throws -> ProProduct
    func purchase() async -> PurchaseOutcome
    /// Asks the store to sync; check `isPro()` afterwards.
    func restore() async throws
    /// True when a verified, unrevoked Pro entitlement exists.
    func isPro() async -> Bool
    /// Emits the new Pro status whenever the store reports a change (approved Ask to Buy, refund).
    func proChanges() -> AsyncStream<Bool>
}
