import SwiftUI

private struct GlassModifier<S: InsettableShape>: ViewModifier {
    let shape: S
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    func body(content: Content) -> some View {
        let t = Theme.resolve(scheme)
        content
            .background {
                if reduceTransparency {
                    shape.fill(Color(hex: t.glassSolid))
                } else {
                    shape.fill(.ultraThinMaterial)
                        .overlay(shape.fill(Color.white.opacity(t.glassFill)))
                        .saturation(1.7)
                }
            }
            .overlay(shape.strokeBorder(Color.white.opacity(t.glassEdge), lineWidth: 1))
            .overlay(
                shape.strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(t.glassHighlight), .clear],
                                   startPoint: .top, endPoint: .center), lineWidth: 1))
            .shadow(color: Color(hex: t.shadow, opacity: t.shadowOpacity), radius: 15, y: 10)
    }
}

public extension View {
    /// Frosted glass; solid under Reduce Transparency. Use only over colour or a photo.
    func glass<S: InsettableShape>(in shape: S) -> some View { modifier(GlassModifier(shape: shape)) }
}
