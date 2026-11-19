import Foundation
import Testing
@testable import SwipeCore

struct LifetimeStatsTests {
    @Test func startsEmpty() {
        let s = LifetimeStats()
        #expect(s.isEmpty && s.freedBytes == 0 && s.deleted == 0)
    }
    @Test func recordAddsUp() {
        var s = LifetimeStats()
        s.record(deleted: 3, bytes: 9_000_000)
        s.record(deleted: 2, bytes: 1_000_000)
        #expect(s.deleted == 5 && s.freedBytes == 10_000_000 && !s.isEmpty)
    }
    @Test func zeroOrNegativeInputsDoNotShrinkTotals() {
        var s = LifetimeStats()
        s.record(deleted: 2, bytes: 500)
        s.record(deleted: 0, bytes: 1_000)
        s.record(deleted: 1, bytes: -5)
        #expect(s.deleted == 3 && s.freedBytes == 500)
    }
    @Test func unknownSizeStillCountsPhotos() {
        var s = LifetimeStats()
        s.record(deleted: 4, bytes: 0)
        #expect(s.deleted == 4 && s.freedBytes == 0)
    }
    @Test func storeRoundTripsAndStartsEmpty() {
        let d = UserDefaults(suiteName: "t.\(UUID().uuidString)")!
        let store = LifetimeStatsStore(defaults: d)
        #expect(store.load().isEmpty)
        var s = LifetimeStats(); s.record(deleted: 7, bytes: 21_000_000_000)
        store.save(s)
        #expect(store.load() == s)
    }
    @Test func appearanceDefaultsToSystemAndRoundTrips() {
        let d = UserDefaults(suiteName: "t.\(UUID().uuidString)")!
        let store = AppearanceStore(defaults: d)
        #expect(store.load() == .system)
        store.save(.dark)
        #expect(store.load() == .dark)
        d.set("nonsense", forKey: "settings.appearance")
        #expect(store.load() == .system)
    }
    @Test func appearanceLaunchArgumentValuesMatchRawValues() {
        #expect(AppearanceSetting.allCases.map(\.rawValue) == ["system", "light", "dark"])
    }
}
