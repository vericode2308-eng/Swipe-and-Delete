import Testing
import Foundation
@testable import SwipeCore

struct AllowanceAndAccessTests {
    var cal: Calendar { var c = Calendar(identifier: .gregorian); c.timeZone = TimeZone(identifier: "Europe/London")!; return c }
    func date(_ d: Int, _ h: Int = 12, _ m: Int = 0, tz: String = "Europe/London") -> Date {
        var c = DateComponents(); c.year = 2026; c.month = 11; c.day = d; c.hour = h; c.minute = m
        var cal = Calendar(identifier: .gregorian); cal.timeZone = TimeZone(identifier: tz)!
        return cal.date(from: c)!
    }

    @Test func freshDayHasFifty() {
        #expect(DeletionAllowance().remaining(now: date(18), calendar: cal) == 50)
    }
    @Test func recordingThirtyLeavesTwenty() {
        var a = DeletionAllowance()
        a.record(30, now: date(18), calendar: cal)
        #expect(a.remaining(now: date(18, 23, 59), calendar: cal) == 20)
    }
    @Test func resetsAfterLocalMidnight() {
        var a = DeletionAllowance()
        a.record(50, now: date(18, 23, 59), calendar: cal)
        #expect(a.remaining(now: date(18, 23, 59), calendar: cal) == 0)
        #expect(a.remaining(now: date(19, 0, 1), calendar: cal) == 50)
    }
    @Test func neverNegative() {
        var a = DeletionAllowance()
        a.record(80, now: date(18), calendar: cal)
        #expect(a.remaining(now: date(18), calendar: cal) == 0)
    }
    @Test func timeZoneChangeNeverNegativeOrAbove50() {
        var a = DeletionAllowance()
        a.record(30, now: date(18, 22), calendar: cal)
        var tokyo = Calendar(identifier: .gregorian); tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let r = a.remaining(now: date(18, 22), calendar: tokyo)
        #expect((0...50).contains(r))
    }
    @Test func storeRoundTrips() {
        let d = UserDefaults(suiteName: "lighter.test.allowance")!
        d.removePersistentDomain(forName: "lighter.test.allowance")
        let store = AllowanceStore(defaults: d)
        var a = store.load()
        a.record(12, now: date(18), calendar: cal)
        store.save(a)
        #expect(store.load().remaining(now: date(18), calendar: cal) == 38)
    }
    @Test func freeWithSeventyTwoMarked() {
        let p = AccessPolicy(isPro: false, allowance: DeletionAllowance())
        #expect(p.deletable(marked: 72, now: date(18), calendar: cal) == 50)
        #expect(p.needsPaywall(marked: 72, now: date(18), calendar: cal))
        #expect(!p.needsPaywall(marked: 50, now: date(18), calendar: cal))
    }
    @Test func partlyUsedDay() {
        var a = DeletionAllowance(); a.record(30, now: date(18), calendar: cal)
        let p = AccessPolicy(isPro: false, allowance: a)
        #expect(p.deletable(marked: 72, now: date(18), calendar: cal) == 20)
    }
    @Test func proDeletesAll() {
        let p = AccessPolicy(isPro: true, allowance: DeletionAllowance())
        #expect(p.deletable(marked: 72, now: date(18), calendar: cal) == 72)
        #expect(!p.needsPaywall(marked: 72, now: date(18), calendar: cal))
    }
}
