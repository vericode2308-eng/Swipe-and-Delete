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

    public init(album: Album, assets: [Asset]) {
        self.album = album
        self.assets = assets
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
}
