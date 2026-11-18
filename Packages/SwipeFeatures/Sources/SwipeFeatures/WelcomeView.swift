import SwiftUI
import SwipeCore
import SwipeUI

public struct WelcomeView: View {
    public static let title = "Lighter"
    let model: AppModel
    @Environment(\.colorScheme) private var scheme

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        let t = Theme.resolve(scheme)
        GeometryReader { geo in
        ScrollView {
            VStack(spacing: 0) {
                // Full-bleed: extend the drawing up under the status bar.
                WelcomeIllustration()
                    .frame(height: 260 + geo.safeAreaInsets.top)
                    .mask(LinearGradient(colors: [.black, .black, .clear],
                                         startPoint: .top, endPoint: .bottom))
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(Self.title).font(.display(64, italic: true))
                            .foregroundStyle(Color(hex: t.text))
                            .accessibilityAddTraits(.isHeader)
                        Text("A calmer camera roll, one photo at a time.")
                            .font(.body).multilineTextAlignment(.center)
                            .foregroundStyle(Color(hex: t.textSecondary))
                    }
                    VStack(spacing: 8) {
                        HintRow(symbol: "xmark", tint: scheme == .dark ? 0xF2B8A8 : 0xA4472F,
                                text: "Swipe left to delete", arrowLeft: true)
                        HintRow(symbol: "checkmark", tint: scheme == .dark ? 0xA9DCCD : 0x286B59,
                                text: "Swipe right to keep", arrowLeft: false)
                    }
                    .padding(12)
                    .glass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))

                    VStack(spacing: 12) {
                        if model.status == .denied {
                            Text("Lighter needs Photos access to show your photos. Turn it on in Settings.")
                                .font(.footnote).multilineTextAlignment(.center)
                                .foregroundStyle(Color(hex: t.textSecondary))
                        }
                        PillButton(model.pillTitle) { Task { await model.pillTapped() } }
                        Text("Your photos never leave this iPhone.")
                            .font(.footnote)
                            .foregroundStyle(Color(hex: t.textSecondary))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollClipDisabled()
        .ignoresSafeArea(edges: .top)
        }
        .background { AppCanvas() }
    }
}

private struct HintRow: View {
    let symbol: String
    let tint: UInt32
    let text: String
    let arrowLeft: Bool
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.resolve(scheme)
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.body.weight(.bold))
                .foregroundStyle(Color(hex: tint))
                .frame(width: 44, height: 44)
                .glass(in: Circle())
                .accessibilityHidden(true)
            Text(text).font(.body.weight(.medium)).foregroundStyle(Color(hex: t.text))
            Spacer(minLength: 0)
            Image(systemName: arrowLeft ? "arrow.left" : "arrow.right")
                .foregroundStyle(Color(hex: t.textSecondary))
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// Landscape drawn in code: sky, sun and layered hills.
private struct WelcomeIllustration: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        let dark = scheme == .dark
        Canvas { ctx, size in
            let sky = Gradient(colors: dark ? [Color(hex: 0x3F4E6B), Color(hex: 0x9A6F80)]
                                            : [Color(hex: 0xA9BCDA), Color(hex: 0xF0D3D8)])
            ctx.fill(Path(CGRect(origin: .zero, size: size)),
                     with: .linearGradient(sky, startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
            let sun = CGRect(x: size.width * 0.62, y: size.height * 0.28, width: 64, height: 64)
            ctx.fill(Path(ellipseIn: sun), with: .color(.white.opacity(dark ? 0.55 : 0.85)))
            func hills(_ base: CGFloat, _ amp: CGFloat, _ phase: CGFloat, _ color: Color) {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: size.height))
                for x in stride(from: 0, through: size.width, by: 8) {
                    let y = base + amp * sin(x / size.width * 2 * .pi + phase)
                    p.addLine(to: CGPoint(x: x, y: y))
                }
                p.addLine(to: CGPoint(x: size.width, y: size.height))
                ctx.fill(p, with: .color(color))
            }
            hills(size.height * 0.62, 14, 0.5, Color(hex: dark ? 0x3F6B66 : 0xB7D6CF).opacity(0.9))
            hills(size.height * 0.78, 12, 2.2, Color(hex: dark ? 0x2E4A52 : 0x9FC4BC))
        }
        .accessibilityHidden(true)
    }
}
