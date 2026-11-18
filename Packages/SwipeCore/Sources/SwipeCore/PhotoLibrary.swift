/// Photos permission as the app sees it (restricted counts as denied).
public enum AuthStatus: Equatable, Sendable {
    case notDetermined, full, limited, denied

    /// Limited access still lets the app work on the selected photos.
    public var isGranted: Bool { self == .full || self == .limited }
}

/// Stage 3 needs permission only. Albums, assets and delete arrive with
/// their stages; PhotoKit lives behind this protocol in the app target.
public protocol PhotoLibrary: Sendable {
    /// Current status; never shows a prompt.
    func currentStatus() -> AuthStatus
    /// Shows the iOS prompt when undetermined; returns the resulting status.
    func authorize() async -> AuthStatus
}
