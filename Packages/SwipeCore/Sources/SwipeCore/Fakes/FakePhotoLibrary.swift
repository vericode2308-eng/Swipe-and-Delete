import Foundation

public final class FakePhotoLibrary: PhotoLibrary, @unchecked Sendable {
    private let lock = NSLock()
    private var status: AuthStatus
    private let statusAfterPrompt: AuthStatus
    private var prompts = 0
    private var albumList: [Album]
    private var loads = 0

    public init(status: AuthStatus, statusAfterPrompt: AuthStatus = .full,
                albums: [Album] = []) {
        self.albumList = albums
        self.status = status
        self.statusAfterPrompt = statusAfterPrompt
    }

    public var promptCount: Int { lock.withLock { prompts } }
    public var albumLoadCount: Int { lock.withLock { loads } }
    public func setAlbums(_ a: [Album]) { lock.withLock { albumList = a } }
    public func set(_ s: AuthStatus) { lock.withLock { status = s } }

    public func currentStatus() -> AuthStatus { lock.withLock { status } }

    public func authorize() async -> AuthStatus {
        lock.withLock {
            if status == .notDetermined { prompts += 1; status = statusAfterPrompt }
            return status
        }
    }

    public func albums() async -> [Album] {
        lock.withLock { loads += 1; return status.isGranted ? albumList : [] }
    }
}
