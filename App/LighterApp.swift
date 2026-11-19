import Photos
import PhotosUI
import SwiftUI
import SwipeCore
import SwipeFeatures
import UIKit

@main struct LighterApp: App {
    /// Where landing-page-design/ is hosted, for example URL(string: "https://lighter.example.com"). Set it to make
    /// Settings open Privacy, Terms and Support in the browser; nil keeps the in-app reader.
    private static let websiteBase: URL? = nil

    @State private var model: AppModel = {
        let loader = PhotoKitImageLoader()
        return AppModel(
        library: PhotoKitLibrary(),
        thumbnails: loader,
        images: loader,
        media: loader,
        links: Self.websiteBase.map { AppLinks(website: $0, supportEmail: "support@vericodestudio.com") }
            ?? AppLinks(supportEmail: "support@vericodestudio.com"),
        scanner: CleanupScanner(library: PhotoKitLibrary(), analyzer: VisionPhotoAnalyzer(),
                                store: .standard(), shouldPause: {
            // Low Power Mode or a hot phone: wait instead of draining the battery.
            ProcessInfo.processInfo.isLowPowerModeEnabled
                || ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
        }),
        purchases: StoreKitPurchases(),
        debugPro: Self.debugPro,
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

    /// `-debug.pro YES` unlocks Pro in Debug builds only; Release builds ignore it.
    private static var debugPro: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "debug.pro")
        #else
        false
        #endif
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let v = info?["CFBundleShortVersionString"] as? String ?? ""
        let b = info?["CFBundleVersion"] as? String ?? ""
        return b.isEmpty ? v : "\(v) (\(b))"
    }
}
