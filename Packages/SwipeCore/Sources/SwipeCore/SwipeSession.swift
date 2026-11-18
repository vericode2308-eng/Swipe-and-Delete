import Observation

/// One pass through an album. Created fresh every time an album opens and
/// never saved (D-02).
@Observable @MainActor
public final class SwipeSession {
    public let album: Album
    public let assets: [Asset]
    public private(set) var index = 0
    /// Ordered, unique ids marked for deletion.
    public private(set) var marked: [String] = []
    private var history: [Decision] = []

    /// Duplicate sets in play order; empty outside the Duplicates filter.
    public let sets: [[String]]
    private let setPosition: [String: SetPosition]

    public struct SetPosition: Equatable, Sendable {
        public let set: Int, ofSets: Int, item: Int, ofItems: Int
    }

    public init(album: Album, assets: [Asset], sets: [[String]] = []) {
        self.album = album
        self.assets = assets
        self.sets = sets
        var pos: [String: SetPosition] = [:]
        for (s, members) in sets.enumerated() {
            for (i, id) in members.enumerated() {
                pos[id] = SetPosition(set: s + 1, ofSets: sets.count, item: i + 1, ofItems: members.count)
            }
        }
        self.setPosition = pos
    }

    /// "Set 3 · 2 of 3" for the Duplicates filter; nil elsewhere.
    public func setPosition(of id: String) -> SetPosition? { setPosition[id] }

    /// Sets in which every copy is marked, so Review can remind the user to keep one.
    public var fullyMarkedSets: Int {
        let m = Set(marked)
        return sets.filter { !$0.isEmpty && $0.allSatisfy(m.contains) }.count
    }

    public var isFinished: Bool { index >= assets.count }
    public var current: Asset? { isFinished ? nil : assets[index] }
    public var keptCount: Int { history.filter { $0 == .keep }.count }
    public var canUndo: Bool { !history.isEmpty }

    public func keep() {
        guard !isFinished else { return }
        history.append(.keep)
        index += 1
    }

    public func delete() {
        guard let asset = current else { return }
        history.append(.delete)
        if !marked.contains(asset.id) { marked.append(asset.id) }
        index += 1
    }

    /// Reverses the last decision. Does nothing at the first item.
    public func undo() {
        guard let last = history.popLast() else { return }
        index -= 1
        if last == .delete { marked.removeAll { $0 == assets[index].id } }
    }

    /// Review: tapping a marked photo keeps it instead.
    public func unmark(_ id: String) {
        marked.removeAll { $0 == id }
    }

    /// Review: tapping a dimmed photo marks it again, back in album order.
    public func mark(_ id: String) {
        guard !marked.contains(id), let at = assets.firstIndex(where: { $0.id == id }) else { return }
        let order = Dictionary(uniqueKeysWithValues: assets.enumerated().map { ($1.id, $0) })
        let pos = marked.firstIndex { (order[$0] ?? 0) > at } ?? marked.endIndex
        marked.insert(id, at: pos)
    }

    /// Drops marks for photos that no longer exist.
    public func unmark(_ ids: [String]) {
        let drop = Set(ids)
        marked.removeAll { drop.contains($0) }
    }
}
