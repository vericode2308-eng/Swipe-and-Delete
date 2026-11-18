import SwiftUI
import SwipeCore
import SwipeUI

private enum Side { case left, right }   // left = delete, right = keep

public struct SwipeView: View {
    let model: AppModel
    let session: SwipeSession

    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.displayScale) private var displayScale
    @State private var dragX: CGFloat = 0
    @State private var busy = false
    @State private var commitTick = 0
    @State private var pendingAlbum: Album?
    @State private var width: CGFloat = 393   // last measured screen width, for prefetch sizing

    private let spring = Animation.spring(response: 0.3, dampingFraction: 0.8)
    private let gap: CGFloat = 12

    public init(model: AppModel, session: SwipeSession) {
        self.model = model; self.session = session
    }

    public var body: some View {
        let t = Theme.resolve(scheme)
        GeometryReader { geo in
            content(t, screenW: geo.size.width)
                .onAppear { width = geo.size.width }
        }
            .background { backdrop(t) }
            .sensoryFeedback(.impact(weight: .light), trigger: commitTick)
            .onChange(of: session.index) { prefetch() }
            .onAppear { prefetch() }
            .confirmationDialog("Discard \(session.marked.count) marks?", isPresented: Binding(
                get: { pendingAlbum != nil }, set: { if !$0 { pendingAlbum = nil } }),
                titleVisibility: .visible) {
                Button("Discard marks", role: .destructive) {
                    if let a = pendingAlbum { Task { await model.open(a) } }
                    pendingAlbum = nil
                }
                Button("Keep swiping", role: .cancel) { pendingAlbum = nil }
            }
    }

    private func content(_ t: Theme, screenW: CGFloat) -> some View {
        VStack(spacing: 14) {
            topBar(t)
            chips(t)
            carousel(t)
            dock(t, screenW)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: Backdrop

    private func backdrop(_ t: Theme) -> some View {
        ZStack {
            AppCanvas()
            if let a = session.current ?? session.assets.last {
                GeometryReader { geo in
                    PhotoImage(id: a.id, pointSize: CGSize(width: 120, height: 260), loader: model.images)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: 50)
                }
                .ignoresSafeArea()
                Color(hex: t.base, opacity: t.scrim).ignoresSafeArea()
            }
        }
        .accessibilityHidden(true)
    }

    // MARK: Top bar and chips

    private func topBar(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            Button { model.closeAlbum() } label: {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: t.text)).frame(width: 44, height: 44)
                    .glass(in: Circle())
            }
            .accessibilityLabel("Back to Albums")
            VStack(alignment: .leading, spacing: 0) {
                Text(session.album.title).font(.display(28)).foregroundStyle(Color(hex: t.text))
                    .lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Text("\(min(session.index + 1, session.assets.count).formatted()) of \(session.assets.count.formatted())")
                    .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
            }
            Spacer(minLength: 8)
            // The Review button arrives in Stage 6; until then this only shows the count.
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text(session.marked.count, format: .number).monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 14).frame(minHeight: 44)
            .glass(in: Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(session.marked.count) marked for deletion")
        }
        .padding(.top, 4)
    }

    private func chips(_ t: Theme) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AlbumList.visible(model.albums, filter: .all)) { album in
                    let on = album.id == session.album.id
                    Button {
                        guard !on else { return }
                        if session.marked.isEmpty { Task { await model.open(album) } }
                        else { pendingAlbum = album }
                    } label: {
                        Text(album.title).font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: on ? t.pillText : t.text))
                            .padding(.horizontal, 16).frame(minHeight: 44)
                            .background { if on { Capsule().fill(Color(hex: t.pillFill)) } }
                            .modifier(GlassUnless(on: on))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    // MARK: Carousel

    private struct Slot: Identifiable {
        let asset: Asset?          // nil = the "That's all" card
        let rel: Int               // -1 previous, 0 current, 1 next
        var id: String { rel == -1 ? "peek-\(asset!.id)" : (asset.map { "card-\($0.id)" } ?? "end") }
    }

    private var slots: [Slot] {
        var out: [Slot] = []
        let i = session.index, a = session.assets
        if i - 1 >= 0, i - 1 < a.count { out.append(Slot(asset: a[i - 1], rel: -1)) }
        if i < a.count { out.append(Slot(asset: a[i], rel: 0)) } else { out.append(Slot(asset: nil, rel: 0)) }
        if i + 1 < a.count { out.append(Slot(asset: a[i + 1], rel: 1)) }
        return out
    }

    private func carousel(_ t: Theme) -> some View {
        GeometryReader { geo in
            let cardW = geo.size.width * 0.78
            let size = CGSize(width: cardW, height: geo.size.height)
            let step = cardW + gap
            ZStack {
                ForEach(slots) { slot in
                    slotView(slot, size: size, step: step, screenW: geo.size.width, t)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .simultaneousGesture(drag(screenW: geo.size.width))
        }
    }

    @ViewBuilder
    private func slotView(_ slot: Slot, size: CGSize, step: CGFloat, screenW: CGFloat, _ t: Theme) -> some View {
        let fade = AnyTransition.opacity
        switch (slot.asset, slot.rel) {
        case (let asset?, -1):
            Button { undo(screenW) } label: {
                PhotoCard(asset: asset, size: size, loader: model.images, theme: t, showsCaption: false)
                    .overlay(alignment: .topTrailing) { badge(for: asset, t).padding(.top, 14).padding(.trailing, 3) }
            }
            .buttonStyle(.plain)
            .scaleEffect(0.94)
            .offset(x: -step)
            .transition(fade)
            .accessibilityLabel("Undo last decision")
        case (let asset?, 0):
            let p = max(-1, min(1, dragX / (screenW * 0.3)))
            PhotoCard(asset: asset, size: size, loader: model.images, theme: t, showsCaption: true)
                .overlay { tint(p, t) }
                .overlay(alignment: .top) { tag(p, t).padding(.top, 18) }
                .rotationEffect(.degrees(12 * Double(max(-1, min(1, dragX / (screenW * 0.5))))))
                .offset(x: dragX)
                .contentShape(Rectangle())
                .transition(reduceMotion ? fade : .asymmetric(insertion: .offset(x: -screenW), removal: .identity))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(asset.kind == .video ? "Video" : "Photo"), \(asset.created.formatted(.dateTime.day().month(.wide).year()))")
                .accessibilityAction(named: "Delete") { commit(.left, screenW) }
                .accessibilityAction(named: "Keep") { commit(.right, screenW) }
                .accessibilityAction(named: "Undo") { undo(screenW) }
        case (let asset?, _):
            PhotoCard(asset: asset, size: size, loader: model.images, theme: t, showsCaption: false)
                .offset(x: step)
                .transition(fade)
                .accessibilityHidden(true)
        default:
            endCard(size: size, t)
                .transition(fade)
        }
    }

    private func badge(for asset: Asset, _ t: Theme) -> some View {
        let deleted = session.marked.contains(asset.id)
        return Image(systemName: deleted ? "xmark" : "checkmark")
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color(hex: deleted ? t.deleteTint : t.keepTint))
            .frame(width: 28, height: 28).glass(in: Circle())
            .accessibilityHidden(true)
    }

    private func tint(_ p: CGFloat, _ t: Theme) -> some View {
        Color(hex: p < 0 ? Theme.blush : Theme.sage).opacity(0.45 * abs(p))
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .allowsHitTesting(false)
    }

    @ViewBuilder private func tag(_ p: CGFloat, _ t: Theme) -> some View {
        if abs(p) > 0.05 {
            let del = p < 0
            HStack(spacing: 6) {
                Image(systemName: del ? "xmark" : "checkmark")
                Text(del ? "DELETE" : "KEEP").tracking(1)
            }
            .font(.footnote.weight(.bold))
            .foregroundStyle(Color(hex: del ? t.deleteTint : t.keepTint))
            .padding(.horizontal, 14).frame(minHeight: 36)
            .glass(in: Capsule())
            .opacity(min(1, abs(p) * 1.4))
            .allowsHitTesting(false)
        }
    }

    private func endCard(size: CGSize, _ t: Theme) -> some View {
        VStack(spacing: 14) {
            Text("That's all").font(.display(40)).foregroundStyle(Color(hex: t.text))
            Text(session.marked.isEmpty
                 ? "Nothing marked for deletion."
                 : "\(session.marked.count.formatted()) marked for deletion.")
                .foregroundStyle(Color(hex: t.textSecondary))
                .multilineTextAlignment(.center)
            // Review deletions replaces this in Stage 6.
            PillButton("Back to Albums") { model.closeAlbum() }
        }
        .padding(24)
        .frame(width: size.width, height: size.height)
        .glass(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    // MARK: Dock

    private func dock(_ t: Theme, _ screenW: CGFloat) -> some View {
        let p = max(-1, min(1, dragX / (screenW * 0.3)))
        return HStack(spacing: 22) {
            dockButton("xmark", "Delete", fill: Theme.blush, size: 64, grow: p < 0 ? -p : 0) {
                commit(.left, screenW)
            }
            dockButton("arrow.uturn.backward", "Undo", fill: nil, size: 48, grow: 0, t: t) {
                undo(screenW)
            }
            .disabled(!session.canUndo)
            .opacity(session.canUndo ? 1 : 0.4)
            dockButton("checkmark", "Keep", fill: Theme.sage, size: 64, grow: p > 0 ? p : 0) {
                commit(.right, screenW)
            }
        }
        .padding(.horizontal, 22).padding(.vertical, 12)
        .glass(in: Capsule())
        .disabled(session.isFinished && !session.canUndo)
    }

    private func dockButton(_ symbol: String, _ label: String, fill: UInt32?, size: CGFloat,
                            grow: CGFloat, t: Theme? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.38, weight: .bold))
                .foregroundStyle(Color(hex: fill == nil ? (t?.text ?? 0xFFFFFF) : Theme.onFill))
                .frame(width: size, height: size)
                .background { if let fill { Circle().fill(Color(hex: fill)) } else { Circle().fill(Color(hex: t?.text ?? 0xFFFFFF, opacity: 0.12)) } }
                .scaleEffect(1 + 0.25 * grow)
        }
        .buttonStyle(.plain)
        .disabled(label != "Undo" && session.isFinished)
        .accessibilityLabel(label)
    }

    // MARK: Gestures and decisions

    private func drag(screenW: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 8)
            .onChanged { v in if !busy { dragX = v.translation.width } }
            .onEnded { v in
                guard !busy else { return }
                let far = abs(v.translation.width) > screenW * 0.3
                let flick = abs(v.velocity.width) > 900 && abs(v.translation.width) > 30
                    && (v.velocity.width > 0) == (v.translation.width > 0)
                if far || flick { commit(v.translation.width < 0 ? .left : .right, screenW) }
                else { withAnimation(spring) { dragX = 0 } }
            }
    }

    private func commit(_ side: Side, _ screenW: CGFloat) {
        guard !busy, !session.isFinished else { return }
        busy = true
        commitTick += 1
        let apply = { side == .left ? session.delete() : session.keep() }
        if reduceMotion {
            withAnimation(.easeInOut(duration: 0.2)) { apply(); dragX = 0 }
            busy = false
        } else {
            withAnimation(spring) { dragX = (side == .left ? -1 : 1) * screenW * 1.3 } completion: {
                withAnimation(spring) { apply(); dragX = 0 }
                busy = false
            }
        }
        if side == .left {
            announce("Marked for deletion, \(min(session.index + 2, session.assets.count)) of \(session.assets.count)")
        }
    }

    private func undo(_ screenW: CGFloat) {
        guard !busy, session.canUndo else { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : spring) { session.undo(); dragX = 0 }
    }

    private func announce(_ text: String) {
        var s = AttributedString(text)
        s.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(s).post()
    }

    private func prefetch() {
        let i = session.index, a = session.assets
        let size = CGSize(width: width * 0.78 * displayScale, height: 520 * displayScale)
        let ahead = (i...(i + 3)).filter { $0 < a.count }.map { a[$0].id }
        let behind = ((i - 6)..<(i - 1)).filter { $0 >= 0 }.map { a[$0].id }
        model.images.prefetch(ids: ahead, size: size)
        model.images.stopPrefetching(ids: behind, size: size)
    }
}

private struct GlassUnless: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        if on { content } else { content.glass(in: Capsule()) }
    }
}

struct PhotoCard: View {
    let asset: Asset
    let size: CGSize
    let loader: PhotoImageLoading
    let theme: Theme
    let showsCaption: Bool

    var body: some View {
        PhotoImage(id: asset.id, pointSize: size, loader: loader)
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(alignment: .bottom) { if showsCaption { caption } }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(asset.created.formatted(.dateTime.day().month(.wide).year()))
                .font(.display(24))
            Text(kindLabel).font(.caption.weight(.semibold)).tracking(1.2)
                .foregroundStyle(Color(hex: theme.textSecondary))
        }
        .foregroundStyle(Color(hex: theme.text))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16).padding(.vertical, 12)
        .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .padding(10)
    }

    private var kindLabel: String {
        switch asset.kind {
        case .photo: "PHOTO"
        case .screenshot: "SCREENSHOT"
        case .livePhoto: "LIVE PHOTO"
        case .video: "VIDEO"
        }
    }
}
