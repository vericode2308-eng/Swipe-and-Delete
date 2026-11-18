import Observation
import SwipeCore

/// Navigation and permission state. One instance, injected at the root.
@Observable @MainActor
public final class AppModel {
    public private(set) var status: AuthStatus
    private let library: PhotoLibrary
    private let openSettings: @MainActor () -> Void

    public init(library: PhotoLibrary, openSettings: @escaping @MainActor () -> Void) {
        self.library = library
        self.openSettings = openSettings
        self.status = library.currentStatus()
    }

    /// Granted (full or limited) → Albums; anything else → Welcome.
    public var showsWelcome: Bool { !status.isGranted }

    /// Call on launch and whenever the app returns to the foreground, so a
    /// revoked permission sends the user back to Welcome.
    public func refresh() { status = library.currentStatus() }

    /// The Welcome pill: ask when undetermined, open Settings when denied.
    public func pillTapped() async {
        switch status {
        case .notDetermined: status = await library.authorize()
        case .denied: openSettings()
        case .full, .limited: break
        }
    }

    public var pillTitle: String { status == .denied ? "Open Settings" : "Allow Photo Access" }
}
