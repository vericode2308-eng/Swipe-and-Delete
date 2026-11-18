import SwiftUI

public struct PillButton: View {
    let title: String
    let action: () -> Void
    @Environment(\.colorScheme) private var scheme
    public init(_ title: String, action: @escaping () -> Void) { self.title = title; self.action = action }
    public var body: some View {
        let t = Theme.resolve(scheme)
        Button(action: action) {
            Text(title).font(.body.weight(.semibold)).multilineTextAlignment(.center).padding(.vertical, 12).padding(.horizontal, 20)
                .foregroundStyle(Color(hex: t.pillText))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Color(hex: t.pillFill), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
