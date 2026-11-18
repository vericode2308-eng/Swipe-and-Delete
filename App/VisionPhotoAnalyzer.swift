import CoreGraphics
import Foundation
import Photos
import SwipeCore
import UIKit
import Vision

/// Looks at a photo's small local thumbnail with Vision. Nothing leaves the iPhone.
struct VisionPhotoAnalyzer: PhotoAnalyzer {
    /// Bump `recipe` when the hash recipe changes. The iOS major version is added because
    /// Vision's models can change with it, so cached results are then redone.
    static let recipe = 1
    var revision: Int { Self.recipe * 1000 + ProcessInfo.processInfo.operatingSystemVersion.majorVersion }

    func analyse(id: String) async -> PhotoAnalysis? {
        guard let image = await Self.thumbnail(id: id) else { return nil }
        let hash = Self.differenceHash(image)
        let handler = ImageRequestHandler(image)

        var hasPeople = false
        if let faces = try? await handler.perform(DetectFaceRectanglesRequest()), !faces.isEmpty { hasPeople = true }
        if !hasPeople, let bodies = try? await handler.perform(DetectHumanRectanglesRequest()), !bodies.isEmpty {
            hasPeople = true
        }

        // The quality check does not run in the Simulator; it simply reports "not utility, 0".
        var isUtility = false
        var score: Float = 0
        if let q = try? await handler.perform(CalculateImageAestheticsScoresRequest()) {
            isUtility = q.isUtility
            score = q.overallScore
        }

        var print: [Float] = []
        if let fp = try? await handler.perform(GenerateImageFeaturePrintRequest()) {
            print = fp.data.withUnsafeBytes { Array($0.bindMemory(to: Float.self)) }
        }
        return PhotoAnalysis(hasPeople: hasPeople, isUtility: isUtility, qualityScore: score,
                             imageHash: hash, featurePrint: print)
    }

    /// 300 px, local data only: an iCloud-only photo without a local copy returns nil and is skipped.
    private static func thumbnail(id: String) async -> CGImage? {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil).firstObject else { return nil }
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = false
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .fast
        options.isSynchronous = false
        return await withCheckedContinuation { cont in
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 300, height: 300),
                                                  contentMode: .aspectFill, options: options) { image, info in
                if (info?[PHImageResultIsDegradedKey] as? Bool) == true { return }
                cont.resume(returning: image?.cgImage)
            }
        }
    }

    /// 64-bit difference hash: 9×8 grey, one bit per "left pixel brighter than right".
    static func differenceHash(_ image: CGImage) -> UInt64 {
        let w = 9, h = 8
        var pixels = [UInt8](repeating: 0, count: w * h)
        let ok = pixels.withUnsafeMutableBytes { buf -> Bool in
            guard let ctx = CGContext(data: buf.baseAddress, width: w, height: h, bitsPerComponent: 8,
                                      bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                      bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return false }
            ctx.interpolationQuality = .medium
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard ok else { return 0 }
        var hash: UInt64 = 0
        for y in 0..<h { for x in 0..<(w - 1) {
            hash <<= 1
            if pixels[y * w + x] > pixels[y * w + x + 1] { hash |= 1 }
        } }
        return hash
    }
}
