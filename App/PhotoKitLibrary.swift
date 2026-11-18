import Photos
import SwipeCore

/// PhotoKit adapter. Stage 3: permission only. This is the only file that
/// will ever delete photos (later stages).
struct PhotoKitLibrary: PhotoLibrary {
    func currentStatus() -> AuthStatus { Self.map(PHPhotoLibrary.authorizationStatus(for: .readWrite)) }

    func authorize() async -> AuthStatus {
        Self.map(await PHPhotoLibrary.requestAuthorization(for: .readWrite))
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
