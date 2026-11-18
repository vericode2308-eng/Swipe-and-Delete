public enum AlbumFilter: CaseIterable, Sendable {
    case all, smart, mine
}

/// Which albums the grid shows. Pure, so the rules are host-tested.
public enum AlbumList {
    /// Empty albums are hidden; smart albums come before the user's own,
    /// each group keeping the order PhotoKit gave.
    public static func visible(_ albums: [Album], filter: AlbumFilter) -> [Album] {
        let shown = albums.filter { $0.count > 0 }
        switch filter {
        case .all: return shown.filter { $0.kind == .smart } + shown.filter { $0.kind == .user }
        case .smart: return shown.filter { $0.kind == .smart }
        case .mine: return shown.filter { $0.kind == .user }
        }
    }
}
