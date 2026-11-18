import Testing
import Foundation
@testable import SwipeCore

struct FormattingAndReviewTests {
    @Test func sizes() {
        #expect(Formatting.size(0) == "0 KB")
        #expect(Formatting.size(999_000_000) == "999 MB")
        #expect(Formatting.size(1_200_000_000) == "1.2 GB")
        #expect(Formatting.size(2_000_000_000) == "2 GB")
        #expect(Formatting.size(999_900_000) == "1 GB")
    }
    @Test func roomForPhotos() {
        #expect(Formatting.roomForPhotos(freedBytes: 0) == "Room for about 0 more photos")
        #expect(Formatting.roomForPhotos(freedBytes: 3_000_000) == "Room for about 1 more photo")
        #expect(Formatting.roomForPhotos(freedBytes: 1_200_000_000) == "Room for about 400 more photos")
        #expect(Formatting.roomForPhotos(freedBytes: 3_600_000_000) == "Room for about 1,200 more photos")
    }

    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "UTC")!; return c }
    func day(_ d: Int) -> Date { cal.date(from: DateComponents(year: 2026, month: 11, day: d, hour: 12))! }

    @Test func notBeforeThirdAlbumOnSecondDay() {
        var p = ReviewPromptPolicy()
        p.recordCompletedAlbum(now: day(1), calendar: cal)
        p.recordCompletedAlbum(now: day(1), calendar: cal)
        p.recordCompletedAlbum(now: day(1), calendar: cal)
        #expect(!p.shouldPrompt(after: .deleteSucceeded, now: day(1), calendar: cal)) // one day only
        p.recordCompletedAlbum(now: day(2), calendar: cal)
        #expect(p.shouldPrompt(after: .deleteSucceeded, now: day(2), calendar: cal))
    }
    @Test func twoAlbumsAreNotEnough() {
        var p = ReviewPromptPolicy()
        p.recordCompletedAlbum(now: day(1), calendar: cal)
        p.recordCompletedAlbum(now: day(2), calendar: cal)
        #expect(!p.shouldPrompt(after: .deleteSucceeded, now: day(2), calendar: cal))
    }
    @Test func neverAfterErrorPurchaseOrLaunch() {
        var p = ReviewPromptPolicy()
        for d in [1, 2, 3] { p.recordCompletedAlbum(now: day(d), calendar: cal) }
        #expect(p.shouldPrompt(after: .deleteSucceeded, now: day(3), calendar: cal))
        #expect(!p.shouldPrompt(after: .deleteFailed, now: day(3), calendar: cal))
        #expect(!p.shouldPrompt(after: .purchased, now: day(3), calendar: cal))
        #expect(!p.shouldPrompt(after: .launched, now: day(3), calendar: cal))
    }
    @Test func onceEvery120Days() {
        var p = ReviewPromptPolicy()
        for d in [1, 2, 3] { p.recordCompletedAlbum(now: day(d), calendar: cal) }
        p.markPrompted(now: day(3))
        #expect(!p.shouldPrompt(after: .deleteSucceeded, now: day(3), calendar: cal))
        let later = cal.date(byAdding: .day, value: 119, to: day(3))!
        let after = cal.date(byAdding: .day, value: 120, to: day(3))!
        #expect(!p.shouldPrompt(after: .deleteSucceeded, now: later, calendar: cal))
        #expect(p.shouldPrompt(after: .deleteSucceeded, now: after, calendar: cal))
    }
    @Test func storeRoundTrips() {
        let d = UserDefaults(suiteName: "lighter.test.review")!
        d.removePersistentDomain(forName: "lighter.test.review")
        let store = ReviewPromptStore(defaults: d)
        var p = store.load()
        p.recordCompletedAlbum(now: day(1), calendar: cal)
        store.save(p)
        #expect(store.load() == p)
    }
}

struct SpokenSizeTests {
    @Test func spokenUnits() {
        #expect(Formatting.spokenSize(1_200_000_000) == "1.2 gigabytes")
        #expect(Formatting.spokenSize(1_000_000_000) == "1 gigabyte")
        #expect(Formatting.spokenSize(48_000_000) == "48 megabytes")
    }
}

@Suite struct ClockTests {
    @Test func formats() {
        #expect(Formatting.clock(14) == "0:14")
        #expect(Formatting.clock(65.4) == "1:05")
        #expect(Formatting.clock(3723) == "1:02:03")
        #expect(Formatting.clock(0) == "0:00")
        #expect(Formatting.clock(-3) == "0:00")
    }
}
