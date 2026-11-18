import Photos
import SwipeCore

/// PhotoKit adapter. This is the only file that deletes photos.
struct PhotoKitLibrary: PhotoLibrary {
    func currentStatus() -> AuthStatus { Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite)) }

    func authorize() async -> AuthStatus {
        Self.map(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
    }

    /// Smart albums worth cleaning, in the order the Photos app lists them.
    /// Hidden and Recently Deleted are left out on purpose.
    private static let smartSubtypes: [PHAssetCollectionSubtype] = [
        .smartAlbumUserLibrary, .smartAlbumFavorites, .smartAlbumScreenshots,
        .smartAlbumSelfPortraits, .smartAlbumLivePhotos, .smartAlbumDepthEffect,
        .smartAlbumPanoramas, .smartAlbumVideos, .smartAlbumSlomoVideos,
        .smartAlbumTimelapses, .smartAlbumAnimated, .smartAlbumLongExposures,
    ]

    func albums() async -> [Album] {
        var result: [Album] = []
        for subtype in Self.smartSubtypes {
            let found = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: subtype, options: nil)
            found.enumerateObjects { c, _, _ in
                if let a = Self.album(from: c, kind: .smart) { result.append(a) }
            }
        }
        let mine = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil)
        var user: [Album] = []
        mine.enumerateObjects { c, _, _ in
            if let a = Self.album(from: c, kind: .user) { user.append(a) }
        }
        return result + user
    }

    func assets(in album: Album) async -> [Asset] {
        guard let collection = PHAssetCollection.fetchAssetCollections(
            withLocalIdentifiers: [album.id], options: nil).firstObject else { return [] }
        let oldestFirst = PHFetchOptions()
        oldestFirst.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let found = PHAsset.fetchAssets(in: collection, options: oldestFirst)
        var out: [Asset] = []
        out.reserveCapacity(found.count)
        found.enumerateObjects { a, _, _ in
            out.append(Asset(id: a.localIdentifier, kind: Self.kind(of: a),
                             created: a.creationDate ?? .distantPast))
        }
        return out
    }

    /// Plain photos and Live Photos, newest first. Screenshots and videos have their own albums.
    func scanItems() async -> [ScanItem] {
        let options = PHFetchOptions()
        options.predicate = NSPredicate(format: "mediaType == %d AND (mediaSubtypes & %d) == 0",
                                        PHAssetMediaType.image.rawValue, PHAssetMediaSubtype.photoScreenshot.rawValue)
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let found = PHAsset.fetchAssets(with: options)
        var out: [ScanItem] = []
        out.reserveCapacity(found.count)
        found.enumerateObjects { a, _, _ in
            let created = a.creationDate ?? .distantPast
            out.append(ScanItem(id: a.localIdentifier, created: created, modified: a.modificationDate ?? created))
        }
        return out
    }

    func assets(ids: [String]) async -> [Asset] {
        guard !ids.isEmpty else { return [] }
        let found = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var byID: [String: Asset] = [:]
        found.enumerateObjects { a, _, _ in
            byID[a.localIdentifier] = Asset(id: a.localIdentifier, kind: Self.kind(of: a),
                                            created: a.creationDate ?? .distantPast)
        }
        return ids.compactMap { byID[$0] }
    }

    func existing(_ ids: [String]) async -> [String] {
        guard !ids.isEmpty else { return [] }
        let found = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var alive = Set<String>()
        found.enumerateObjects { a, _, _ in alive.insert(a.localIdentifier) }
        return ids.filter(alive.contains)
    }

    /// Original file sizes via the undocumented `fileSize` key; a missing value counts as 0.
    func byteSize(of ids: [String]) async -> Int64 {
        guard !ids.isEmpty else { return 0 }
        let found = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var total: Int64 = 0
        found.enumerateObjects { asset, _, _ in
            for r in PHAssetResource.assetResources(for: asset) {
                if let n = r.value(forKey: "fileSize") as? Int64 { total += n }
                else if let n = r.value(forKey: "fileSize") as? NSNumber { total += n.int64Value }
            }
        }
        return total
    }

    /// One change request, so iOS shows one prompt.
    func delete(_ ids: [String]) async throws -> DeleteOutcome {
        let found = PHAsset.fetchAssets(withLocalIdentifiers: ids, options: nil)
        var assets: [PHAsset] = []
        found.enumerateObjects { a, _, _ in assets.append(a) }
        guard !assets.isEmpty else { return .deleted }
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }
            return .deleted
        } catch let error as PHPhotosError where error.code == .userCancelled {
            return .cancelled
        } catch let error as NSError where error.domain == PHPhotosErrorDomain && error.code == PHPhotosError.userCancelled.rawValue {
            return .cancelled
        }
    }

    private static func kind(of a: PHAsset) -> AssetKind {
        if a.mediaType == .video { return .video }
        if a.mediaSubtypes.contains(.photoScreenshot) { return .screenshot }
        if a.mediaSubtypes.contains(.photoLive) { return .livePhoto }
        return .photo
    }

    private static func album(from c: PHAssetCollection, kind: AlbumKind) -> Album? {
        let newestFirst = PHFetchOptions()
        newestFirst.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(in: c, options: newestFirst)
        guard assets.count > 0 else { return nil }
        return Album(id: c.localIdentifier, title: c.localizedTitle ?? "Untitled",
                     count: assets.count, kind: kind, coverID: assets.firstObject?.localIdentifier)
    }

    private static func map(_ s: PHAuthorizationStatus) -> AuthStatus {
        switch s {
        case .authorized: .full
        case .limited: .limited
        case .notDetermined: .notDetermined
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }
}
