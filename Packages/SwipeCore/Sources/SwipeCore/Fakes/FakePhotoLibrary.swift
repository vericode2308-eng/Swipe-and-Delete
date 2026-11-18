import Foundation

public final class FakePhotoLibrary: PhotoLibrary, @unchecked Sendable {
    private let lock = NSLock()
    private var status: AuthStatus
    private let statusAfterPrompt: AuthStatus
    private var prompts = 0

    public init(status: AuthStatus, statusAfterPrompt: AuthStatus = .full) {
        self.status = status
        self.statusAfterPrompt = statusAfterPrompt
    }

    public var promptCount: Int { lock.withLock { prompts } }
    public func set(_ s: AuthStatus) { lock.withLock { status = s } }

    public func currentStatus() -> AuthStatus { lock.withLock { status } }

    public func authorize() async -> AuthStatus {
        lock.withLock {
            if status == .notDetermined { prompts += 1; status = statusAfterPrompt }
            return status
        }
    }
}
