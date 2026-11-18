import Photos
import SwipeFeatures
import UIKit

/// Album covers and the swipe screen's photos. One caching manager, so the
/// prefetched next photos are served from memory when they become current.
final class PhotoKitImageLoader: ThumbnailLoading, PhotoImageLoading, @unchecked Sendable {
    private let manager = PHCachingImageManager()
    private let lock = NSLock()
    private var assets: [String: PHAsset] = [:]

    /// Same options for caching and requests, or the cache is not used.
    private let options: PHImageRequestOptions = {
        let o = PHImageRequestOptions()
        o.deliveryMode = .opportunistic     // quick image first, then the sharp one
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true     // iCloud-only photos download on demand
        return o
    }()

    private func asset(_ id: String) -> PHAsset? {
        lock.lock(); defer { lock.unlock() }
        if let a = assets[id] { return a }
        let a = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        if let a { assets[id] = a }
        return a
    }

    func images(id: String, size: CGSize) -> AsyncStream<CGImage> {
        AsyncStream { continuation in
            guard let asset = asset(id) else { continuation.finish(); return }
            let request = manager.requestImage(
                for: asset, targetSize: size, contentMode: .aspectFill, options: options
            ) { image, info in
                if let cg = image?.cgImage { continuation.yield(cg) }
                let degraded = (info?[PHImageResultIsDegradedKey] as? Bool) ?? false
                let cancelled = (info?[PHImageCancelledKey] as? Bool) ?? false
                let failed = info?[PHImageErrorKey] != nil
                if !degraded || cancelled || failed { continuation.finish() }
            }
            continuation.onTermination = { [manager] _ in manager.cancelImageRequest(request) }
        }
    }

    func prefetch(ids: [String], size: CGSize) {
        let list = ids.compactMap(asset)
        manager.startCachingImages(for: list, targetSize: size, contentMode: .aspectFill, options: options)
    }

    func stopPrefetching(ids: [String], size: CGSize) {
        let list = ids.compactMap(asset)
        manager.stopCachingImages(for: list, targetSize: size, contentMode: .aspectFill, options: options)
        lock.lock(); ids.forEach { assets[$0] = nil }; lock.unlock()
    }

    /// Album cover: one sharp square, no degraded first pass.
    func thumbnail(id: String, side: CGFloat) async -> CGImage? {
        guard let asset = asset(id) else { return nil }
        let o = PHImageRequestOptions()
        o.deliveryMode = .highQualityFormat
        o.resizeMode = .fast
        o.isNetworkAccessAllowed = true
        return await withCheckedContinuation { cont in
            PHImageManager.default().requestImage(
                for: asset, targetSize: CGSize(width: side, height: side),
                contentMode: .aspectFill, options: o
            ) { image, _ in cont.resume(returning: image?.cgImage) }
        }
    }
}
