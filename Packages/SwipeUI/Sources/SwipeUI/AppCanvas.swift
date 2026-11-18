import SwiftUI

/// Base colour plus three blurred blobs: the backdrop glass sits on.
public struct AppCanvas: View {
    @Environment(\.colorScheme) private var scheme
    public init() {}
    public var body: some View {
        let t = Theme.resolve(scheme)
        GeometryReader { geo in
            ZStack {
                Color(hex: t.base)
                Circle().fill(Color(hex: t.blobs[0])).frame(width: geo.size.width * 0.9)
                    .offset(x: -geo.size.width * 0.3, y: -geo.size.height * 0.25)
                Circle().fill(Color(hex: t.blobs[1])).frame(width: geo.size.width * 0.8)
                    .offset(x: geo.size.width * 0.35, y: geo.size.height * 0.05)
                Circle().fill(Color(hex: t.blobs[2])).frame(width: geo.size.width * 0.85)
                    .offset(x: -geo.size.width * 0.1, y: geo.size.height * 0.35)
            }
            .blur(radius: 75)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

public extension View {
    func appCanvas() -> some View { background { AppCanvas() } }
}
