import Photos
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
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var dragX: CGFloat = 0
    @State private var busy = false
    @State private var commitTick = 0
    @State private var pendingAlbum: Album?
    @State private var viewing: Asset?
    @State private var holdingLive = false
    @State private var stripID: String?
    @State private var scrubPos: CGFloat = 0
    @State private var scrubbing = false
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
            .sensoryFeedback(.selection, trigger: scrubbing) { _, now in !now }
            .onChange(of: session.index) { prefetch(); holdingLive = false }
            .mediaCover(item: $viewing, model: model)
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
        VStack(spacing: 6) {
            topBar(t)
            chips(t)
            carousel(t)
            strip(t, screenW: screenW)
            dock(t, screenW)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 0)
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
        let back = Button { model.closeAlbum() } label: {
            Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: t.text)).frame(width: 44, height: 44)
                .glass(in: Circle())
        }
        .accessibilityLabel("Back to Albums")
        let title = VStack(alignment: .leading, spacing: 0) {
            Text(session.album.title).font(.display(28)).foregroundStyle(Color(hex: t.text))
                .lineLimit(typeSize.isAccessibilitySize ? nil : 1).minimumScaleFactor(typeSize.isAccessibilitySize ? 1 : 0.7)
                .accessibilityAddTraits(.isHeader)
            Text("\(min(session.index + 1, session.assets.count).formatted()) of \(session.assets.count.formatted())")
                .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
        }
        let review = Button { model.beginReview() } label: {
            HStack(spacing: 6) {
                Image(systemName: "trash")
                Text(session.marked.count, format: .number).monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 14).frame(minHeight: 44)
            .glass(in: Capsule())
        }
        .disabled(session.marked.isEmpty)
        .accessibilityLabel("Review \(session.marked.count) marked for deletion")
        let select = Button { model.beginSelect() } label: {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle")
                Text("Select")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 14).frame(minHeight: 44)
            .glass(in: Capsule())
        }
        .accessibilityLabel("Select many photos")
        .accessibilityHint("Pick several photos at once to delete")
        return Group {
            if typeSize.isAccessibilitySize {
                // Big text: buttons share a row, the title gets the full width below.
                VStack(alignment: .leading, spacing: 8) {
                    HStack { back; Spacer(minLength: 8); select; review }
                    title
                }
            } else {
                HStack(spacing: 8) { back; title; Spacer(minLength: 4); select; review }
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder private func chips(_ t: Theme) -> some View {
        if !model.isFilter(session.album) { albumChips(t) }
    }

    private func albumChips(_ t: Theme) -> some View {
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
        var id: String { rel < 0 ? "peek-\(asset!.id)" : (asset.map { "card-\($0.id)" } ?? "end") }
    }

    private var slots: [Slot] {
        var out: [Slot] = []
        let i = session.index, a = session.assets
        let n = ring.visible
        for rel in -n...n {
            let j = i + rel
            if rel == 0 { out.append(Slot(asset: i < a.count ? a[i] : nil, rel: 0)) }
            else if j >= 0, j < a.count { out.append(Slot(asset: a[j], rel: rel)) }
        }
        return out
    }

    private var ring: CoverFlowRing {
        CoverFlowRing()
    }

    private func carousel(_ t: Theme) -> some View {
        GeometryReader { geo in
            let cardW = geo.size.width * 0.86
            let size = CGSize(width: cardW, height: geo.size.height)
            let step = cardW * 0.62  // neighbours tuck behind the centre card (Cover Flow)
            let ring = self.ring
            ZStack {
                ForEach(slots) { slot in
                    let pose = ring.pose(at: CGFloat(slot.rel) - scrubFrac, step: step, cardWidth: cardW)
                    slotView(slot, size: size, step: step, screenW: geo.size.width, t)
                        .brightness(-pose.dim)
                        .saturation(1 - pose.dim * 0.6)
                        .shadow(color: .black.opacity(0.45 * pose.shadow), radius: 22, x: 0, y: 6)
                        .scaleEffect(pose.scale)
                        .opacity(pose.opacity)
                        .offset(x: pose.x, y: pose.y)
                        .zIndex(pose.depth)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .simultaneousGesture(drag(screenW: geo.size.width))
        }
        // Cards may bleed into the 16 pt page margin but not under a side status strip (iPhone Duo).
        .mask { Rectangle().padding(.horizontal, -16) }
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
            .transition(fade)
            .accessibilityLabel("Undo last decision")
        case (let asset?, 0):
            let p = max(-1, min(1, dragX / (screenW * 0.3)))
            PhotoCard(asset: asset, size: size, loader: model.images, theme: t, showsCaption: true,
                      setPosition: session.setPosition(of: asset.id))
                .overlay { livePlayback(asset) }
                .overlay { playBadge(asset, t) }
                .overlay { tint(p, t) }
                .overlay(alignment: .top) { tag(p, t).padding(.top, 18) }
                .rotationEffect(.degrees(12 * Double(max(-1, min(1, dragX / (screenW * 0.5))))))
                .offset(x: dragX)
                .contentShape(Rectangle())
                .onTapGesture { viewing = asset }
                .onLongPressGesture(minimumDuration: 0.3, maximumDistance: 24, perform: {},
                                    onPressingChanged: { if asset.kind == .livePhoto { holdingLive = $0 } })
                .transition(reduceMotion ? fade : .asymmetric(insertion: .offset(x: step), removal: .identity))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(cardLabel(asset))
                .accessibilityAction(named: "Delete") { commit(.left, screenW) }
                .accessibilityAction(named: "Keep") { commit(.right, screenW) }
                .accessibilityAction(named: "Undo") { undo(screenW) }
                .accessibilityAction(named: asset.kind == .video ? "Play" : "Open") { viewing = asset }
        case (let asset?, _):
            PhotoCard(asset: asset, size: size, loader: model.images, theme: t, showsCaption: false)
                .transition(.asymmetric(insertion: fade, removal: .identity))
                .accessibilityHidden(true)
        default:
            endCard(size: size, t)
                .transition(fade)
        }
    }

    private func cardLabel(_ a: Asset) -> String {
        var parts: [String]
        switch a.kind {
        case .photo: parts = ["Photo"]
        case .screenshot: parts = ["Screenshot"]
        case .livePhoto: parts = ["Live Photo"]
        case .video: parts = ["Video" + (a.duration.map { ", \(Formatting.spokenClock($0)) long" } ?? "")]
        }
        parts.append(a.created.formatted(.dateTime.day().month(.wide).year()))
        if let p = session.setPosition(of: a.id) { parts.append("Set \(p.set) of \(p.ofSets), copy \(p.item) of \(p.ofItems)") }
        parts.append("\(min(session.index + 1, session.assets.count)) of \(session.assets.count)")
        return parts.joined(separator: ", ")
    }

    /// Video: a play button in the middle; tapping the card opens the player.
    @ViewBuilder private func playBadge(_ asset: Asset, _ t: Theme) -> some View {
        if asset.kind == .video {
            Image(systemName: "play.fill").font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color(hex: t.text)).frame(width: 64, height: 64)
                .glass(in: Circle()).allowsHitTesting(false).accessibilityHidden(true)
        }
    }

    /// Live Photo: plays in place while the finger is held down.
    @ViewBuilder private func livePlayback(_ asset: Asset) -> some View {
        if asset.kind == .livePhoto, holdingLive {
            InlineLivePhoto(model: model, id: asset.id)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .allowsHitTesting(false)
        }
    }

    private func badge(for asset: Asset, _ t: Theme) -> some View {
        let deleted = session.marked.contains(asset.id)
        return Image(systemName: deleted ? "trash.fill" : "heart.fill")
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
                Image(systemName: del ? "trash.fill" : "heart.fill")
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
            if session.marked.isEmpty {
                PillButton("Back to Albums") { model.closeAlbum() }
            } else {
                PillButton("Review deletions") { model.beginReview() }
            }
        }
        .padding(24)
        .frame(width: size.width, height: size.height)
        .glass(in: RoundedRectangle(cornerRadius: 30, style: .continuous))
    }

    // MARK: Dock

    private func dock(_ t: Theme, _ screenW: CGFloat) -> some View {
        let p = max(-1, min(1, dragX / (screenW * 0.3)))
        return VStack(spacing: 0) {
            HStack(spacing: 12) {
                dockButton("trash.fill", "Delete", fill: Theme.blush, grow: p < 0 ? -p : 0) {
                    commit(.left, screenW)
                }
                dockButton("arrow.uturn.backward", "Undo", fill: nil, grow: 0, t: t) {
                    undo(screenW)
                }
                .disabled(!session.canUndo)
                .opacity(session.canUndo ? 1 : 0.4)
                dockButton("heart.fill", "Keep", fill: Theme.sage, grow: p > 0 ? p : 0) {
                    commit(.right, screenW)
                }
            }
        }
        .padding(.horizontal, 8).padding(.vertical, 6)
        .glass(in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .disabled(session.isFinished && !session.canUndo)
    }

    private func dockButton(_ symbol: String, _ label: String, fill: UInt32?,
                            grow: CGFloat, t: Theme? = nil, action: @escaping () -> Void) -> some View {
        let isUndo = fill == nil
        return Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: symbol).font(.system(size: 17, weight: .bold))
                Text(label).font(.subheadline.weight(.bold))
            }
            .foregroundStyle(Color(hex: isUndo ? (t?.text ?? 0xFFFFFF) : Theme.onFill))
            .frame(maxWidth: .infinity, minHeight: 48)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(isUndo ? Color(hex: t?.text ?? 0xFFFFFF, opacity: 0.12) : Color(hex: fill!))
            }
            .scaleEffect(1 + 0.06 * grow)
        }
        .buttonStyle(.plain)
        .layoutPriority(isUndo ? 0 : 1)
        .frame(maxWidth: isUndo ? 110 : .infinity)
        .disabled(label != "Undo" && session.isFinished)
        .accessibilityLabel(label)
    }

    // MARK: Dot scrubber (D-25, revised)

    private let dotPitch: CGFloat = 16

    /// Slide the dots to browse. The big photo rotates through a 3D carousel as you go.
    /// Sliding forward keeps every photo it passes (D-25); sliding back undoes those decisions.
    private func strip(_ t: Theme, screenW: CGFloat) -> some View {
        let viewW = max(1, screenW - 32)
        let pitch = dotPitch
        let marked = Set(session.marked)
        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 0) {
                ForEach(session.assets) { a in
                    let isMarked = marked.contains(a.id)
                    Capsule()
                        .fill(isMarked ? Color(hex: Theme.blush) : Color(hex: t.text))
                        .frame(width: 8, height: 8)
                        .frame(width: pitch, height: 44)
                        .contentShape(Rectangle())
                        .visualEffect { c, proxy in
                            let f = proxy.frame(in: .scrollView(axis: .horizontal))
                            let d = min(6, abs(f.midX - viewW / 2) / pitch)
                            let near = max(0, 1 - d)          // 1 at the centre: dot stretches into a pill
                            let s = max(0.45, 1.5 - d * 0.2)
                            return c.scaleEffect(x: s * (1 + 1.2 * near), y: s)
                                .opacity(max(0.25, 1 - d * 0.12))
                        }
                        .onTapGesture {
                            withAnimation(reduceMotion ? nil : spring) { stripID = a.id }
                        }
                        .id(a.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $stripID, anchor: .center)
        .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
        .contentMargins(.horizontal, max(0, (viewW - pitch) / 2), for: .scrollContent)
        .onScrollGeometryChange(for: CGFloat.self) { g in
            (g.contentOffset.x + g.contentInsets.leading) / pitch
        } action: { _, pos in
            scrubPos = pos
        }
        .onScrollPhaseChange { _, phase in
            scrubbing = phase == .tracking || phase == .interacting || phase == .decelerating
        }
        .frame(height: 44)
        .onAppear { stripID = session.current?.id }
        .onChange(of: stripID) { _, id in followStrip(id) }
        .onChange(of: session.index) { _, i in
            guard i < session.assets.count, stripID != session.assets[i].id else { return }
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.25)) { stripID = session.assets[i].id }
        }
        .accessibilityHidden(true)
    }

    /// How far the dots are between photos, -0.5...0.5, while a finger is scrubbing; else 0.
    private var scrubFrac: CGFloat {
        guard scrubbing, !reduceMotion else { return 0 }
        return max(-1, min(1, scrubPos - CGFloat(session.index)))
    }

    /// The strip settled on or passed a photo: everything in between is kept (forward) or un-decided (back).
    private func followStrip(_ id: String?) {
        guard let id, !busy, let target = session.assets.firstIndex(where: { $0.id == id }) else { return }
        while session.index < target { session.keep() }
        while session.index > target, session.canUndo { session.undo() }
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
        let next = session.index + 2   // read before the decision is applied
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
        if next > session.assets.count {
            announce(side == .left ? "Marked for deletion. That's all." : "Kept. That's all.")
        } else {
            announce("\(side == .left ? "Marked for deletion" : "Kept"), \(next) of \(session.assets.count)")
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
    var setPosition: SwipeSession.SetPosition?

    var body: some View {
        PhotoImage(id: asset.id, pointSize: size, loader: loader)
            .frame(width: size.width, height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .overlay(alignment: .bottom) { if showsCaption { caption } }
    }

    private var caption: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(asset.created.formatted(.dateTime.day().month(.wide).year()))
                .font(.footnote.weight(.semibold))
            HStack(spacing: 6) {
                Text(kindLabel).font(.caption2.weight(.semibold)).tracking(1)
                    .foregroundStyle(Color(hex: theme.textSecondary))
                if let p = setPosition {
                    Text("Set \(p.set) · \(p.item) of \(p.ofItems)")
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10).padding(.vertical, 4)
                        .glass(in: Capsule())
                        .accessibilityLabel("Set \(p.set) of \(p.ofSets), photo \(p.item) of \(p.ofItems)")
                }
            }
        }
        .foregroundStyle(Color(hex: theme.text))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12).padding(.vertical, 6)
        .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(8)
    }

    private var kindLabel: String {
        switch asset.kind {
        case .photo: "PHOTO"
        case .screenshot: "SCREENSHOT"
        case .livePhoto: "LIVE PHOTO"
        case .video: asset.duration.map { "VIDEO · \(Formatting.clock($0))" } ?? "VIDEO"
        }
    }
}


/// Loads the Live Photo on first hold and plays it with sound until the finger lifts.
private struct InlineLivePhoto: View {
    let model: AppModel
    let id: String
    @State private var photo: PHLivePhoto?

    var body: some View {
        Group {
            if let photo { LivePhotoRepresentable(photo: photo, playing: true) }
        }
        .task { photo = await model.media.livePhoto(id: id, size: CGSize(width: 1200, height: 1600)) }
    }
}


private extension View {
    /// Full-screen cover on iPhone; host test builds (macOS) have none.
    @ViewBuilder func mediaCover(item: Binding<Asset?>, model: AppModel) -> some View {
        #if os(iOS)
        fullScreenCover(item: item) { MediaViewer(model: model, asset: $0) }
        #else
        self
        #endif
    }
}
