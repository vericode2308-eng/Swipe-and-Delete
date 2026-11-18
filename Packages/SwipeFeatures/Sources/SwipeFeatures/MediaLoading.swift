import AVFoundation
import Photos

/// Playback sources for videos and Live Photos. The PhotoKit version lives in the app target.
public protocol MediaLoading: Sendable {
    /// nil when the video can't be loaded (offline iCloud video, deleted).
    func video(id: String) async -> AVPlayerItem?
    func livePhoto(id: String, size: CGSize) async -> PHLivePhoto?
}

public struct NoMedia: MediaLoading {
    public init() {}
    public func video(id: String) async -> AVPlayerItem? { nil }
    public func livePhoto(id: String, size: CGSize) async -> PHLivePhoto? { nil }
}
