import SwiftUI
import SwipeCore
import SwipeUI

extension AlbumFilter {
    var title: String {
        switch self { case .all: "All"; case .smart: "Smart Albums"; case .mine: "My Albums" }
    }
}

public struct AlbumsView: View {
    let model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showsAbout = false

    public init(model: AppModel) { self.model = model }

    public var body: some View {
        let t = Theme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header(t)
                if model.status == .limited { limitedRow(t) }
                if model.cleanupEnabled { QuickCleanupPanel(model: model) }
                chips(t)
                content(t)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .appCanvas()
        .task { await model.loadAlbums(); model.startScan() }
        .sheet(isPresented: $showsAbout) { AboutSheet(model: model) }
    }

    private func header(_ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Albums").font(.display(44)).foregroundStyle(Color(hex: t.text))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 12)
            Button { showsAbout = true } label: {
                Image(systemName: "info")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: t.text))
                    .frame(width: 44, height: 44)
                    .glass(in: Circle())
            }
            .accessibilityLabel("About Lighter")
        }
        .padding(.top, 8)
    }

    private func limitedRow(_ t: Theme) -> some View {
        Button { model.manageLimitedSelection() } label: {
            HStack {
                Text("Limited access").foregroundStyle(Color(hex: t.text))
                Text("·").foregroundStyle(Color(hex: t.textSecondary))
                Text("Manage selection").foregroundStyle(Color(hex: t.textSecondary))
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
                    .foregroundStyle(Color(hex: t.textSecondary))
            }
            .font(.subheadline)
            .padding(.horizontal, 16).padding(.vertical, 12)
            .frame(minHeight: 44)
            .glass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Limited access. Manage selection")
    }

    private func chips(_ t: Theme) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AlbumFilter.allCases, id: \.self) { f in
                    let on = model.filter == f
                    Button { model.filter = f } label: {
                        Text(f.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color(hex: on ? t.pillText : t.text))
                            .padding(.horizontal, 16).frame(minHeight: 44)
                            .background { if on { Capsule().fill(Color(hex: t.pillFill)) } }
                            .glassIf(!on, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
            .padding(.vertical, 2)
        }
        .scrollClipDisabled()
    }

    @ViewBuilder private func content(_ t: Theme) -> some View {
        let albums = model.visibleAlbums
        if !model.hasLoadedAlbums {
            Text("Loading albums…").foregroundStyle(Color(hex: t.textSecondary))
                .frame(maxWidth: .infinity).padding(.top, 40)
        } else if albums.isEmpty {
            Text("No photos to show here yet.").foregroundStyle(Color(hex: t.textSecondary))
                .frame(maxWidth: .infinity).padding(.top, 40)
        } else {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 14),
                                count: typeSize.isAccessibilitySize ? 1 : 2)
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(albums) { album in
                    Button { Task { await model.open(album) } } label: {
                        AlbumTile(album: album, loader: model.thumbnails)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

private extension View {
    @ViewBuilder func glassIf<S: InsettableShape>(_ on: Bool, in shape: S) -> some View {
        if on { glass(in: shape) } else { self }
    }
}

struct AlbumTile: View {
    let album: Album
    let loader: ThumbnailLoading
    @Environment(\.colorScheme) private var scheme
    @Environment(\.displayScale) private var displayScale
    @State private var image: CGImage?

    var body: some View {
        let t = Theme.resolve(scheme)
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let image {
                    Image(decorative: image, scale: displayScale).resizable().scaledToFill()
                } else {
                    Color(hex: t.blobs[0], opacity: 0.35)
                }
            }
            .overlay(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(album.title).font(.subheadline.weight(.semibold))
                    Text(album.count, format: .number).font(.footnote)
                        .foregroundStyle(Color(hex: t.textSecondary))
                }
                .foregroundStyle(Color(hex: t.text))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .glass(in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .padding(8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .task(id: album.coverID) {
                guard let id = album.coverID else { image = nil; return }
                image = await loader.thumbnail(id: id, side: 400)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(album.title), \(album.count) items")
            .accessibilityAddTraits(.isButton)
    }
}
