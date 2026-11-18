import Foundation

/// Walks the library newest first, analyses what the cache does not already know,
/// and publishes the filters' answer as it grows. Stops when its task is cancelled;
/// what was analysed is saved, so the next run continues from there (D-21).
public actor CleanupScanner {
    private let library: PhotoLibrary
    private let analyzer: PhotoAnalyzer
    private let store: CleanupCacheStore
    private let index: CleanupIndex
    private let shouldPause: @Sendable () -> Bool
    private let pausePoll: Duration
    private let publishEvery: Int
    private var traits: [String: PhotoTraits] = [:]

    public init(library: PhotoLibrary, analyzer: PhotoAnalyzer, store: CleanupCacheStore,
                index: CleanupIndex = CleanupIndex(),
                shouldPause: @escaping @Sendable () -> Bool = { false },
                pausePoll: Duration = .seconds(5), publishEvery: Int = 100) {
        self.library = library; self.analyzer = analyzer; self.store = store
        self.index = index; self.shouldPause = shouldPause
        self.pausePoll = pausePoll; self.publishEvery = publishEvery
    }

    /// One pass. `onUpdate` is called with the cached answer first, then as the scan grows.
    public func run(onUpdate: @Sendable (CleanupResult) -> Void) async {
        let items = await library.scanItems()
        let live = Set(items.map(\.id))
        traits = store.load().filter { live.contains($0.key) }
        let revision = analyzer.revision

        func publish(checked: Int, running: Bool) {
            var r = CleanupResult()
            let all = Array(traits.values)
            r.duplicateSets = index.duplicateSets(all)
            r.pagesAndThings = index.pagesAndThings(all)
            r.checked = checked; r.total = items.count; r.isRunning = running
            onUpdate(r)
        }

        var checked = 0
        var sinceSave = 0
        publish(checked: 0, running: true)
        for item in items {
            if Task.isCancelled { break }
            while shouldPause() && !Task.isCancelled { try? await Task.sleep(for: pausePoll) }
            if Task.isCancelled { break }
            if let known = traits[item.id], known.modified == item.modified, known.visionRevision == revision {
                checked += 1
                continue
            }
            if let a = await analyzer.analyse(id: item.id) {
                traits[item.id] = PhotoTraits(id: item.id, modified: item.modified, created: item.created,
                                              hasPeople: a.hasPeople, isUtility: a.isUtility,
                                              qualityScore: a.qualityScore, imageHash: a.imageHash,
                                              featurePrint: a.featurePrint, visionRevision: revision)
                sinceSave += 1
            }
            checked += 1
            if sinceSave >= publishEvery {
                store.save(traits); sinceSave = 0
                publish(checked: checked, running: true)
            }
        }
        store.save(traits)
        publish(checked: checked, running: false)
    }
}
