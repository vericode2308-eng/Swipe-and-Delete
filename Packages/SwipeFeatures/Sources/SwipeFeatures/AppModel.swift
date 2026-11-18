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

/// Store links the owner has not supplied yet stay nil, and their rows stay hidden.
public struct AppLinks: Sendable {
    public var privacyPolicy: URL?
    public var rateOnAppStore: URL?
    public init(privacyPolicy: URL? = nil, rateOnAppStore: URL? = nil) {
        self.privacyPolicy = privacyPolicy; self.rateOnAppStore = rateOnAppStore
    }
}

/// Navigation, permission and album state. One instance, injected at the root.
@Observable @MainActor
public final class AppModel {
    public private(set) var status: AuthStatus
    public private(set) var albums: [Album] = []
    public private(set) var hasLoadedAlbums = false
    public var filter: AlbumFilter = .all
    public let thumbnails: ThumbnailLoading
    public let links: AppLinks
    public let appVersion: String

    private let library: PhotoLibrary
    private let openSettings: @MainActor () -> Void
    private let presentLimitedPicker: @MainActor () -> Void

    public init(library: PhotoLibrary,
                thumbnails: ThumbnailLoading = NoThumbnails(),
                links: AppLinks = AppLinks(),
                appVersion: String = "",
                presentLimitedPicker: @escaping @MainActor () -> Void = {},
                openSettings: @escaping @MainActor () -> Void) {
        self.library = library
        self.thumbnails = thumbnails
        self.links = links
        self.appVersion = appVersion
        self.presentLimitedPicker = presentLimitedPicker
        self.openSettings = openSettings
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
        guard status.isGranted else { albums = []; hasLoadedAlbums = false; return }
        await loadAlbums()
    }

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
            if status.isGranted { await loadAlbums() }
        case .denied: openSettings()
        case .full, .limited: break
        }
    }

    public var pillTitle: String { status == .denied ? "Open Settings" : "Allow Photo Access" }

    public func manageLimitedSelection() { presentLimitedPicker() }
}
