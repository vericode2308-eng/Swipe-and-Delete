import Testing
@testable import SwipeFeatures

@Suite struct CoverFlowRingTests {
    let ring = CoverFlowRing()

    @Test func centreIsFlatFullSizeAndOpaque() {
        let p = ring.pose(at: 0, step: 300, cardWidth: 280)
        #expect(p.x == 0 && p.y == 0 && p.scale == 1 && p.opacity == 1)
    }

    @Test func sidesAreSymmetric() {
        let l = ring.pose(at: -1.4, step: 300, cardWidth: 280)
        let r = ring.pose(at: 1.4, step: 300, cardWidth: 280)
        #expect(l.x == -r.x)
        #expect(l.scale == r.scale && l.opacity == r.opacity && l.y == r.y)
    }

    @Test func farCardsShrinkAndFade() {
        let near = ring.pose(at: 1, step: 300, cardWidth: 280)
        let far = ring.pose(at: 2, step: 300, cardWidth: 280)
        #expect(far.scale < near.scale && far.opacity < near.opacity)
        #expect(far.x > near.x && far.y >= near.y && far.depth < near.depth)
    }

    @Test func frontPhotoIsBrightAndCastsShadowBehindAreDim() {
        let front = ring.pose(at: 0, step: 300, cardWidth: 280)
        let back = ring.pose(at: 1, step: 300, cardWidth: 280)
        #expect(front.dim == 0 && front.shadow == 1)
        #expect(back.dim == ring.maxDim && back.shadow == 0)
    }

    @Test func ringTurnsContinuously() {
        // A card at 0.5 is halfway between centre and neighbour poses.
        let half = ring.pose(at: 0.5, step: 300, cardWidth: 280)
        #expect(half.x == 150)
    }
}
