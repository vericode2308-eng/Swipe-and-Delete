import SwiftUI
import SwipeUI

/// One photo, filled into its frame. Shows the quick image first and swaps in
/// the sharp one; a late image for a previous id is never shown (the task is
/// cancelled when the id changes).
struct PhotoImage: View {
    let id: String
    let pointSize: CGSize
    let loader: PhotoImageLoading
    @Environment(\.displayScale) private var displayScale
    @Environment(\.colorScheme) private var scheme
    @State private var image: CGImage?
    @State private var shownID: String?
    @State private var unavailable = false

    var body: some View {
        let t = Theme.resolve(scheme)
        Color(hex: t.blobs[0], opacity: 0.30)
            .overlay {
                if let image, shownID == id {
                    Image(decorative: image, scale: displayScale).resizable().scaledToFill()
                } else if unavailable {
                    Text("Not available").font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
                }
            }
            .clipped()
            .task(id: id) {
                image = nil; shownID = nil; unavailable = false
                let px = CGSize(width: pointSize.width * displayScale, height: pointSize.height * displayScale)
                for await next in loader.images(id: id, size: px) {
                    if Task.isCancelled { return }
                    image = next; shownID = id
                }
                if !Task.isCancelled, image == nil { unavailable = true }
            }
    }
}
