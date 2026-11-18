import Foundation

public struct Album: Equatable, Hashable, Sendable, Identifiable {
    public let id: String
    public let title: String
    public let count: Int
    public init(id: String, title: String, count: Int) {
        self.id = id; self.title = title; self.count = count
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
