import SwiftUI
import SwipeCore
import SwipeUI

/// "Quick clean-up" (D-18): one glass panel with Duplicates, Pages & Things and From WhatsApp.
struct QuickCleanupPanel: View {
    let model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let t = Theme.resolve(scheme)
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick clean-up").font(.display(28)).foregroundStyle(Color(hex: t.text))
                .accessibilityAddTraits(.isHeader)
            Text("Found on this iPhone").font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
            VStack(spacing: 0) {
                row(.duplicates, icon: "square.on.square", tint: t.blobs[0],
                    detail: "Same or near-identical shots", t)
                divider(t)
                row(.pagesAndThings, icon: "doc.text", tint: Theme.blush,
                    detail: "Notes, documents, no people", t)
                if model.whatsAppAlbum != nil {
                    divider(t)
                    row(.whatsApp, icon: "bubble.left.and.bubble.right", tint: Theme.sage,
                        detail: "Saved from your chats", t)
                }
            }
            .glass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .frame(maxWidth: 560, alignment: .leading)   // don't stretch across a wide window (iPhone Duo open)
    }

    private func divider(_ t: Theme) -> some View {
        Rectangle().fill(Color(hex: t.textSecondary, opacity: 0.18)).frame(height: 0.5).padding(.leading, 70)
    }

    private func scanning(_ f: CleanupFilter) -> Bool { f != .whatsApp && model.cleanup.isRunning }

    private func countText(_ f: CleanupFilter) -> String {
        let n = model.count(for: f)
        if f == .duplicates { return "\(n.formatted()) in \(model.cleanup.duplicateSets.count.formatted()) sets" }
        return n.formatted()
    }

    private func detail(_ f: CleanupFilter, _ base: String) -> String {
        scanning(f) ? "Checking \(model.cleanup.checked.formatted()) of \(model.cleanup.total.formatted())" : base
    }

    private func row(_ f: CleanupFilter, icon: String, tint: UInt32, detail base: String, _ t: Theme) -> some View {
        let n = model.count(for: f)
        let none = n == 0 && !scanning(f)
        return Button { Task { await model.openFilter(f) } } label: {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: t.text))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(Color(hex: tint, opacity: 0.45)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(f.title).font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                    Text(none ? "None found" : detail(f, base)).font(.footnote)
                        .foregroundStyle(Color(hex: t.textSecondary))
                }
                Spacer(minLength: 8)
                if !none && n > 0 {
                    Text(countText(f)).font(.footnote.weight(.semibold)).monospacedDigit()
                        .foregroundStyle(Color(hex: t.text))
                    Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                        .foregroundStyle(Color(hex: t.textSecondary))
                }
            }
            .padding(.horizontal, 14).frame(minHeight: 58)
            .overlay(alignment: .bottom) { hairline(f, t) }
            .opacity(none ? 0.75 : 1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(n == 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label(f, n, none))
        .accessibilityAddTraits(n > 0 ? .isButton : [])
    }

    /// A 2 pt progress line under a row while the scan runs; text only with Reduce Motion.
    @ViewBuilder private func hairline(_ f: CleanupFilter, _ t: Theme) -> some View {
        if scanning(f), !reduceMotion, model.cleanup.total > 0 {
            GeometryReader { g in
                Capsule().fill(Color(hex: t.text, opacity: 0.5))
                    .frame(width: g.size.width * CGFloat(model.cleanup.checked) / CGFloat(model.cleanup.total), height: 2)
            }
            .frame(height: 2).padding(.horizontal, 14)
        }
    }

    private func label(_ f: CleanupFilter, _ n: Int, _ none: Bool) -> String {
        if scanning(f) {
            return "\(f.title), checking photos, \(model.cleanup.checked) of \(model.cleanup.total)"
                + (n > 0 ? ", \(n) found so far" : "")
        }
        if none { return "\(f.title), none found" }
        if f == .duplicates { return "\(f.title), \(n) photos in \(model.cleanup.duplicateSets.count) sets" }
        return "\(f.title), \(n) photos"
    }
}
