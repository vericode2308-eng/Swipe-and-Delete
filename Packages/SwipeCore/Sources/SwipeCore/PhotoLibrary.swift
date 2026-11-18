/// Photos permission as the app sees it (restricted counts as denied).
public enum AuthStatus: Equatable, Sendable {
    case notDetermined, full, limited, denied

    /// Limited access still lets the app work on the selected photos.
    public var isGranted: Bool { self == .full || self == .limited }
}

/// What the iOS delete prompt ended with. Any other failure throws.
public enum DeleteOutcome: Equatable, Sendable { case deleted, cancelled }

/// Permission, albums, assets and delete. PhotoKit lives behind this protocol in the app target.
public protocol PhotoLibrary: Sendable {
    /// Current status; never shows a prompt.
    func currentStatus() -> AuthStatus
    /// Shows the iOS prompt when undetermined; returns the resulting status.
    func authorize() async -> AuthStatus
    /// Smart albums first (Photos order), then the user's own albums.
    func albums() async -> [Album]
    /// Every item in the album, newest first (owner decision 2026-11-18, supersedes oldest-first).
    func assets(in album: Album) async -> [Asset]
    /// Every plain photo or Live Photo (no videos, no screenshots), newest first, for the clean-up scan.
    func scanItems() async -> [ScanItem]
    /// These ids as assets, in the order given; ids that no longer exist are left out.
    func assets(ids: [String]) async -> [Asset]
    /// The ids that still exist, in the order given. Used right before deleting.
    func existing(_ ids: [String]) async -> [String]
    /// Sum of the original file sizes, in bytes. Undocumented in PhotoKit, so a
    /// missing value counts as 0 and the UI says "about".
    func byteSize(of ids: [String]) async -> Int64
    /// One request, one iOS prompt. Returns `.cancelled` when the user says no.
    func delete(_ ids: [String]) async throws -> DeleteOutcome
}
