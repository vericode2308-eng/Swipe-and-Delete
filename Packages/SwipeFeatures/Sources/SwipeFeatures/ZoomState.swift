import CoreGraphics

/// Pinch and double-tap zoom for the full-screen photo. Pure, so the limits are tested.
struct ZoomState: Equatable {
    static let maxScale: CGFloat = 5
    private(set) var scale: CGFloat = 1
    private(set) var offset: CGSize = .zero

    var isZoomed: Bool { scale > 1.01 }

    /// `factor` is the pinch's cumulative magnification applied on top of `base`.
    mutating func pinch(base: CGFloat, factor: CGFloat, content: CGSize, in frame: CGSize) {
        scale = min(Self.maxScale, max(1, base * factor))
        offset = Self.clamp(offset, scale: scale, content: content, frame: frame)
    }

    mutating func pan(base: CGSize, translation: CGSize, content: CGSize, in frame: CGSize) {
        guard isZoomed else { offset = .zero; return }
        offset = Self.clamp(CGSize(width: base.width + translation.width, height: base.height + translation.height),
                            scale: scale, content: content, frame: frame)
    }

    /// Double tap: back to 1, or in to 2.5×.
    mutating func toggle() { scale = isZoomed ? 1 : 2.5; if !isZoomed { offset = .zero } }

    mutating func reset() { scale = 1; offset = .zero }

    /// The picture can't be dragged past the point where its edge leaves the screen edge.
    static func clamp(_ o: CGSize, scale: CGFloat, content: CGSize, frame: CGSize) -> CGSize {
        let maxX = max(0, (content.width * scale - frame.width) / 2)
        let maxY = max(0, (content.height * scale - frame.height) / 2)
        return CGSize(width: min(maxX, max(-maxX, o.width)), height: min(maxY, max(-maxY, o.height)))
    }
}
