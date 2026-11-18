import SwiftUI
import SwipeCore
import SwipeUI

/// Welcome until Photos access is granted, then Albums.
public struct RootView: View {
    let model: AppModel
    @Environment(\.scenePhase) private var scenePhase

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        Group {
            if model.showsWelcome {
                WelcomeView(model: model)
            } else {
                AlbumsView(model: model)
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.refresh() } }
        }
    }
}
