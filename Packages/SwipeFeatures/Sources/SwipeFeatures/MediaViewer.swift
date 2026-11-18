import AVKit
import Photos
import PhotosUI
import SwiftUI
import SwipeCore
import SwipeUI

/// Full-screen look at one item: zoomable photo, playing video, or Live Photo.
/// Closing stops all playback and releases the audio session.
struct MediaViewer: View {
    let model: AppModel
    let asset: Asset
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var screenSize = CGSize(width: 393, height: 852)
    @State private var player: AVPlayer?
    @State private var live: PHLivePhoto?
    @State private var image: CGImage?
    @State private var failed = false
    @State private var zoom = ZoomState()
    @State private var baseScale: CGFloat = 1
    @State private var baseOffset: CGSize = .zero

    var body: some View {
        let t = Theme.resolve(scheme)
        GeometryReader { geo in
            ZStack {
                Color.black.ignoresSafeArea()
                content(geo.size, t)
                if failed {
                    Text("Couldn't load this one.").foregroundStyle(.white.opacity(0.8))
                }
            }
            .overlay(alignment: .topLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(Color(hex: t.text)).frame(width: 44, height: 44)
                        .glass(in: Circle())
                }
                .accessibilityLabel("Close")
                .padding(16)
            }
        }
        .onGeometryChange(for: CGSize.self) { $0.size } action: { screenSize = $0 }
        .task(id: asset.id) { await load() }
        .onDisappear { stop() }
        .onChange(of: scenePhase) { _, p in if p != .active { player?.pause() } }
    }

    @ViewBuilder private func content(_ frame: CGSize, _ t: Theme) -> some View {
        switch asset.kind {
        case .video:
            if let player { VideoPlayer(player: player).ignoresSafeArea() }
        case .livePhoto where live != nil:
            LivePhotoRepresentable(photo: live!, autoplay: true).ignoresSafeArea()
                .accessibilityLabel("Live Photo. Touch and hold to play.")
        default:
            if let image { zoomable(image, frame) }
        }
    }

    private func zoomable(_ cg: CGImage, _ frame: CGSize) -> some View {
        let aspect = CGFloat(cg.width) / CGFloat(max(1, cg.height))
        let fit = aspect > frame.width / max(1, frame.height)
            ? CGSize(width: frame.width, height: frame.width / aspect)
            : CGSize(width: frame.height * aspect, height: frame.height)
        return Image(decorative: cg, scale: displayScale).resizable().scaledToFit()
            .frame(width: frame.width, height: frame.height)
            .scaleEffect(zoom.scale).offset(zoom.offset)
            .gesture(MagnifyGesture()
                .onChanged { zoom.pinch(base: baseScale, factor: $0.magnification, content: fit, in: frame) }
                .onEnded { _ in baseScale = zoom.scale })
            .simultaneousGesture(DragGesture()
                .onChanged { zoom.pan(base: baseOffset, translation: $0.translation, content: fit, in: frame) }
                .onEnded { _ in baseOffset = zoom.offset })
            .onTapGesture(count: 2) {
                withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85)) { zoom.toggle() }
                baseScale = zoom.scale; baseOffset = zoom.offset
            }
            .accessibilityLabel("Photo, \(asset.created.formatted(.dateTime.day().month(.wide).year()))")
            .accessibilityHint("Double tap to zoom")
    }

    private func load() async {
        let screen = screenSize
        switch asset.kind {
        case .video:
            guard let item = await model.media.video(id: asset.id) else { failed = true; return }
            Self.activateAudio()
            let p = AVPlayer(playerItem: item)
            player = p; p.play()
        case .livePhoto:
            let px = CGSize(width: screen.width * displayScale, height: screen.height * displayScale)
            if let l = await model.media.livePhoto(id: asset.id, size: px) { live = l; return }
            await loadStill(screen)      // no live data (iCloud, edited): show it as a photo
        default:
            await loadStill(screen)
        }
    }

    private func loadStill(_ screen: CGSize) async {
        let px = CGSize(width: screen.width * displayScale * 2, height: screen.height * displayScale * 2)
        for await next in model.images.images(id: asset.id, size: px) { image = next }
        if image == nil { failed = true }
    }

    private func stop() {
        player?.pause(); player?.replaceCurrentItem(with: nil); player = nil
        Self.releaseAudio()
    }

    /// Video plays with sound even with the silent switch on; released when the viewer closes.
    private static func activateAudio() {
        #if canImport(UIKit)
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private static func releaseAudio() {
        #if canImport(UIKit)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}

#if canImport(UIKit)
/// PHLivePhotoView: touch and hold plays it with sound; `autoplay` plays once on appear.
struct LivePhotoRepresentable: UIViewRepresentable {
    let photo: PHLivePhoto
    var autoplay = false
    /// Inline use: play while true, stop when it becomes false.
    var playing: Bool? = nil

    func makeUIView(context: Context) -> PHLivePhotoView {
        let v = PHLivePhotoView()
        v.contentMode = .scaleAspectFit
        v.livePhoto = photo
        return v
    }

    func updateUIView(_ v: PHLivePhotoView, context: Context) {
        if v.livePhoto !== photo { v.livePhoto = photo }
        if let playing { playing ? v.startPlayback(with: .full) : v.stopPlayback() }
        else if autoplay, !context.coordinator.started { context.coordinator.started = true; v.startPlayback(with: .full) }
    }

    func makeCoordinator() -> Coordinator { Coordinator() }
    final class Coordinator { var started = false }
}
#else
/// Host builds (tests) have no Live Photo view.
struct LivePhotoRepresentable: View {
    let photo: PHLivePhoto
    var autoplay = false
    var playing: Bool? = nil
    var body: some View { EmptyView() }
}
#endif
