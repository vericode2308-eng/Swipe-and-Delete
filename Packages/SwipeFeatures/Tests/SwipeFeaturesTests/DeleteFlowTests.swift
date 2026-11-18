import Foundation
import Testing
import SwipeCore
@testable import SwipeFeatures

@MainActor
struct DeleteFlowTests {
    struct Boom: Error {}
    let album = Album(id: "a", title: "Shots", count: 6, kind: .smart)
    var ids: [String] { (1...6).map(String.init) }

    /// Fresh stores per test so nothing leaks into the real defaults.
    func setup(marks: Set<String> = ["1", "2", "3"], swipeAll: Bool = true, pro: Bool = false,
               used: Int = 0) async -> (AppModel, FakePhotoLibrary, UserDefaults) {
        let suite = "t.\(UUID().uuidString)"
        let d = UserDefaults(suiteName: suite)!
        if used > 0 { var a = DeletionAllowance(); a.record(used, now: Date()); AllowanceStore(defaults: d).save(a) }
        let lib = FakePhotoLibrary(status: .full, albums: [album])
        lib.setAssets(ids.map { Asset(id: $0) }, in: album)
        for i in ids { lib.setSize(1_000_000, for: i) }
        let m = AppModel(library: lib, allowanceStore: AllowanceStore(defaults: d),
                         promptStore: ReviewPromptStore(defaults: d), openSettings: {})
        m.isPro = pro
        await m.open(album)
        for i in ids { marks.contains(i) ? m.session!.delete() : m.session!.keep() }
        _ = swipeAll
        m.beginReview()
        return (m, lib, d)
    }

    @Test func successRecordsCountAndShowsSummary() async {
        let (m, lib, d) = await setup()
        await m.confirmDelete()
        #expect(lib.deleteRequests == [["1", "2", "3"]])
        #expect(m.summary?.deleted == 3 && m.summary?.freedBytes == 3_000_000 && m.summary?.kept == 3)
        #expect(m.freeRemaining == 47)
        #expect(AllowanceStore(defaults: d).load().remaining(now: Date()) == 47)
    }
    @Test func cancelKeepsEverything() async {
        let (m, lib, d) = await setup()
        lib.setDelete(.success(.cancelled))
        await m.confirmDelete()
        #expect(m.summary == nil && m.reviewing && m.session?.marked == ["1", "2", "3"])
        #expect(m.freeRemaining == 50 && AllowanceStore(defaults: d).load().remaining(now: Date()) == 50)
    }
    @Test func failureDoesNotCountAndSaysSo() async {
        let (m, lib, _) = await setup()
        lib.setDelete(.failure(Boom()))
        await m.confirmDelete()
        #expect(m.summary == nil && m.freeRemaining == 50 && m.deleteMessage != nil && m.session?.marked.count == 3)
    }
    @Test func vanishedPhotosAreSkipped() async {
        let (m, lib, _) = await setup()
        lib.remove("2")
        await m.confirmDelete()
        #expect(lib.deleteRequests == [["1", "3"]] && m.summary?.deleted == 2)
    }
    @Test func freePlanDeletesOnlyWhatFits() async {
        let (m, lib, _) = await setup(used: 48)
        await m.confirmDelete(dropOverflow: true)
        #expect(lib.deleteRequests == [["1", "2"]] && m.freeRemaining == 0)
        #expect(m.session?.marked == ["1", "2"])             // the third mark is dropped (D-22)
    }
    @Test func nothingLeftTodayShowsMessageAndNoPrompt() async {
        let (m, lib, _) = await setup(used: 50)
        await m.confirmDelete()
        #expect(lib.deleteRequests.isEmpty && m.showsPaywall && m.summary == nil)
    }
    @Test func proIgnoresTheLimit() async {
        let (m, lib, _) = await setup(pro: true, used: 50)
        await m.confirmDelete()
        #expect(lib.deleteRequests.count == 1 && m.freeRemaining == nil)
    }
}
