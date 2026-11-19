import StoreKit
import SwiftUI
import SwipeCore
import SwipeUI

/// Welcome until Photos access is granted, then Albums, or Swipe while an album is open.
public struct RootView: View {
    let model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        Group {
            if model.showsWelcome {
                WelcomeView(model: model)
            } else if let session = model.session, let summary = model.summary {
                DoneView(model: model, summary: summary).id(ObjectIdentifier(session))
            } else if let session = model.session, model.reviewing {
                ReviewView(model: model, session: session).id(ObjectIdentifier(session))
            } else if let session = model.session {
                SwipeView(model: model, session: session).id(ObjectIdentifier(session))
            } else {
                AlbumsView(model: model)
            }
        }
        // Asked once, only after Back to Albums on the Albums screen, never on Review or Done.
        .preferredColorScheme(model.appearance.colorScheme)
        .onChange(of: model.session == nil) { _, onAlbums in
            if onAlbums, model.reviewPromptDue { model.ratingShown(); requestReview() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.refresh() } }
        }
    }
}

extension AppearanceSetting {
    /// nil lets the iPhone's own setting decide.
    var colorScheme: ColorScheme? {
        switch self { case .system: nil; case .light: .light; case .dark: .dark }
    }
}
