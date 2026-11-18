import SwiftUI
import SwipeCore
import SwipeUI

/// Welcome until Photos access is granted, then Albums (placeholder until Stage 4).
public struct RootView: View {
    let model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var scheme

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        Group {
            if model.showsWelcome {
                WelcomeView(model: model)
            } else {
                let t = Theme.resolve(scheme)
                VStack(spacing: 8) {
                    Text("Albums").font(.display(44)).foregroundStyle(Color(hex: t.text))
                    Text(model.status == .limited ? "Limited access granted." : "Full access granted.")
                        .foregroundStyle(Color(hex: t.textSecondary))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .appCanvas()
            }
        }
        .onChange(of: scenePhase) { _, phase in if phase == .active { model.refresh() } }
    }
}
