import SwiftUI
import SwipeCore
import SwipeUI

/// Opens only from Review, when more is marked than today's allowance (R-13).
struct PaywallSheet: View {
    let model: AppModel
    let marked: Int
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let t = Theme.resolve(scheme)
        let left = model.freeRemaining ?? 0
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Delete them all").font(.display(36)).foregroundStyle(Color(hex: t.text))
                    .accessibilityAddTraits(.isHeader)
                Text("Free plan deletes up to \(DeletionAllowance.dailyFree) photos a day. You've marked \(marked.formatted()).")
                    .foregroundStyle(Color(hex: t.textSecondary))
                VStack(spacing: 0) {
                    perk("infinity", "Unlimited deletions, every day", "No daily limit, ever.", t)
                    perk("creditcard", model.proPrice.map { "One-time \($0)" } ?? "One-time purchase",
                         "Paid once. No subscription.", t)
                    perk("sparkles", "Everything else stays the same", "Swiping, filters and Review are already free.", t)
                }
                .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))

                if let message = model.purchaseMessage {
                    Text(message).font(.footnote.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                        .accessibilityAddTraits(.updatesFrequently)
                }

                Button { Task { await model.unlockPro() } } label: {
                    HStack(spacing: 8) {
                        if model.isPurchasing { ProgressView().tint(Color(hex: t.pillText)) }
                        Text(unlockTitle).font(.body.weight(.semibold))
                    }
                    .foregroundStyle(Color(hex: t.pillText))
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Color(hex: t.pillFill), in: Capsule())
                    .opacity(model.proPrice == nil ? 0.5 : 1)
                }
                .buttonStyle(.plain)
                .disabled(model.proPrice == nil || model.isPurchasing)

                if left > 0 {
                    VStack(spacing: 4) {
                        Button { Task { model.dismissPaywall(); await model.confirmDelete(dropOverflow: true) } } label: {
                            Text("Delete \(left.formatted()) now").font(.body.weight(.semibold))
                                .foregroundStyle(Color(hex: t.text))
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .glass(in: Capsule())
                        }
                        .buttonStyle(.plain)
                        Text("The first \(left.formatted()) you marked. The rest are left alone.")
                            .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
                    }
                    .disabled(model.isPurchasing)
                }

                HStack {
                    Button("Restore Purchases") { Task { await model.restorePurchases() } }
                        .disabled(model.isPurchasing)
                    Spacer()
                    Button("Not now") { model.dismissPaywall() }
                }
                .font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                .frame(minHeight: 44)
            }
            .padding(20)
        }
        .appCanvas()
        .presentationBackground(.clear)
        .presentationCornerRadius(34)
        .presentationDragIndicator(.visible)
        .presentationDetents([.large])
    }

    private var unlockTitle: String {
        if let p = model.proPrice { return "Unlock Pro – \(p)" }
        return model.priceFailed ? "Price unavailable" : "Loading price…"
    }

    private func perk(_ icon: String, _ title: String, _ line: String, _ t: Theme) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color(hex: t.text)).frame(width: 40, height: 40)
                .background(Circle().fill(Color(hex: Theme.sage, opacity: 0.4)))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                Text(line).font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 10).frame(minHeight: 58)
        .accessibilityElement(children: .combine)
    }
}
