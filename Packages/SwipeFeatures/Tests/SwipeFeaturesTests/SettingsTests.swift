import Foundation
import Testing
import SwipeCore
@testable import SwipeFeatures

@MainActor
struct SettingsTests {
    let album = Album(id: "a", title: "Shots", count: 4, kind: .smart)

    func make(_ d: UserDefaults, lib: FakePhotoLibrary? = nil) -> (AppModel, FakePhotoLibrary) {
        let lib = lib ?? { let l = FakePhotoLibrary(status: .full, albums: [album])
            l.setAssets((1...4).map { Asset(id: String($0)) }, in: album)
            for i in 1...4 { l.setSize(2_000_000, for: String(i)) }
            return l }()
        let m = AppModel(library: lib, allowanceStore: AllowanceStore(defaults: d),
                         promptStore: ReviewPromptStore(defaults: d),
                         statsStore: LifetimeStatsStore(defaults: d),
                         appearanceStore: AppearanceStore(defaults: d), openSettings: {})
        return (m, lib)
    }

    func markTwoAndReview(_ m: AppModel) async {
        await m.open(album)
        let s = m.session!
        s.delete(); s.delete(); s.keep(); s.keep()
        m.beginReview()
    }

    @Test func confirmedDeleteAddsToLifetimeTotalsAndSurvivesRelaunch() async {
        let d = UserDefaults(suiteName: "t.\(UUID().uuidString)")!
        let (m, _) = make(d)
        #expect(m.lifetime.isEmpty)
        await markTwoAndReview(m)
        await m.confirmDelete()
        #expect(m.lifetime.deleted == 2 && m.lifetime.freedBytes == 4_000_000)
        let (again, _) = make(d)
        #expect(again.lifetime == m.lifetime)
    }

    @Test func cancelledDeleteLeavesLifetimeTotalsAlone() async {
        let d = UserDefaults(suiteName: "t.\(UUID().uuidString)")!
        let (m, lib) = make(d)
        lib.setDelete(.success(.cancelled))
        await markTwoAndReview(m)
        await m.confirmDelete()
        #expect(m.lifetime.isEmpty)
    }

    @Test func appearanceIsSavedAndRestored() {
        let d = UserDefaults(suiteName: "t.\(UUID().uuidString)")!
        let (m, _) = make(d)
        #expect(m.appearance == .system)
        m.setAppearance(.light)
        #expect(m.appearance == .light)
        let (again, _) = make(d)
        #expect(again.appearance == .light)
    }
}
