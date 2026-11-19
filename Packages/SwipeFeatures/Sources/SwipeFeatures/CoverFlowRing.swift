import CoreGraphics

/// Geometry of a Cover Flow style ring: where a card sits, and how it is scaled and faded (cards always face front, never bent),
/// given its signed distance `r` from the centre in card steps (fractional while the ring turns).
/// Pure maths, so it can be tested and reused by any carousel view.
struct CoverFlowRing: Equatable, Sendable {
    /// Scale lost per card of distance, never below `minScale`.
    var scaleFalloff: CGFloat = 0.26
    var minScale: CGFloat = 0.5
    /// Opacity lost per card of distance beyond half a card.
    var opacityFalloff: Double = 0.2
    /// Vertical drop per card of distance, in points.
    var drop: CGFloat = 0
    /// Gap between cards beyond the first neighbour, as a fraction of the card width.
    var farSpacing: CGFloat = 0.14
    /// Darkening of photos behind the front one, so it reads as a separate photo (no border).
    var maxDim: Double = 0.4
    /// Cards drawn on each side of the centre.
    var visible: Int = 2

    struct Pose: Equatable {
        var x: CGFloat
        var y: CGFloat
        var scale: CGFloat
        var opacity: Double
        var dim: Double           // 0 = front photo, up to `maxDim` for those behind
        var shadow: Double        // shadow strength; only the front photo casts one
        var depth: Double         // higher = closer to the viewer (z-order)
    }

    func pose(at r: CGFloat, step: CGFloat, cardWidth: CGFloat) -> Pose {
        let a = abs(r)
        let sign: CGFloat = r < 0 ? -1 : 1
        let x = sign * (min(a, 1) * step + max(a - 1, 0) * cardWidth * farSpacing)
        return Pose(
            x: x,
            y: min(a, 3) * drop,
            scale: max(minScale, 1 - min(a, 3) * scaleFalloff),
            opacity: max(0, 1 - Double(max(a - 0.5, 0)) * opacityFalloff),
            dim: min(Double(a), 1) * maxDim,
            shadow: max(0, 1 - Double(a)),
            depth: -Double(a))
    }
}
