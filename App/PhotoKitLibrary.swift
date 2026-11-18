import Photos
import SwipeCore

/// PhotoKit adapter. This is the only file that will ever delete photos
/// (a later stage).
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
