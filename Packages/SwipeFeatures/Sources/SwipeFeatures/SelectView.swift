import SwiftUI
#if os(iOS)
import UIKit
#endif
import SwipeCore
import SwipeUI

/// Pick many photos at once (D-24). Tapping a tile selects it for deletion;
/// "Review" hands the picks to the normal Review screen, so the single iOS
/// delete prompt and the free-plan limit work exactly as after swiping.
public struct SelectView: View {
    let model: AppModel
    let session: SwipeSession
    @Environment(\.colorScheme) private var scheme
    @State private var picked: Set<String> = []

    public init(model: AppModel, session: SwipeSession) { self.model = model; self.session = session }

    private var allIDs: [String] { session.assets.map(\.id) }
    private var allPicked: Bool { !allIDs.isEmpty && picked.count == allIDs.count }

    private let spacing: CGFloat = 4
    @State private var dragMode: Bool?       // true = selecting, false = deselecting
    @State private var lastIndex = 0
    @State private var scrollPos = ScrollPosition(edge: .top)
    @State private var offset: CGFloat = 0
    @State private var maxOffset: CGFloat = 0
    @State private var fingerX: CGFloat = 0
    @State private var fingerViewportY: CGFloat?

    public var body: some View {
        let t = Theme.resolve(scheme)
        VStack(spacing: 14) {
            header(t)
            GeometryReader { geo in
                let w = geo.size.width
                let cols = max(3, Int((w + spacing) / (100 + spacing)))
                let cell = (w - spacing * CGFloat(cols - 1)) / CGFloat(cols)
                ScrollView {
                    grid(cols: cols, cell: cell, width: w)
                        .padding(.bottom, 8)
                }
                .scrollPosition($scrollPos)
                .scrollIndicators(.visible)
                .scrollDisabled(dragMode != nil)
                .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, y in offset = y }
                .onScrollGeometryChange(for: CGFloat.self) { max(0, $0.contentSize.height - $0.containerSize.height) } action: { _, m in maxOffset = m }
                // While a drag-select is on, a finger near the top or bottom edge scrolls the list.
                .task(id: dragMode != nil) {
                    guard dragMode != nil else { return }
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .milliseconds(16))
                        guard let vy = fingerViewportY else { continue }
                        let zone: CGFloat = 80, h = geo.size.height
                        var dy: CGFloat = 0
                        if vy < zone { dy = -16 * min(1, (zone - vy) / zone) }
                        else if vy > h - zone { dy = 16 * min(1, (vy - (h - zone)) / zone) }
                        let next = min(maxOffset, max(0, offset + dy))
                        guard dy != 0, next != offset else { continue }
                        offset = next
                        scrollPos.scrollTo(y: next)
                        extend(to: CGPoint(x: fingerX, y: vy + next), cols: cols, cell: cell, width: w)
                    }
                }
            }
            footer(t)
        }
        .padding(.horizontal, 16).padding(.bottom, 8)
        .background { AppCanvas() }
        .onAppear { picked = Set(session.marked) }
    }

    /// Hit-testing is arithmetic on fixed cells, so a touch can only ever land on the tile drawn under it.
    private func grid(cols: Int, cell: CGFloat, width: CGFloat) -> some View {
        let assets = session.assets
        let columns = Array(repeating: GridItem(.fixed(cell), spacing: spacing), count: cols)
        func index(at p: CGPoint) -> Int? { cellIndex(p, cols: cols, cell: cell, width: width) }
        return LazyVGrid(columns: columns, spacing: spacing) {
            ForEach(Array(assets.enumerated()), id: \.element.id) { i, a in
                SelectTile(id: a.id, on: picked.contains(a.id), cell: cell, loader: model.images,
                           label: "Photo \(i + 1) of \(assets.count), \(picked.contains(a.id) ? "selected" : "not selected")") {
                    toggle(a.id)
                }
            }
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .gesture(SpatialTapGesture().onEnded { v in
            if let i = index(at: v.location) { toggle(assets[i].id) }
        })
        .swipeSelect(
            began: { p in
                guard let i = index(at: p) else { return }
                dragMode = !picked.contains(assets[i].id)
                track(p)
                lastIndex = i
                set(i...i, dragMode!)
            },
            moved: { p in
                track(p)
                extend(to: p, cols: cols, cell: cell, width: width)
            },
            ended: { dragMode = nil; fingerViewportY = nil })
    }

    private func cellIndex(_ p: CGPoint, cols: Int, cell: CGFloat, width: CGFloat) -> Int? {
        guard p.x >= 0, p.y >= 0, p.x < width else { return nil }
        let c = min(cols - 1, Int(p.x / (cell + spacing)))
        let i = Int(p.y / (cell + spacing)) * cols + c
        return i < session.assets.count ? i : nil
    }

    private func track(_ p: CGPoint) { fingerX = p.x; fingerViewportY = p.y - offset }

    /// Applies the drag's mode to every tile between the last one reached and the one under `p`.
    private func extend(to p: CGPoint, cols: Int, cell: CGFloat, width: CGFloat) {
        guard let mode = dragMode, let i = cellIndex(p, cols: cols, cell: cell, width: width) else { return }
        set(min(i, lastIndex)...max(i, lastIndex), mode)
        lastIndex = i
    }

    private func toggle(_ id: String) {
        if picked.contains(id) { picked.remove(id) } else { picked.insert(id) }
    }

    private func set(_ range: ClosedRange<Int>, _ on: Bool) {
        let a = session.assets
        for i in range where i < a.count {
            if on { picked.insert(a[i].id) } else { picked.remove(a[i].id) }
        }
    }

    private func header(_ t: Theme) -> some View {
        HStack(spacing: 12) {
            Button { model.endSelect() } label: {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color(hex: t.text)).frame(width: 44, height: 44).glass(in: Circle())
            }
            .accessibilityLabel("Back to swiping")
            VStack(alignment: .leading, spacing: 2) {
                Text("\(picked.count.formatted()) selected").font(.display(30))
                    .foregroundStyle(Color(hex: t.text)).lineLimit(1).minimumScaleFactor(0.7)
                    .accessibilityAddTraits(.isHeader)
                Text("Tap or swipe across photos. Back cancels.").font(.footnote)
                    .foregroundStyle(Color(hex: t.textSecondary))
            }
            Spacer(minLength: 0)
            Button { picked = allPicked ? [] : Set(allIDs) } label: {
                Text(allPicked ? "Clear" : "Select all").font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color(hex: t.text))
                    .padding(.horizontal, 14).frame(minHeight: 44).glass(in: Capsule())
            }
        }
        .padding(.top, 4)
    }

    private func footer(_ t: Theme) -> some View {
        Button { apply(); model.endSelect(); model.beginReview() } label: {
            Text(picked.isEmpty ? "Select photos to delete"
                                : "Review \(picked.count.formatted()) photo\(picked.count == 1 ? "" : "s")")
                .font(.body.weight(.semibold))
                .foregroundStyle(Color(hex: Theme.onFill))
                .padding(.vertical, 12).padding(.horizontal, 20)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color(hex: Theme.blush), in: Capsule())
                .opacity(picked.isEmpty ? 0.45 : 1)
        }
        .buttonStyle(.plain)
        .disabled(picked.isEmpty)
    }

    /// The session's marks follow the picks.
    private func apply() {
        for id in allIDs { picked.contains(id) ? session.mark(id) : session.unmark(id) }
    }
}


/// One cell. Takes only its own state, so a pick re-draws one tile, not the whole grid.
private struct SelectTile: View, Equatable {
    let id: String
    let on: Bool
    let cell: CGFloat
    let loader: PhotoImageLoading
    let label: String
    let toggle: () -> Void

    nonisolated static func == (l: Self, r: Self) -> Bool { l.id == r.id && l.on == r.on && l.cell == r.cell }

    var body: some View {
        PhotoImage(id: id, pointSize: CGSize(width: 120, height: 120), loader: loader)
            .frame(width: cell, height: cell)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                if on {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(hex: Theme.blush, opacity: 0.35))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color(hex: Theme.blush), lineWidth: 3))
                }
            }
            .overlay(alignment: .topTrailing) {
                Image(systemName: on ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(on ? Color(hex: Theme.blush) : Color.white.opacity(0.9))
                    .shadow(radius: 2).padding(5)
            }
            .allowsHitTesting(false)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityAddTraits(on ? [.isButton, .isSelected] : .isButton)
            .accessibilityAction { toggle() }
    }
}

private extension View {
    @ViewBuilder func swipeSelect(began: @escaping (CGPoint) -> Void, moved: @escaping (CGPoint) -> Void,
                                  ended: @escaping () -> Void) -> some View {
        #if os(iOS)
        gesture(HorizontalSwipeSelect(began: began, moved: moved, ended: ended))
        #else
        self
        #endif
    }
}

#if os(iOS)
/// Photos-style drag select: starts only when the finger moves mostly sideways,
/// so up and down still scrolls.
private struct HorizontalSwipeSelect: UIGestureRecognizerRepresentable {
    let began: (CGPoint) -> Void
    let moved: (CGPoint) -> Void
    let ended: () -> Void

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard let pan = g as? UIPanGestureRecognizer, let v = pan.view else { return false }
            let t = pan.translation(in: v)
            return abs(t.x) > abs(t.y)
        }
        func gestureRecognizer(_ a: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith b: UIGestureRecognizer) -> Bool { true }
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let g = UIPanGestureRecognizer()
        g.maximumNumberOfTouches = 1
        g.delegate = context.coordinator
        return g
    }

    func handleUIGestureRecognizerAction(_ g: UIPanGestureRecognizer, context: Context) {
        let p = context.converter.localLocation
        switch g.state {
        case .began: began(p)
        case .changed: moved(p)
        case .ended, .cancelled, .failed: ended()
        default: break
        }
    }
}
#endif
