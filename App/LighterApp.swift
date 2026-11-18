import SwiftUI
import SwipeFeatures

@main
struct LighterApp: App {
    @State private var model = AppModel(library: PhotoKitLibrary()) {
        if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
    }

    var body: some Scene {
        WindowGroup { RootView(model: model) }
    }
}
