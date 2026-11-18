import Foundation

public final class FakePurchases: Purchases, @unchecked Sendable {
    private let lock = NSLock()
    private var pro: Bool
    private var price: Result<ProProduct, Error>
    private var nextPurchase: PurchaseOutcome = .success
    private var restoreResult: Result<Bool, Error> = .success(false)
    private var buys = 0, restores = 0

    public init(isPro: Bool = false, price: Result<ProProduct, Error> = .success(ProProduct(displayPrice: "$4.99"))) {
        self.pro = isPro; self.price = price
    }
    public var purchaseCount: Int { lock.withLock { buys } }
    public var restoreCount: Int { lock.withLock { restores } }
    public func setNextPurchase(_ o: PurchaseOutcome) { lock.withLock { nextPurchase = o } }
    /// `.success(true)` makes the next restore find a purchase.
    public func setRestore(_ r: Result<Bool, Error>) { lock.withLock { restoreResult = r } }

    public func product() async throws -> ProProduct { try lock.withLock { price }.get() }
    public func purchase() async -> PurchaseOutcome {
        lock.withLock { buys += 1; if nextPurchase == .success { pro = true }; return nextPurchase }
    }
    public func restore() async throws {
        let r = lock.withLock { restores += 1; return restoreResult }
        if try r.get() { lock.withLock { pro = true } }
    }
    public func isPro() async -> Bool { lock.withLock { pro } }
    public func proChanges() -> AsyncStream<Bool> { AsyncStream { $0.finish() } }
}
