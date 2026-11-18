import Photos
import PhotosUI
import SwiftUI
import SwipeFeatures
import UIKit

@main struct LighterApp: App {
    @State private var model: AppModel = {
        let loader = PhotoKitImageLoader()
        return AppModel(
        library: PhotoKitLibrary(),
        thumbnails: loader,
        images: loader,
        appVersion: Self.version,
        presentLimitedPicker: {
            let root = UIApplication.shared.connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow?.rootViewController }.first
            guard let root else { return }
            var top = root
            while let next = top.presentedViewController { top = next }
            PHPhotoLibrary.shared().presentLimitedLibraryPicker(from: top)
        },
        openSettings: {
            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
        })
    }()
    var body: some Scene { WindowGroup { RootView(model: model) } }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? ""
        let b = info?["CFBundleVersion"] as? String ?? ""
        return b.isEmpty ? v : "\(v) (\(b))"
    }
}
