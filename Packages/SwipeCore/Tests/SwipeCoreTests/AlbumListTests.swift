import Testing
@testable import SwipeCore

struct AlbumListTests {
    let all = [
        Album(id: "a", title: "Mine A", count: 3, kind: .user),
        Album(id: "b", title: "Recents", count: 10, kind: .smart),
        Album(id: "c", title: "Empty", count: 0, kind: .user),
        Album(id: "d", title: "Empty smart", count: 0, kind: .smart),
        Album(id: "e", title: "Screenshots", count: 4, kind: .smart),
    ]
    @Test func hidesEmptyAlbums() {
        #expect(!AlbumList.visible(all, filter: .all).contains { $0.count == 0 })
    }
    @Test func smartAlbumsComeFirstInGivenOrder() {
        #expect(AlbumList.visible(all, filter: .all).map(\.id) == ["b", "e", "a"])
    }
    @Test func filtersBySmartAndMine() {
        #expect(AlbumList.visible(all, filter: .smart).map(\.id) == ["b", "e"])
        #expect(AlbumList.visible(all, filter: .mine).map(\.id) == ["a"])
    }
    @Test func noAlbumsGivesNothing() {
        #expect(AlbumList.visible([], filter: .all).isEmpty)
    }
}
