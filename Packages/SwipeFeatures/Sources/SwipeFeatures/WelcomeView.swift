import SwiftUI
import SwipeUI

/// Stage 1: empty Welcome shell. Permission flow arrives in Stage 3.
public struct WelcomeView: View {
    public static let title = "Lighter"
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public var body: some View {
        let t = Theme.resolve(scheme)
        VStack(spacing: 12) {
            Spacer()
            Text(Self.title).font(.display(64, italic: true))
                .foregroundStyle(Color(hex: t.text))
            Text("A calmer camera roll, one photo at a time.")
                .font(.body).multilineTextAlignment(.center)
                .foregroundStyle(Color(hex: t.textSecondary))
            Spacer()
            PillButton("Allow Photo Access") {}
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .appCanvas()
    }
}

#Preview("Dusk") { WelcomeView().preferredColorScheme(.dark) }
#Preview("Dawn") { WelcomeView().preferredColorScheme(.light) }
