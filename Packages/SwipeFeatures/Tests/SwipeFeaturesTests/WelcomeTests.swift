import Testing
import SwipeCore
@testable import SwipeFeatures

@MainActor
struct AppModelTests {
    @Test func undeterminedShowsWelcomeAndAllowPill() {
        let m = AppModel(library: FakePhotoLibrary(status: .notDetermined)) {}
        #expect(m.showsWelcome && m.pillTitle == "Allow Photo Access")
    }
    @Test func grantingMovesOn() async {
        let lib = FakePhotoLibrary(status: .notDetermined, statusAfterPrompt: .full)
        let m = AppModel(library: lib) {}
        await m.pillTapped()
        #expect(!m.showsWelcome && lib.promptCount == 1)
    }
    @Test func limitedCountsAsGranted() async {
        let m = AppModel(library: FakePhotoLibrary(status: .notDetermined, statusAfterPrompt: .limited)) {}
        await m.pillTapped()
        #expect(!m.showsWelcome && m.status == .limited)
    }
    @Test func decliningStaysOnWelcomeAndOffersSettings() async {
        let m = AppModel(library: FakePhotoLibrary(status: .notDetermined, statusAfterPrompt: .denied)) {}
        await m.pillTapped()
        #expect(m.showsWelcome && m.pillTitle == "Open Settings")
    }
    @Test func deniedPillOpensSettingsWithoutPrompt() async {
        let lib = FakePhotoLibrary(status: .denied)
        var opened = 0
        let m = AppModel(library: lib) { opened += 1 }
        await m.pillTapped()
        #expect(opened == 1 && lib.promptCount == 0)
    }
    @Test func revokedWhileAwayReturnsToWelcome() async {
        let lib = FakePhotoLibrary(status: .full)
        let m = AppModel(library: lib) {}
        #expect(!m.showsWelcome)
        lib.set(.denied); await m.refresh()
        #expect(m.showsWelcome)
    }
    @Test func grantedInSettingsMovesOnAfterRefresh() async {
        let lib = FakePhotoLibrary(status: .denied)
        let m = AppModel(library: lib) {}
        lib.set(.limited); await m.refresh()
        #expect(!m.showsWelcome)
    }
}
