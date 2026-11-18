import SwiftUI
import SwipeCore
import SwipeUI

/// Every marked photo in one grid. Tapping a tile keeps it instead (R-07);
/// one button leads to the single iOS delete prompt (R-08).
public struct ReviewView: View {
    let model: AppModel
    let session: SwipeSession
    @Environment(\.colorScheme) private var scheme
    /// Tiles the user flipped back to "keep", shown dimmed until Delete or Back.
    @State private var spared: Set<String> = []
    @State private var shown: [String] = []

    public init(model: AppModel, session: SwipeSession) { self.model = model; self.session = session }

    private var toDelete: [String] { shown.filter { !spared.contains($0) } }
    private var allowed: Int { model.deletableCount(marked: toDelete.count) }

    public var body: some View {
        let t = Theme.resolve(scheme)
        VStack(spacing: 14) {
            header(t)
            ScrollView {
                VStack(spacing: 14) {
                    grid(t)
                    note(t)
                    if fullyMarked > 0 { setsNote(t) }
                }
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)
            footer(t)
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
        .background { AppCanvas() }
        .onAppear { shown = session.marked }
        .onChange(of: model.reviewBytesKey) { Task { await model.refreshReviewBytes() } }
        .sheet(isPresented: Binding(get: { model.showsPaywall }, set: { if !$0 { model.dismissPaywall() } })) {
            PaywallSheet(model: model, marked: toDelete.count)
        }
    }

    // MARK: Pieces

    private func header(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            Button { leave() } label: {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: t.text)).frame(width: 44, height: 44).glass(in: Circle())
            }
            .accessibilityLabel("Back to swiping")
            VStack(alignment: .leading, spacing: 2) {
                Text("\(toDelete.count.formatted()) to delete").font(.display(30))
                    .foregroundStyle(Color(hex: t.text)).lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Text("Tap a photo to keep it instead.").font(.footnote)
                    .foregroundStyle(Color(hex: t.textSecondary))
            }
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private func grid(_ t: Theme) -> some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
        return LazyVGrid(columns: cols, spacing: 8) {
            ForEach(shown, id: \.self) { id in tile(id, t) }
        }
        .padding(10)
        .glass(in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func tile(_ id: String, _ t: Theme) -> some View {
        let off = spared.contains(id)
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                if off { spared.remove(id) } else { spared.insert(id) }
            }
        } label: {
            Color.clear.aspectRatio(1, contentMode: .fit)
                .overlay { PhotoImage(id: id, pointSize: CGSize(width: 120, height: 120), loader: model.images) }
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .opacity(off ? 0.35 : 1)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: off ? "checkmark" : "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color(hex: off ? t.keepTint : t.deleteTint))
                        .frame(width: 26, height: 26).glass(in: Circle()).padding(5)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Photo \((shown.firstIndex(of: id) ?? 0) + 1) of \(shown.count), \(off ? "will be kept" : "will be deleted")")
        .accessibilityHint(off ? "Double tap to delete it again" : "Double tap to keep it instead")
    }

    /// Duplicates only: sets whose every copy is still going to be deleted.
    private var fullyMarked: Int {
        let going = Set(toDelete)
        return session.sets.filter { !$0.isEmpty && $0.allSatisfy(going.contains) }.count
    }

    private func setsNote(_ t: Theme) -> some View {
        let n = fullyMarked
        return Text(n == 1 ? "All copies of 1 set are marked. Tap one to keep it."
                           : "All copies of \(n) sets are marked. Tap one to keep it.")
            .font(.footnote.weight(.semibold)).foregroundStyle(Color(hex: t.text))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func note(_ t: Theme) -> some View {
        Text("Deleted photos stay in Recently Deleted for 30 days. With iCloud Photos on, they're removed from your other devices too.")
            .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func footer(_ t: Theme) -> some View {
        VStack(spacing: 10) {
            if let left = model.freeRemaining {
                Text("Free plan: \(DeletionAllowance.dailyFree) deletions a day · \(left.formatted()) left today")
                    .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
                    .multilineTextAlignment(.center)
            }
            if let message = model.deleteMessage {
                Text(message).font(.footnote.weight(.semibold)).foregroundStyle(Color(hex: t.deleteTint))
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.updatesFrequently)
            }
            if toDelete.isEmpty {
                PillButton("Back to Albums") { model.closeAlbum() }
            } else {
                Button { Task { await commitDelete() } } label: {
                    HStack(spacing: 8) {
                        if model.isDeleting { ProgressView().tint(Color(hex: Theme.onFill)) }
                        Text(deleteTitle).font(.body.weight(.semibold)).multilineTextAlignment(.center)
                    }
                    .foregroundStyle(Color(hex: Theme.onFill))
                    .padding(.vertical, 12).padding(.horizontal, 20)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color(hex: Theme.blush), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(model.isDeleting)
            }
        }
    }

    private var deleteTitle: String {
        let n = toDelete.count
        return "Delete \(n.formatted()) photo\(n == 1 ? "" : "s")"
    }

    // MARK: Actions

    /// Marks follow the tiles: spared photos are unmarked, so cancelling the iOS prompt
    /// leaves exactly what the grid shows.
    private func syncSession() {
        for id in shown { spared.contains(id) ? session.unmark(id) : session.mark(id) }
    }

    private func commitDelete() async {
        syncSession()
        await model.confirmDelete()
    }

    private func leave() { syncSession(); model.endReview() }
}
