/// Photos permission as the app sees it (restricted counts as denied).
public enum AuthStatus: Equatable, Sendable {
    case notDetermined, full, limited, denied

    /// Limited access still lets the app work on the selected photos.
    public var isGranted: Bool { self == .full || self == .limited }
}

/// Permission and albums so far. Assets and delete arrive with their stages; PhotoKit lives behind this protocol in the app target.
public protocol PhotoLibrary: Sendable {
    /// Current status; never shows a prompt.
    func currentStatus() -> AuthStatus
    /// Shows the iOS prompt when undetermined; returns the resulting status.
    func authorize() async -> AuthStatus
    /// Smart albums first (Photos order), then the user's own albums.
    func albums() async -> [Album]
    /// Every item in the album, oldest first.
    func assets(in album: Album) async -> [Asset]
}
