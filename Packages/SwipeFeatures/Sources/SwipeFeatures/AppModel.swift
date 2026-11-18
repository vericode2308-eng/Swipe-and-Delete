import CoreGraphics
import Foundation
import Observation
import SwipeCore

/// Loads small images for album covers. The PhotoKit version lives in the app target.
public protocol ThumbnailLoading: Sendable {
    func thumbnail(id: String, side: CGFloat) async -> CGImage?
}

public struct NoThumbnails: ThumbnailLoading {
    public init() {}
    public func thumbnail(id: String, side: CGFloat) async -> CGImage? { nil }
}

/// Full-size photos for the swipe screen. Delivers a quick low-quality image
/// first, then the sharp one; cancelling the consuming task cancels the request.
public protocol PhotoImageLoading: Sendable {
    func images(id: String, size: CGSize) -> AsyncStream<CGImage>
    func prefetch(ids: [String], size: CGSize)
    func stopPrefetching(ids: [String], size: CGSize)
}

public struct NoImages: PhotoImageLoading {
    public init() {}
    public func images(id: String, size: CGSize) -> AsyncStream<CGImage> { AsyncStream { $0.finish() } }
    public func prefetch(ids: [String], size: CGSize) {}
    public func stopPrefetching(ids: [String], size: CGSize) {}
}

/// Store links the owner has not supplied yet stay nil, and their rows stay hidden.
public struct AppLinks: Sendable {
    public var privacyPolicy: URL?
    public var rateOnAppStore: URL?
    public init(privacyPolicy: URL? = nil, rateOnAppStore: URL? = nil) {
        self.privacyPolicy = privacyPolicy; self.rateOnAppStore = rateOnAppStore
    }
}

/// The Quick clean-up rows on Albums (D-18).
public enum CleanupFilter: Equatable, Hashable, Sendable {
    case duplicates, pagesAndThings, whatsApp

    public var title: String {
        switch self { case .duplicates: "Duplicates"; case .pagesAndThings: "Pages & Things"; case .whatsApp: "From WhatsApp" }
    }
    var albumID: String {
        switch self { case .duplicates: "filter.duplicates"; case .pagesAndThings: "filter.pages"; case .whatsApp: "filter.whatsapp" }
    }
}

/// What Done shows after a confirmed delete.
public struct DeletionSummary: Sendable {
    public let albumTitle: String
    public let reviewed: Int
    public let kept: Int
    public let deleted: Int
    /// 0 when PhotoKit gave no sizes; the UI then drops the size and says photos.
    public let freedBytes: Int64
    /// A few thumbnails taken before deleting, for the drift animation.
    public let thumbnails: [CGImage]
}

/// Navigation, permission and album state. One instance, injected at the root.
@Observable @MainActor
public final class AppModel {
    public private(set) var status: AuthStatus
    public private(set) var albums: [Album] = []
    public private(set) var hasLoadedAlbums = false
    public var filter: AlbumFilter = .all
    public private(set) var session: SwipeSession?
    public let thumbnails: ThumbnailLoading
    public let images: PhotoImageLoading
    public let links: AppLinks
    public let appVersion: String
    /// Review screen is up (marks are listed, nothing deleted yet).
    public private(set) var reviewing = false
    public private(set) var isDeleting = false
    /// Calm, authored text for the Review screen; nil when there is nothing to say.
    public private(set) var deleteMessage: String?
    public private(set) var reviewBytes: Int64?
    public private(set) var summary: DeletionSummary?
    /// Set after a confirmed delete; the root asks for a rating once after Back to Albums.
    public private(set) var reviewPromptDue = false
    public var isPro = false
    public private(set) var allowance: DeletionAllowance
    private var prompts: ReviewPromptPolicy
    private let allowanceStore: AllowanceStore
    private let promptStore: ReviewPromptStore
    private let now: @Sendable () -> Date

    /// Filters and scan progress. Grows while the scan runs; empty without a scanner.
    public private(set) var cleanup = CleanupResult()
    /// False in builds without a scanner (tests, previews): the rows stay hidden.
    public var cleanupEnabled: Bool { scanner != nil }
    private let scanner: CleanupScanner?
    private var scanTask: Task<Void, Never>?

    private let library: PhotoLibrary
    private let openSettings: @MainActor () -> Void
    private let presentLimitedPicker: @MainActor () -> Void

    public init(library: PhotoLibrary,
                thumbnails: ThumbnailLoading = NoThumbnails(),
                images: PhotoImageLoading = NoImages(),
                links: AppLinks = AppLinks(),
                scanner: CleanupScanner? = nil,
                appVersion: String = "",
                allowanceStore: AllowanceStore = AllowanceStore(),
                promptStore: ReviewPromptStore = ReviewPromptStore(),
                now: @escaping @Sendable () -> Date = { Date() },
                presentLimitedPicker: @escaping @MainActor () -> Void = {},
                openSettings: @escaping @MainActor () -> Void) {
        self.library = library
        self.thumbnails = thumbnails
        self.images = images
        self.links = links
        self.scanner = scanner
        self.appVersion = appVersion
        self.presentLimitedPicker = presentLimitedPicker
        self.openSettings = openSettings
        self.allowanceStore = allowanceStore
        self.promptStore = promptStore
        self.now = now
        self.allowance = allowanceStore.load()
        self.prompts = promptStore.load()
        self.status = library.currentStatus()
    }

    /// Granted (full or limited) → Albums; anything else → Welcome.
    public var showsWelcome: Bool { !status.isGranted }

    public var visibleAlbums: [Album] { AlbumList.visible(albums, filter: filter) }

    /// Call on launch and whenever the app returns to the foreground, so a
    /// revoked permission sends the user back to Welcome and new or deleted
    /// photos show up in the counts.
    public func refresh() async {
        status = library.currentStatus()
        guard status.isGranted else {
            albums = []; hasLoadedAlbums = false; session = nil; reviewing = false; summary = nil
            stopScan(); cleanup = CleanupResult(); return
        }
        await loadAlbums()
        startScan()
    }

    // MARK: Quick clean-up

    /// The user's own "WhatsApp" album, if there is one. The row hides otherwise.
    public var whatsAppAlbum: Album? { albums.first { $0.kind == .user && $0.title == "WhatsApp" } }

    /// Photos each row would open. WhatsApp needs no scan.
    public func count(for filter: CleanupFilter) -> Int {
        switch filter {
        case .duplicates: cleanup.duplicateCount
        case .pagesAndThings: cleanup.pagesAndThings.count
        case .whatsApp: whatsAppAlbum?.count ?? 0
        }
    }

    /// Starts the scan at low priority; a scan already running is left alone.
    public func startScan() {
        guard let scanner, status.isGranted, scanTask == nil else { return }
        scanTask = Task.detached(priority: .utility) { [weak self] in
            await scanner.run { result in
                Task { @MainActor in self?.apply(result) }
            }
            await MainActor.run { self?.scanTask = nil }
        }
    }

    public func stopScan() { scanTask?.cancel(); scanTask = nil }

    private func apply(_ result: CleanupResult) {
        // A delete since the scan began removed photos that the scan may still list.
        cleanup = result.removing(deletedSinceScan)
    }
    private var deletedSinceScan: [String] = []

    /// Opens a filter through the normal swipe flow. Nothing is deleted without a swipe and Review.
    public func openFilter(_ filter: CleanupFilter) async {
        let assets: [Asset]
        var sets: [[String]] = []
        switch filter {
        case .duplicates:
            sets = cleanup.duplicateSets
            let found = await library.assets(ids: sets.flatMap { $0 })
            let alive = Set(found.map(\.id))
            sets = sets.map { $0.filter(alive.contains) }.filter { $0.count > 1 }
            let order = Dictionary(uniqueKeysWithValues: found.map { ($0.id, $0) })
            assets = sets.flatMap { $0 }.compactMap { order[$0] }
        case .pagesAndThings:
            assets = await library.assets(ids: cleanup.pagesAndThings)
        case .whatsApp:
            guard let album = whatsAppAlbum else { return }
            assets = await library.assets(in: album)
        }
        guard !assets.isEmpty else { return }
        let album = Album(id: filter.albumID, title: filter.title, count: assets.count, kind: .smart)
        session = SwipeSession(album: album, assets: assets, sets: sets)
    }

    /// Swipe hides the album chips for filters.
    public func isFilter(_ album: Album) -> Bool { album.id.hasPrefix("filter.") }

    public func loadAlbums() async {
        guard status.isGranted else { return }
        albums = await library.albums()
        hasLoadedAlbums = true
    }

    /// The Welcome pill: ask when undetermined, open Settings when denied.
    public func pillTapped() async {
        switch status {
        case .notDetermined:
            status = await library.authorize()
            if status.isGranted { await loadAlbums(); startScan() }
        case .denied: openSettings()
        case .full, .limited: break
        }
    }

    public var pillTitle: String { status == .denied ? "Open Settings" : "Allow Photo Access" }

    /// Opens an album from its first item with no marks (D-02). Opening
    /// another album the same way discards the old session.
    public func open(_ album: Album) async {
        let assets = await library.assets(in: album)
        session = SwipeSession(album: album, assets: assets)
    }

    public func closeAlbum() { session = nil; reviewing = false; summary = nil }

    // MARK: Review and delete

    private var policy: AccessPolicy { AccessPolicy(isPro: isPro, allowance: allowance) }
    /// Free deletions left today; nil for Pro.
    public var freeRemaining: Int? { isPro ? nil : allowance.remaining(now: now()) }
    /// How many of the marked photos a delete would remove right now.
    public func deletableCount(marked: Int) -> Int { policy.deletable(marked: marked, now: now()) }

    public func beginReview() {
        guard let session, !session.marked.isEmpty else { return }
        reviewing = true; deleteMessage = nil; reviewBytes = nil
        Task { await refreshReviewBytes() }
    }

    /// Changes whenever the marks change, so the Review size estimate refreshes.
    public var reviewBytesKey: [String] { session?.marked ?? [] }

    public func endReview() { reviewing = false; deleteMessage = nil }

    /// Freed-size estimate for the marked photos; runs off the main actor in the library.
    public func refreshReviewBytes() async {
        guard let session else { return }
        let ids = session.marked
        let bytes = await library.byteSize(of: ids)
        if self.session === session, session.marked == ids { reviewBytes = bytes }
    }

    /// One iOS prompt for the photos that still exist and fit today's allowance.
    /// Cancel leaves marks, count and screen exactly as they were; the count is
    /// recorded only when iOS confirms the delete.
    public func confirmDelete() async {
        guard let session, !isDeleting else { return }
        isDeleting = true; deleteMessage = nil
        defer { isDeleting = false }
        let marked = session.marked
        let present = await library.existing(marked)
        session.unmark(marked.filter { !present.contains($0) })
        let n = policy.deletable(marked: present.count, now: now())
        guard n > 0 else {
            deleteMessage = present.isEmpty
                ? "Those photos are already gone."
                : "You've used today's \(DeletionAllowance.dailyFree) free deletions. They reset tomorrow."
            return
        }
        let ids = Array(present.prefix(n))
        let bytes = await library.byteSize(of: ids)
        var shots: [CGImage] = []
        for id in ids.prefix(8) { if let img = await thumbnails.thumbnail(id: id, side: 160) { shots.append(img) } }
        do {
            switch try await library.delete(ids) {
            case .cancelled:
                return
            case .deleted:
                let date = now()
                allowance.record(ids.count, now: date)
                allowanceStore.save(allowance)
                if session.isFinished { prompts.recordCompletedAlbum(now: date) }
                reviewPromptDue = prompts.shouldPrompt(after: .deleteSucceeded, now: date)
                if reviewPromptDue { prompts.markPrompted(now: date) }
                promptStore.save(prompts)
                summary = DeletionSummary(albumTitle: session.album.title,
                                          reviewed: min(session.index, session.assets.count),
                                          kept: session.keptCount, deleted: ids.count,
                                          freedBytes: bytes, thumbnails: shots)
                reviewing = false
                deletedSinceScan += ids
                cleanup = cleanup.removing(ids)
            }
        } catch {
            deleteMessage = "Couldn't delete the photos. Nothing was removed."
        }
    }

    public func ratingShown() { reviewPromptDue = false }

    public func manageLimitedSelection() { presentLimitedPicker() }
}
