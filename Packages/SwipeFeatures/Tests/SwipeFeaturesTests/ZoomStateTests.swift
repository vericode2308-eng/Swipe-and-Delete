import CoreGraphics
import Testing
@testable import SwipeFeatures

struct ZoomStateTests {
    let frame = CGSize(width: 400, height: 800)
    let content = CGSize(width: 400, height: 300)

    @Test func pinchIsLimitedToOneAndFive() {
        var z = ZoomState()
        z.pinch(base: 1, factor: 0.4, content: content, in: frame); #expect(z.scale == 1)
        z.pinch(base: 1, factor: 20, content: content, in: frame); #expect(z.scale == ZoomState.maxScale)
    }
    @Test func cannotPanUnlessZoomed() {
        var z = ZoomState()
        z.pan(base: .zero, translation: CGSize(width: 90, height: 90), content: content, in: frame)
        #expect(z.offset == .zero)
    }
    @Test func panStopsAtTheEdgeOfThePicture() {
        var z = ZoomState()
        z.pinch(base: 1, factor: 2, content: content, in: frame)       // 800 wide, 600 tall
        z.pan(base: .zero, translation: CGSize(width: 900, height: 900), content: content, in: frame)
        #expect(z.offset.width == 200)                                  // (800-400)/2
        #expect(z.offset.height == 0)                                   // 600 < 800: stays centred
    }
    @Test func doubleTapTogglesAndResetsOffset() {
        var z = ZoomState()
        z.toggle(); #expect(z.scale == 2.5 && z.isZoomed)
        z.toggle(); #expect(z.scale == 1 && z.offset == .zero)
    }
    @Test func zoomingOutRecentres() {
        var z = ZoomState()
        z.pinch(base: 1, factor: 3, content: content, in: frame)
        z.pan(base: .zero, translation: CGSize(width: 400, height: 0), content: content, in: frame)
        z.pinch(base: 1, factor: 1, content: content, in: frame)
        #expect(z.offset == .zero)
    }
}
