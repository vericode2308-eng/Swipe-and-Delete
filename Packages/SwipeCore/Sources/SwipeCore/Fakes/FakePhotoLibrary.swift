import Foundation

public final class FakePhotoLibrary: PhotoLibrary, @unchecked Sendable {
    private let lock = NSLock()
    private var status: AuthStatus
    private let statusAfterPrompt: AuthStatus
    private var prompts = 0
    private var albumList: [Album]
    private var loads = 0
    private var assetsByAlbum: [String: [Asset]] = [:]
    private var gone: Set<String> = []
    private var sizes: [String: Int64] = [:]
    private var nextDelete: Result<DeleteOutcome, Error> = .success(.deleted)
    private var deleteCalls: [[String]] = []

    public init(status: AuthStatus, statusAfterPrompt: AuthStatus = .full,
                albums: [Album] = []) {
        self.albumList = albums
        self.status = status
        self.statusAfterPrompt = statusAfterPrompt
    }

    public var promptCount: Int { lock.withLock { prompts } }
    public var albumLoadCount: Int { lock.withLock { loads } }
    public func setAssets(_ a: [Asset], in album: Album) { lock.withLock { assetsByAlbum[album.id] = a } }
    public func setAlbums(_ a: [Album]) { lock.withLock { albumList = a } }
    public func set(_ s: AuthStatus) { lock.withLock { status = s } }

    public var deleteRequests: [[String]] { lock.withLock { deleteCalls } }
    /// What the next delete does: `.success(.deleted)` (default), `.success(.cancelled)` or a throw.
    public func setDelete(_ r: Result<DeleteOutcome, Error>) { lock.withLock { nextDelete = r } }
    public func setSize(_ bytes: Int64, for id: String) { lock.withLock { sizes[id] = bytes } }
    /// Simulates a photo removed elsewhere.
    public func remove(_ id: String) { lock.withLock { _ = gone.insert(id) } }

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

    public func assets(in album: Album) async -> [Asset] {
        lock.withLock { assetsByAlbum[album.id] ?? [] }
    }

    public func existing(_ ids: [String]) async -> [String] {
        lock.withLock { ids.filter { !gone.contains($0) } }
    }

    public func byteSize(of ids: [String]) async -> Int64 {
        lock.withLock { ids.reduce(0) { $0 + (sizes[$1] ?? 0) } }
    }

    public func delete(_ ids: [String]) async throws -> DeleteOutcome {
        let r: Result<DeleteOutcome, Error> = lock.withLock {
            deleteCalls.append(ids)
            if case .success(.deleted) = nextDelete { gone.formUnion(ids) }
            return nextDelete
        }
        return try r.get()
    }
}
