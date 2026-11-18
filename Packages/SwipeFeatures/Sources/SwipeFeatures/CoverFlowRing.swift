import CoreGraphics

/// Geometry of a Cover Flow style ring: where a card sits, and how it is turned, scaled and faded,
/// given its signed distance `r` from the centre in card steps (fractional while the ring turns).
/// Pure maths, so it can be tested and reused by any carousel view.
struct CoverFlowRing: Equatable, Sendable {
    /// Y-axis turn per card of distance, in degrees, capped at `maxTilt`.
    var tilt: Double = 30
    var maxTilt: Double = 60
    var perspective: CGFloat = 0.2
    /// Scale lost per card of distance, never below `minScale`.
    var scaleFalloff: CGFloat = 0.06
    var minScale: CGFloat = 0.7
    /// Opacity lost per card of distance beyond half a card.
    var opacityFalloff: Double = 0.3
    /// Vertical drop per card of distance, in points.
    var drop: CGFloat = 5
    /// Gap between cards beyond the first neighbour, as a fraction of the card width.
    var farSpacing: CGFloat = 0.18
    /// Cards drawn on each side of the centre.
    var visible: Int = 2

    struct Pose: Equatable {
        var x: CGFloat
        var y: CGFloat
        var rotation: Double      // degrees about the vertical axis
        var scale: CGFloat
        var opacity: Double
        var depth: Double         // higher = closer to the viewer (z-order)
    }

    func pose(at r: CGFloat, step: CGFloat, cardWidth: CGFloat) -> Pose {
        let a = abs(r)
        let sign: CGFloat = r < 0 ? -1 : 1
        let x = sign * (min(a, 1) * step + max(a - 1, 0) * cardWidth * farSpacing)
        let turn = min(Double(a) * tilt, maxTilt)
        return Pose(
            x: x,
            y: min(a, 3) * drop,
            rotation: -Double(sign) * turn,
            scale: max(minScale, 1 - min(a, 3) * scaleFalloff),
            opacity: max(0, 1 - Double(max(a - 0.5, 0)) * opacityFalloff),
            depth: -Double(a))
    }
}
