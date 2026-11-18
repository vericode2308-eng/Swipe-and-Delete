import Photos
import SwipeFeatures
import UIKit

/// Album cover thumbnails. Stage 5 extends this for the swipe carousel.
struct PhotoKitImageLoader: ThumbnailLoading {
    func thumbnail(id: String, side: CGFloat) async -> CGImage? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject
        else { return nil }
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat   // one callback, not a degraded one first
        options.resizeMode = .fast
        options.isNetworkAccessAllowed = true
        return await withCheckedContinuation { cont in
            PHImageManager.default().requestImage(
                for: asset, targetSize: CGSize(width: side, height: side),
                contentMode: .aspectFill, options: options
            ) { image, _ in cont.resume(returning: image?.cgImage) }
        }
    }
}
