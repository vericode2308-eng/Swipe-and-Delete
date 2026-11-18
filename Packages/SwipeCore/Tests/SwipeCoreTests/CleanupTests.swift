import Foundation
import Testing
@testable import SwipeCore

private let t0 = Date(timeIntervalSince1970: 1_700_000_000)
private func traits(_ id: String, at offset: TimeInterval = 0, hash: UInt64 = 0xA5A5_5A5A_F0F0_0F0F,
                    people: Bool = false, utility: Bool = false, q: Float = 0.5,
                    fp: [Float] = [], modified: Date = t0, rev: Int = 1) -> PhotoTraits {
    PhotoTraits(id: id, modified: modified, created: t0.addingTimeInterval(offset), hasPeople: people,
                isUtility: utility, qualityScore: q, imageHash: hash, featurePrint: fp, visionRevision: rev)
}

@Suite struct CleanupIndexTests {
    let index = CleanupIndex()

    @Test func identicalHashesYearsApartFormOneSet() {
        let year: TimeInterval = 365 * 86_400
        let sets = index.duplicateSets([traits("a", at: 0), traits("b", at: 2 * year),
                                        traits("c", at: 3 * year, hash: 0x1357_9BDF_2468_ACE0)])
        #expect(sets == [["a", "b"]])
    }

    @Test func hashWithinTwoBitsMatchesThreeBitsDoesNot() {
        let base: UInt64 = 0xA5A5_5A5A_F0F0_0F0F
        let two = traits("two", hash: base ^ 0b11)
        let three = traits("three", hash: base ^ 0b111)
        #expect(index.duplicateSets([traits("a"), two]) == [["a", "two"]])
        #expect(index.duplicateSets([traits("a"), three]).isEmpty)
    }

    @Test func flatPicturesNeverMatchEachOther() {
        let sets = index.duplicateSets([traits("a", hash: 0), traits("b", hash: 0),
                                        traits("c", hash: .max), traits("d", hash: .max)])
        #expect(sets.isEmpty)
    }

    @Test func similarPrintsThirtySecondsApartFormASetTwoMinutesDoNot() {
        let p: [Float] = [1, 0, 0, 0], near: [Float] = [1, 0.1, 0, 0]
        let h1: UInt64 = 0x0123_4567_89AB_CDEF, h2: UInt64 = 0xFEDC_BA98_7654_3210
        let close = index.duplicateSets([traits("a", hash: h1, fp: p), traits("b", at: 30, hash: h2, fp: near)])
        let far = index.duplicateSets([traits("a", hash: h1, fp: p), traits("b", at: 120, hash: h2, fp: near)])
        #expect(close == [["a", "b"]])
        #expect(far.isEmpty)
    }

    @Test func differentPrintsInsideTheWindowStaySeparate() {
        let sets = index.duplicateSets([
            traits("a", hash: 0x0123_4567_89AB_CDEF, fp: [1, 0, 0, 0]),
            traits("b", at: 5, hash: 0xFEDC_BA98_7654_3210, fp: [0, 1, 0, 0])])
        #expect(sets.isEmpty)
    }

    @Test func setsAreNewestFirstAndOldestFirstInside() {
        let h1: UInt64 = 0x0123_4567_89AB_CDEF, h2: UInt64 = 0xFEDC_BA98_7654_3210
        let sets = index.duplicateSets([
            traits("new2", at: 5_000, hash: h2), traits("old1", at: 0, hash: h1),
            traits("new1", at: 4_000, hash: h2), traits("old2", at: 10, hash: h1)])
        #expect(sets == [["new1", "new2"], ["old1", "old2"]])
    }

    @Test func pagesAndThingsRules() {
        let found = index.pagesAndThings([
            traits("page", at: 1, utility: true),
            traits("blur", at: 2, q: -0.6),
            traits("selfieUtility", at: 3, people: true, utility: true),
            traits("fine", at: 4, q: 0.4)])
        #expect(found == ["blur", "page"])
    }
}

@Suite struct CleanupCacheTests {
    private func tempStore() -> CleanupCacheStore {
        CleanupCacheStore(url: FileManager.default.temporaryDirectory
            .appendingPathComponent("cleanup-\(UUID().uuidString).bin"))
    }

    @Test func roundTrips() {
        let s = tempStore()
        s.save(["a": traits("a", fp: [1, 2, 3])])
        #expect(s.load()["a"] == traits("a", fp: [1, 2, 3]))
    }

    @Test func corruptFileIsDeletedAndReadsEmpty() throws {
        let s = tempStore()
        try Data("not a plist".utf8).write(to: s.url)
        #expect(s.load().isEmpty)
        #expect(!FileManager.default.fileExists(atPath: s.url.path))
    }
}

/// Counts analyse calls and returns a fixed answer.
private final class CountingAnalyzer: PhotoAnalyzer, @unchecked Sendable {
    let revision: Int
    private let lock = NSLock()
    private var calls: [String] = []
    private let skip: Set<String>
    init(revision: Int = 1, skip: Set<String> = []) { self.revision = revision; self.skip = skip }
    var analysed: [String] { lock.withLock { calls } }
    func analyse(id: String) async -> PhotoAnalysis? {
        lock.withLock { calls.append(id) }
        if skip.contains(id) { return nil }
        return PhotoAnalysis(hasPeople: false, isUtility: id.hasPrefix("page"), qualityScore: 0.5,
                             imageHash: id == "a" || id == "b" ? 0x0123_4567_89AB_CDEF : 0xFEDC_BA98_7654_3210 &* UInt64(id.utf8.count))
    }
}

private final class Box<T>: @unchecked Sendable {
    private let lock = NSLock(); private var v: T
    init(_ v: T) { self.v = v }
    var value: T { get { lock.withLock { v } } set { lock.withLock { v = newValue } } }
}

@Suite struct CleanupScannerTests {
    private func store() -> CleanupCacheStore {
        CleanupCacheStore(url: FileManager.default.temporaryDirectory
            .appendingPathComponent("scan-\(UUID().uuidString).bin"))
    }
    private func items(_ ids: [String]) -> [ScanItem] {
        ids.enumerated().map { ScanItem(id: $1, created: t0.addingTimeInterval(-Double($0) * 1000), modified: t0) }
    }

    @Test func findsFiltersAndSkipsPhotosWithoutAThumbnail() async {
        let lib = FakePhotoLibrary(status: .full)
        lib.setScanItems(items(["a", "b", "page1", "icloud"]))
        let analyzer = CountingAnalyzer(skip: ["icloud"])
        let last = Box(CleanupResult())
        await CleanupScanner(library: lib, analyzer: analyzer, store: store())
            .run { last.value = $0 }
        #expect(last.value.duplicateSets == [["b", "a"]] || last.value.duplicateSets == [["a", "b"]])
        #expect(last.value.pagesAndThings == ["page1"])
        #expect(last.value.checked == 4 && last.value.total == 4 && !last.value.isRunning)
    }

    @Test func secondRunUsesTheCache() async {
        let lib = FakePhotoLibrary(status: .full)
        lib.setScanItems(items(["a", "b"]))
        let s = store()
        let first = CountingAnalyzer()
        await CleanupScanner(library: lib, analyzer: first, store: s).run { _ in }
        let second = CountingAnalyzer()
        await CleanupScanner(library: lib, analyzer: second, store: s).run { _ in }
        #expect(first.analysed.count == 2)
        #expect(second.analysed.isEmpty)
    }

    @Test func changedModificationDateOrRevisionIsAnalysedAgain() async {
        let lib = FakePhotoLibrary(status: .full)
        lib.setScanItems(items(["a", "b"]))
        let s = store()
        await CleanupScanner(library: lib, analyzer: CountingAnalyzer(), store: s).run { _ in }
        lib.setScanItems([ScanItem(id: "a", created: t0, modified: t0.addingTimeInterval(60)),
                          ScanItem(id: "b", created: t0, modified: t0)])
        let edited = CountingAnalyzer()
        await CleanupScanner(library: lib, analyzer: edited, store: s).run { _ in }
        #expect(edited.analysed == ["a"])
        let newer = CountingAnalyzer(revision: 2)
        await CleanupScanner(library: lib, analyzer: newer, store: s).run { _ in }
        #expect(Set(newer.analysed) == ["a", "b"])
    }

    @Test func deletedPhotosAreDroppedFromTheCache() async {
        let lib = FakePhotoLibrary(status: .full)
        lib.setScanItems(items(["a", "b"]))
        let s = store()
        await CleanupScanner(library: lib, analyzer: CountingAnalyzer(), store: s).run { _ in }
        lib.remove("b")
        await CleanupScanner(library: lib, analyzer: CountingAnalyzer(), store: s).run { _ in }
        #expect(Set(s.load().keys) == ["a"])
    }

    @Test func stoppedScanKeepsWhatItDidAndResumes() async {
        let lib = FakePhotoLibrary(status: .full)
        lib.setScanItems(items((0..<10).map { "p\($0)" }))
        let s = store()
        let stop = Box(false)
        let slow = CountingAnalyzer()
        let task = Task {
            await CleanupScanner(library: lib, analyzer: slow, store: s,
                                 shouldPause: { stop.value }, pausePoll: .milliseconds(5), publishEvery: 1)
                .run { r in if r.checked >= 3 { stop.value = true } }
        }
        try? await Task.sleep(for: .milliseconds(150))
        task.cancel(); await task.value
        let kept = s.load().count
        #expect(kept >= 3 && kept < 10)
        let resumed = CountingAnalyzer()
        await CleanupScanner(library: lib, analyzer: resumed, store: s).run { _ in }
        #expect(resumed.analysed.count == 10 - kept)
    }

    @Test func pausesWhileTheConditionHolds() async {
        let lib = FakePhotoLibrary(status: .full)
        lib.setScanItems(items(["a"]))
        let paused = Box(true)
        let analyzer = CountingAnalyzer()
        let task = Task {
            await CleanupScanner(library: lib, analyzer: analyzer, store: store(),
                                 shouldPause: { paused.value }, pausePoll: .milliseconds(5)).run { _ in }
        }
        try? await Task.sleep(for: .milliseconds(60))
        #expect(analyzer.analysed.isEmpty)
        paused.value = false
        await task.value
        #expect(analyzer.analysed == ["a"])
    }
}

@Suite struct SessionSetTests {
    @Test @MainActor func setPositionAndFullyMarkedSets() {
        let album = Album(id: "f", title: "Duplicates", count: 4)
        let assets = ["a", "b", "c", "d"].map { Asset(id: $0) }
        let s = SwipeSession(album: album, assets: assets, sets: [["a", "b"], ["c", "d"]])
        #expect(s.setPosition(of: "d") == .init(set: 2, ofSets: 2, item: 2, ofItems: 2))
        s.delete(); s.delete()                       // a and b
        #expect(s.fullyMarkedSets == 1)
        s.keep(); s.delete()                         // c kept, d marked
        #expect(s.fullyMarkedSets == 1)
    }
}
