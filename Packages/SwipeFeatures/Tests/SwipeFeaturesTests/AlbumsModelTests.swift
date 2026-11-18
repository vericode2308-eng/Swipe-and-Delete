import Testing
import SwipeCore
@testable import SwipeFeatures

@MainActor
struct AlbumsModelTests {
    let albums = [
        Album(id: "r", title: "Recents", count: 12, kind: .smart, coverID: "x"),
        Album(id: "e", title: "Empty", count: 0, kind: .user),
        Album(id: "t", title: "Trip", count: 5, kind: .user, coverID: "y"),
    ]

    @Test func grantingAccessLoadsAlbums() async {
        let lib = FakePhotoLibrary(status: .notDetermined, statusAfterPrompt: .full, albums: albums)
        let m = AppModel(library: lib) {}
        await m.pillTapped()
        #expect(m.visibleAlbums.map(\.id) == ["r", "t"] && m.hasLoadedAlbums)
    }
    @Test func decliningLoadsNothing() async {
        let lib = FakePhotoLibrary(status: .notDetermined, statusAfterPrompt: .denied, albums: albums)
        let m = AppModel(library: lib) {}
        await m.pillTapped()
        #expect(m.albums.isEmpty && lib.albumLoadCount == 0)
    }
    @Test func refreshPicksUpChangedCounts() async {
        let lib = FakePhotoLibrary(status: .full, albums: albums)
        let m = AppModel(library: lib) {}
        await m.loadAlbums()
        lib.setAlbums([Album(id: "r", title: "Recents", count: 13, kind: .smart)])
        await m.refresh()
        #expect(m.albums.first?.count == 13)
    }
    @Test func revokedAccessClearsAlbums() async {
        let lib = FakePhotoLibrary(status: .full, albums: albums)
        let m = AppModel(library: lib) {}
        await m.loadAlbums()
        lib.set(.denied); await m.refresh()
        #expect(m.albums.isEmpty && m.showsWelcome && !m.hasLoadedAlbums)
    }
    @Test func filterChangesWhatShows() async {
        let m = AppModel(library: FakePhotoLibrary(status: .full, albums: albums)) {}
        await m.loadAlbums()
        m.filter = .mine
        #expect(m.visibleAlbums.map(\.id) == ["t"])
    }
    @Test func manageSelectionCallsThePicker() {
        var calls = 0
        let m = AppModel(library: FakePhotoLibrary(status: .limited), presentLimitedPicker: { calls += 1 }) {}
        m.manageLimitedSelection()
        #expect(calls == 1)
    }

    @Test func openingAnAlbumStartsAtTheFirstItemWithNoMarks() async {
        let lib = FakePhotoLibrary(status: .full, albums: albums)
        lib.setAssets([Asset(id: "1"), Asset(id: "2")], in: albums[0])
        let m = AppModel(library: lib) {}
        await m.open(albums[0])
        #expect(m.session?.index == 0 && m.session?.assets.count == 2 && m.session?.marked.isEmpty == true)
    }
    @Test func reopeningStartsFreshEvenAfterSwipes() async {
        let lib = FakePhotoLibrary(status: .full, albums: albums)
        lib.setAssets([Asset(id: "1"), Asset(id: "2")], in: albums[0])
        let m = AppModel(library: lib) {}
        await m.open(albums[0]); m.session?.delete()
        m.closeAlbum(); await m.open(albums[0])
        #expect(m.session?.index == 0 && m.session?.marked.isEmpty == true)
    }
    @Test func revokedAccessClosesTheSession() async {
        let lib = FakePhotoLibrary(status: .full, albums: albums)
        let m = AppModel(library: lib) {}
        await m.open(albums[0])
        lib.set(.denied); await m.refresh()
        #expect(m.session == nil)
    }
}
