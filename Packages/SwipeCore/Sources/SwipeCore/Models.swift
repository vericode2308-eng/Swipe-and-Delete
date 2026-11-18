import Foundation

public enum AlbumKind: Equatable, Hashable, Sendable {
    case smart, user
}

public struct Album: Equatable, Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let count: Int
    public let kind: AlbumKind
    /// Newest photo in the album, used as its cover.
    public let coverID: String?
    public init(id: String, title: String, count: Int,
                kind: AlbumKind = .user, coverID: String? = nil) {
        self.id = id; self.title = title; self.count = count
        self.kind = kind; self.coverID = coverID
    }
}

public enum AssetKind: Equatable, Hashable, Sendable {
    case photo, screenshot, livePhoto, video
}

public struct Asset: Equatable, Hashable, Sendable, Identifiable {
    public let id: String
    public let kind: AssetKind
    public let created: Date
    /// Seconds, for videos only.
    public let duration: TimeInterval?
    public init(id: String, kind: AssetKind = .photo, created: Date = .distantPast, duration: TimeInterval? = nil) {
        self.id = id; self.kind = kind; self.created = created; self.duration = duration
    }
}

public enum Decision: Equatable, Sendable {
    case keep, delete
}
