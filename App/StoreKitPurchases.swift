import StoreKit
import SwipeCore

/// StoreKit 2: one non-consumable product. Entitlements are the only source of Pro.
struct StoreKitPurchases: Purchases {
    static let productID = "com.vericodestudio.lighter.pro"
    struct Unavailable: Error {}

    func product() async throws -> ProProduct {
        guard let p = try await Product.products(for: [Self.productID]).first else { throw Unavailable() }
        return ProProduct(displayPrice: p.displayPrice)
    }

    func purchase() async -> PurchaseOutcome {
        do {
            guard let p = try await Product.products(for: [Self.productID]).first else { return .failed }
            switch try await p.purchase() {
            case .success(let result):
                guard case .verified(let tx) = result else { return .failed }
                await tx.finish()
                return .success
            case .userCancelled: return .cancelled
            case .pending: return .pending
            @unknown default: return .failed
            }
        } catch { return .failed }
    }

    func restore() async throws { try await AppStore.sync() }

    func isPro() async -> Bool {
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == Self.productID, tx.revocationDate == nil { return true }
        }
        return false
    }

    func proChanges() -> AsyncStream<Bool> {
        AsyncStream { cont in
            let task = Task {
                for await update in Transaction.updates {
                    if case .verified(let tx) = update { await tx.finish() }
                    cont.yield(await isPro())
                }
                cont.finish()
            }
            cont.onTermination = { _ in task.cancel() }
        }
    }
}
