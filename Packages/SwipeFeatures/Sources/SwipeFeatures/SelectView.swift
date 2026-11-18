import SwiftUI
import SwipeCore
import SwipeUI

/// Pick many photos at once (D-24). Tapping a tile selects it for deletion;
/// "Review" hands the picks to the normal Review screen, so the single iOS
/// delete prompt and the free-plan limit work exactly as after swiping.
public struct SelectView: View {
    let model: AppModel
    let session: SwipeSession
    @Environment(\.colorScheme) private var scheme
    @State private var picked: Set<String> = []

    public init(model: AppModel, session: SwipeSession) { self.model = model; self.session = session }

    private var allIDs: [String] { session.assets.map(\.id) }
    private var allPicked: Bool { !allIDs.isEmpty && picked.count == allIDs.count }

    public var body: some View {
        let t = Theme.resolve(scheme)
        VStack(spacing: 14) {
            header(t)
            ScrollView {
                let cols = [GridItem(.adaptive(minimum: 96), spacing: 8)]
                LazyVGrid(columns: cols, spacing: 8) {
                    ForEach(Array(session.assets.enumerated()), id: \.element.id) { i, a in tile(a, i, t) }
                }
                .padding(10)
                .glass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
            footer(t)
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
        .background { AppCanvas() }
        .onAppear { picked = Set(session.marked) }
    }

    private func header(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            Button { apply(); model.endSelect() } label: {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: t.text)).frame(width: 44, height: 44).glass(in: Circle())
            }
            .accessibilityLabel("Back to swiping")
            VStack(alignment: .leading, spacing: 2) {
                Text("\(picked.count.formatted()) selected").font(.display(30))
                    .foregroundStyle(Color(hex: t.text)).lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Text("Tap photos to select them for deletion.").font(.footnote)
                    .foregroundStyle(Color(hex: t.textSecondary))
            }
            Spacer(minLength: 0)
            Button { picked = allPicked ? [] : Set(allIDs) } label: {
                Text(allPicked ? "Clear" : "Select all").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: t.text))
                    .padding(.horizontal, 14).frame(minHeight: 44).glass(in: Capsule())
            }
        }
        .padding(.top, 4)
    }

    private func tile(_ a: Asset, _ i: Int, _ t: Theme) -> some View {
        let on = picked.contains(a.id)
        return Button {
            if on { picked.remove(a.id) } else { picked.insert(a.id) }
        } label: {
            Color.clear.aspectRatio(1, contentMode: .fit)
                .overlay { PhotoImage(id: a.id, pointSize: CGSize(width: 120, height: 120), loader: model.images) }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    if on {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: Theme.blush, opacity: 0.35))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .strokeBorder(Color(hex: Theme.blush), lineWidth: 3))
                    }
                }
                .overlay(alignment: .topTrailing) {
                    Image(systemName: on ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(on ? Color(hex: Theme.blush) : Color.white.opacity(0.9))
                        .shadow(radius: 2).padding(6)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Photo \(i + 1) of \(session.assets.count), \(on ? "selected" : "not selected")")
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func footer(_ t: Theme) -> some View {
        Button { apply(); model.endSelect(); model.beginReview() } label: {
            Text(picked.isEmpty ? "Select photos to delete"
                                : "Review \(picked.count.formatted()) photo\(picked.count == 1 ? "" : "s")")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(hex: Theme.onFill))
                .padding(.vertical, 12).padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color(hex: Theme.blush), in: Capsule())
                .opacity(picked.isEmpty ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(picked.isEmpty)
    }

    /// The session's marks follow the picks.
    private func apply() {
        for id in allIDs { picked.contains(id) ? session.mark(id) : session.unmark(id) }
    }
}
