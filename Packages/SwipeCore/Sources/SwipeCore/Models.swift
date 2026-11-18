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
    public init(id: String, kind: AssetKind = .photo, created: Date = .distantPast) {
        self.id = id; self.kind = kind; self.created = created
    }
}

public enum Decision: Equatable, Sendable {
    case keep, delete
}
