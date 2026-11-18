import SwiftUI
import SwipeCore
import SwipeUI

/// The celebration after a confirmed delete (~3 s). Everything is a pure
/// function of elapsed time, so a tap can jump to the end and Reduce Motion
/// can show the final state directly.
public struct DoneView: View {
    let model: AppModel
    let summary: DeletionSummary
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var start = Date()
    @State private var finished = false
    @State private var haptic = 0
    @State private var fadeIn = false

    private static let total = 3.0

    public init(model: AppModel, summary: DeletionSummary) { self.model = model; self.summary = summary }

    private func clamp(_ x: Double) -> Double { max(0, min(1, x)) }
    private func ease(_ x: Double) -> Double { let c = clamp(x); return c * c * (3 - 2 * c) }
    private func span(_ e: Double, _ a: Double, _ b: Double) -> Double { clamp((e - a) / (b - a)) }

    public var body: some View {
        let t = Theme.resolve(scheme)
        VStack(spacing: 0) {
            TimelineView(.animation(paused: finished || reduceMotion)) { ctx in
                let e = (finished || reduceMotion) ? 99 : ctx.date.timeIntervalSince(start)
                ScrollView {
                    VStack(spacing: 22) {
                        disc(e, t)
                        words(e, t)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(spoken)
                }
                .scrollBounceBehavior(.basedOnSize)
                .overlay { drift(e, t) }
            }
            .contentShape(Rectangle())
            .onTapGesture { finished = true }
            VStack(spacing: 12) {
                Text("Space returns once Recently Deleted empties. Changed your mind? Restore within 30 days.")
                    .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
                    .multilineTextAlignment(.center)
                PillButton("Back to Albums") { model.closeAlbum() }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
        .background { AppCanvas() }
        .opacity(reduceMotion && !fadeIn ? 0 : 1)
        .sensoryFeedback(.success, trigger: haptic)
        .task {
            if reduceMotion {
                haptic += 1
                withAnimation(.easeInOut(duration: 0.3)) { fadeIn = true }
                return
            }
            try? await Task.sleep(for: .seconds(1.9)); if !Task.isCancelled { haptic += 1 }
            try? await Task.sleep(for: .seconds(1.3)); if !Task.isCancelled { finished = true }
        }
    }

    // MARK: Parts

    private var hasSize: Bool { summary.freedBytes > 0 }

    private func disc(_ e: Double, _ t: Theme) -> some View {
        let p = ease(span(e, 0.5, 1.9))
        let shown = Int64(Double(summary.freedBytes) * p)
        let pop = span(e, 1.9, 2.25)
        let scale = pop == 0 ? 0 : 1 + 0.25 * sin(pop * .pi) * (1 - pop) * 2   // overshoot, settles at 1
        return ZStack {
            Circle().fill(Color(hex: Theme.sage, opacity: 0.25 * pop)).blur(radius: 28).frame(width: 240, height: 240)
            Circle().glass(in: Circle()).frame(width: 190, height: 190)
            Circle().stroke(Color(hex: t.text, opacity: 0.12), lineWidth: 8).frame(width: 190, height: 190)
            Circle().trim(from: 0, to: p)
                .stroke(AngularGradient(colors: [Color(hex: t.text, opacity: 0.55), Color(hex: Theme.sage), Color(hex: Theme.blush)],
                                        center: .center), style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90)).frame(width: 190, height: 190)
            VStack(spacing: 2) {
                Text(hasSize ? Formatting.size(shown) : (Int(Double(summary.deleted) * p)).formatted())
                    .font(.display(44)).monospacedDigit().foregroundStyle(Color(hex: t.text))
                Text(hasSize ? "CLEARED" : "DELETED").font(.caption.weight(.semibold)).tracking(1.4)
                    .foregroundStyle(Color(hex: t.textSecondary))
            }
            Image(systemName: "checkmark").font(.system(size: 20, weight: .bold))
                .foregroundStyle(Color(hex: Theme.onFill)).frame(width: 46, height: 46)
                .background(Circle().fill(Color(hex: Theme.sage)))
                .scaleEffect(scale).opacity(pop > 0 ? 1 : 0)
                .offset(x: 66, y: 66)
        }
        .frame(height: 220)
        .overlay { sparkles(e).frame(width: 900, height: 900).allowsHitTesting(false) }
        .accessibilityHidden(true)
    }

    private func words(_ e: Double, _ t: Theme) -> some View {
        let a = ease(span(e, 2.0, 2.4)), b = ease(span(e, 2.3, 2.7)), c = ease(span(e, 2.6, 3.0))
        let k = ease(span(e, 2.2, 3.0))
        let lighter = hasSize
            ? "\(summary.albumTitle) is about \(Formatting.size(summary.freedBytes)) lighter."
            : "\(summary.deleted.formatted()) photo\(summary.deleted == 1 ? "" : "s") removed from \(summary.albumTitle)."
        return VStack(spacing: 18) {
            VStack(spacing: 6) {
                Text("Beautifully done").font(.display(34, italic: true)).foregroundStyle(Color(hex: t.text))
                Text(lighter).foregroundStyle(Color(hex: t.textSecondary)).multilineTextAlignment(.center)
            }
            .opacity(a).offset(y: 10 * (1 - a))
            HStack(spacing: 0) {
                stat(Int(Double(summary.reviewed) * k), "REVIEWED", t)
                stat(Int(Double(summary.kept) * k), "KEPT", t)
                stat(Int(Double(summary.deleted) * k), "DELETED", t)
            }
            .padding(.vertical, 14)
            .glass(in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .opacity(b).offset(y: 10 * (1 - b))
            if hasSize {
                Text(Formatting.roomForPhotos(freedBytes: summary.freedBytes))
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16).padding(.vertical, 10).glass(in: Capsule())
                    .opacity(c).offset(y: 10 * (1 - c))
            }
        }
    }

    private func stat(_ n: Int, _ label: String, _ t: Theme) -> some View {
        VStack(spacing: 2) {
            Text(n.formatted()).font(.display(30)).monospacedDigit().foregroundStyle(Color(hex: t.text))
            Text(label).font(.caption2.weight(.semibold)).tracking(1.2).foregroundStyle(Color(hex: t.textSecondary))
        }
        .frame(maxWidth: .infinity)
    }

    /// The deleted photos drift to the middle, shrink and fade, 70 ms apart.
    private func drift(_ e: Double, _ t: Theme) -> some View {
        GeometryReader { geo in
            let target = CGPoint(x: geo.size.width / 2, y: 40 + 110)
            ForEach(Array(summary.thumbnails.enumerated()), id: \.offset) { i, img in
                let p = ease(span(e, Double(i) * 0.07, Double(i) * 0.07 + 0.9))
                let a = Double(i) / Double(max(1, summary.thumbnails.count)) * 2 * .pi
                let from = CGPoint(x: target.x + cos(a) * geo.size.width * 0.45,
                                   y: target.y + sin(a) * 200 + 60)
                Image(decorative: img, scale: 1).resizable().scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .scaleEffect(1 - 0.8 * p)
                    .opacity(p >= 1 ? 0 : 1 - p * p)
                    .position(x: from.x + (target.x - from.x) * p, y: from.y + (target.y - from.y) * p)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// 22 sparkles flung out from the disc once the check lands.
    private func sparkles(_ e: Double) -> some View {
        Canvas { ctx, size in
            let c = CGPoint(x: size.width / 2, y: size.height / 2)
            let life = span(e, 1.9, 3.0)
            guard life > 0, life < 1 else { return }
            for i in 0..<22 {
                let seed = Double(i)
                let angle = seed / 22 * 2 * .pi + sin(seed * 12.9898) * 0.3
                let speed = 150 + 130 * abs(sin(seed * 78.233))
                let r = 95 + speed * ease(life)
                let pt = CGPoint(x: c.x + cos(angle) * r, y: c.y + sin(angle) * r)
                let s = (4 + 4 * abs(sin(seed * 3.1))) * (1 - life)
                var star = Path()
                star.move(to: CGPoint(x: pt.x, y: pt.y - s * 1.6)); star.addLine(to: CGPoint(x: pt.x + s * 0.4, y: pt.y - s * 0.4))
                star.addLine(to: CGPoint(x: pt.x + s * 1.6, y: pt.y)); star.addLine(to: CGPoint(x: pt.x + s * 0.4, y: pt.y + s * 0.4))
                star.addLine(to: CGPoint(x: pt.x, y: pt.y + s * 1.6)); star.addLine(to: CGPoint(x: pt.x - s * 0.4, y: pt.y + s * 0.4))
                star.addLine(to: CGPoint(x: pt.x - s * 1.6, y: pt.y)); star.addLine(to: CGPoint(x: pt.x - s * 0.4, y: pt.y - s * 0.4))
                star.closeSubpath()
                ctx.fill(star, with: .color(Color(hex: i % 2 == 0 ? Theme.sage : Theme.blush, opacity: 1 - life)))
            }
        }
    }

    private var spoken: String {
        let tail = "\(summary.reviewed) reviewed, \(summary.kept) kept, \(summary.deleted) deleted."
        return hasSize ? "\(Formatting.spokenSize(summary.freedBytes)) cleared. \(tail)"
                       : "\(summary.deleted) photos deleted. \(tail)"
    }
}
