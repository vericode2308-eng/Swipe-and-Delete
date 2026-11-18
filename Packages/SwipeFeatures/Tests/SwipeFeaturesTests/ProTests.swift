import Foundation
import Testing
import SwipeCore
@testable import SwipeFeatures

@MainActor
struct ProTests {
    struct Boom: Error {}
    let album = Album(id: "a", title: "Shots", count: 6, kind: .smart)

    func make(_ store: FakePurchases, used: Int = 0, marks: Int = 3, debugPro: Bool = false) async -> (AppModel, FakePhotoLibrary) {
        let d = UserDefaults(suiteName: "t.\(UUID().uuidString)")!
        if used > 0 { var a = DeletionAllowance(); a.record(used, now: Date()); AllowanceStore(defaults: d).save(a) }
        let ids = (1...6).map(String.init)
        let lib = FakePhotoLibrary(status: .full, albums: [album])
        lib.setAssets(ids.map { Asset(id: $0) }, in: album)
        let m = AppModel(library: lib, purchases: store, debugPro: debugPro, allowanceStore: AllowanceStore(defaults: d),
                         promptStore: ReviewPromptStore(defaults: d), openSettings: {})
        await m.startStore()
        await m.open(album)
        for (i, _) in ids.enumerated() { i < marks ? m.session!.delete() : m.session!.keep() }
        m.beginReview()
        return (m, lib)
    }

    @Test func withinAllowanceNeverShowsPaywall() async {
        let (m, lib) = await make(FakePurchases())
        await m.confirmDelete()
        #expect(!m.showsPaywall && lib.deleteRequests.count == 1)
    }
    @Test func overTheAllowanceOpensPaywallNotThePrompt() async {
        let (m, lib) = await make(FakePurchases(), used: 48)
        await m.confirmDelete()
        #expect(m.showsPaywall && lib.deleteRequests.isEmpty && m.proPrice == "$4.99")
    }
    @Test func purchaseSuccessUnlocksAndClosesPaywall() async {
        let (m, _) = await make(FakePurchases(), used: 48)
        await m.confirmDelete(); await m.unlockPro()
        #expect(m.isPro && !m.showsPaywall)
        #expect(m.deletableCount(marked: 3) == 3)
    }
    @Test func cancelPendingAndFailedKeepFreeAndExplain() async {
        for (outcome, text) in [(PurchaseOutcome.cancelled, nil), (.pending, "waiting"), (.failed, "didn't go through")] as [(PurchaseOutcome, String?)] {
            let store = FakePurchases(); store.setNextPurchase(outcome)
            let (m, _) = await make(store, used: 48)
            await m.confirmDelete(); await m.unlockPro()
            #expect(!m.isPro && m.showsPaywall)
            if let text { #expect(m.purchaseMessage?.contains(text) == true) } else { #expect(m.purchaseMessage == nil) }
        }
    }
    @Test func priceFailureDisablesPurchaseAndShowsNoPrice() async {
        let store = FakePurchases(price: .failure(Boom()))
        let (m, _) = await make(store, used: 48)
        await m.unlockPro()
        #expect(m.proPrice == nil && m.priceFailed && store.purchaseCount == 0)
    }
    @Test func restoreFindsOrNot() async {
        let store = FakePurchases()
        let (m, _) = await make(store)
        await m.restorePurchases()
        #expect(!m.isPro && m.purchaseMessage?.contains("No earlier") == true)
        store.setRestore(.success(true))
        await m.restorePurchases()
        #expect(m.isPro)
        store.setRestore(.failure(Boom()))
        let (m2, _) = await make(store.self === store ? FakePurchases() : store)
        let failing = FakePurchases(); failing.setRestore(.failure(Boom()))
        let (m3, _) = await make(failing)
        await m3.restorePurchases()
        #expect(!m3.isPro && m3.purchaseMessage?.contains("Couldn't reach") == true)
        _ = m2
    }
    @Test func proStartsPaidAndSkipsPaywall() async {
        let (m, lib) = await make(FakePurchases(isPro: true), used: 50)
        await m.confirmDelete()
        #expect(!m.showsPaywall && lib.deleteRequests.count == 1)
    }
    @Test func debugProFlag() async {
        let (m, _) = await make(FakePurchases(), debugPro: true)
        #expect(m.isPro)
    }
}
