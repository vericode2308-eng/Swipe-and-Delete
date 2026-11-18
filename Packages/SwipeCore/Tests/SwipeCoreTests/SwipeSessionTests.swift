import Testing
@testable import SwipeCore

@MainActor
struct SwipeSessionTests {
    let album = Album(id: "a", title: "All Photos", count: 4)
    func make() -> SwipeSession {
        SwipeSession(album: album, assets: ["1", "2", "3", "4"].map { Asset(id: $0) })
    }

    @Test func undoAfterDeleteRemovesMark() {
        let s = make()
        s.keep(); s.delete()
        #expect(s.marked == ["2"])
        s.undo()
        #expect(s.marked.isEmpty && s.index == 1)
    }
    @Test func undoAtStartDoesNothing() {
        let s = make()
        s.undo()
        #expect(s.index == 0 && !s.canUndo)
    }
    @Test func undoRepeatsBackToFirst() {
        let s = make()
        s.keep(); s.delete(); s.keep()
        s.undo(); s.undo(); s.undo(); s.undo()
        #expect(s.index == 0 && s.marked.isEmpty)
    }
    @Test func newSessionStartsFresh() {
        let s1 = make(); s1.delete(); s1.keep()
        let s2 = make()
        #expect(s2.index == 0 && s2.marked.isEmpty && s2.keptCount == 0)
    }
    @Test func unmarkRemovesOnlyThatIdKeepingOrder() {
        let s = make()
        s.delete(); s.delete(); s.delete()
        s.unmark("2")
        #expect(s.marked == ["1", "3"])
    }
    @Test func finishesAndStops() {
        let s = make()
        for _ in 0..<6 { s.keep() }
        #expect(s.isFinished && s.index == 4 && s.current == nil)
    }
}

@MainActor
struct ReviewMarkTests {
    func make() -> SwipeSession {
        let s = SwipeSession(album: Album(id: "a", title: "A", count: 4), assets: ["1", "2", "3", "4"].map { Asset(id: $0) })
        s.delete(); s.keep(); s.delete(); s.delete()
        return s
    }
    @Test func unmarkThenMarkRestoresAlbumOrder() {
        let s = make()
        #expect(s.marked == ["1", "3", "4"])
        s.unmark("3"); #expect(s.marked == ["1", "4"])
        s.mark("3"); #expect(s.marked == ["1", "3", "4"])
    }
    @Test func markIgnoresDuplicatesAndStrangers() {
        let s = make()
        s.mark("1"); s.mark("zzz")
        #expect(s.marked == ["1", "3", "4"])
    }
    @Test func unmarkManyDropsOnlyThose() {
        let s = make()
        s.unmark(["1", "4"])
        #expect(s.marked == ["3"])
    }
}
