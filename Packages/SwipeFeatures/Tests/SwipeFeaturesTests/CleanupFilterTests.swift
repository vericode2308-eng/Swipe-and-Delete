import Foundation
import Testing
import SwipeCore
@testable import SwipeFeatures

private struct FixedAnalyzer: PhotoAnalyzer {
    let revision = 1
    func analyse(id: String) async -> PhotoAnalysis? {
        switch id {
        case "d1", "d2": PhotoAnalysis(hasPeople: false, isUtility: false, qualityScore: 0.5, imageHash: 0x0123_4567_89AB_CDEF)
        case "page": PhotoAnalysis(hasPeople: false, isUtility: true, qualityScore: 0.5, imageHash: 0xFEDC_BA98_7654_3210)
        default: PhotoAnalysis(hasPeople: true, isUtility: false, qualityScore: 0.5, imageHash: 0x1111_2222_3333_4444 &* UInt64(id.utf8.last ?? 1))
        }
    }
}

@MainActor
struct CleanupFilterTests {
    let whatsApp = Album(id: "w", title: "WhatsApp", count: 2, kind: .user)

    func model(scan: Bool = true) async -> (AppModel, FakePhotoLibrary) {
        let d = UserDefaults(suiteName: "t.\(UUID().uuidString)")!
        let lib = FakePhotoLibrary(status: .full, albums: [whatsApp])
        let t0 = Date(timeIntervalSince1970: 1_700_000_000)
        let ids = ["d1", "p1", "d2", "page"]
        lib.setScanItems(ids.enumerated().map { ScanItem(id: $1, created: t0.addingTimeInterval(Double($0) * 100_000), modified: t0) })
        lib.setAssets([Asset(id: "w1"), Asset(id: "w2")], in: whatsApp)
        let store = CleanupCacheStore(url: FileManager.default.temporaryDirectory.appendingPathComponent("m-\(UUID().uuidString).bin"))
        let scanner = scan ? CleanupScanner(library: lib, analyzer: FixedAnalyzer(), store: store) : nil
        let m = AppModel(library: lib, scanner: scanner, allowanceStore: AllowanceStore(defaults: d),
                         promptStore: ReviewPromptStore(defaults: d), openSettings: {})
        await m.loadAlbums()
        m.startScan()
        for _ in 0..<200 where m.cleanup.checked < 4 || m.cleanup.isRunning { try? await Task.sleep(for: .milliseconds(10)) }
        return (m, lib)
    }

    @Test func rowsCountWhatTheScanFound() async {
        let (m, _) = await model()
        #expect(m.count(for: .duplicates) == 2)
        #expect(m.count(for: .pagesAndThings) == 1)
        #expect(m.count(for: .whatsApp) == 2)
        #expect(m.cleanupEnabled)
    }

    @Test func noScannerMeansNoRows() async {
        let (m, _) = await model(scan: false)
        #expect(!m.cleanupEnabled && m.count(for: .duplicates) == 0)
    }

    @Test func duplicatesOpensSetsAsAFilterSession() async {
        let (m, _) = await model()
        await m.openFilter(.duplicates)
        #expect(m.session?.album.title == "Duplicates")
        #expect(m.session?.assets.map(\.id) == ["d1", "d2"])
        #expect(m.session?.setPosition(of: "d2")?.ofItems == 2)
        #expect(m.isFilter(m.session!.album))
    }

    @Test func pagesAndWhatsAppOpen() async {
        let (m, _) = await model()
        await m.openFilter(.pagesAndThings)
        #expect(m.session?.assets.map(\.id) == ["page"])
        await m.openFilter(.whatsApp)
        #expect(m.session?.album.title == "From WhatsApp" && m.session?.assets.count == 2)
    }

    @Test func deletingFromAFilterUpdatesTheRows() async {
        let (m, _) = await model()
        await m.openFilter(.duplicates)
        m.session!.delete(); m.session!.keep()
        m.beginReview()
        await m.confirmDelete()
        #expect(m.summary?.deleted == 1)
        #expect(m.count(for: .duplicates) == 0)          // a set of one is no longer a set
    }
}
