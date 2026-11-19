import SwiftUI
import SwipeCore
import SwipeUI

/// Settings (D-24, D-25; replaces the About sheet, supersedes D-16): the space
/// cleared so far, Pro and Restore, Appearance, and legal and support links.
/// Links the owner has not supplied yet stay hidden.
struct SettingsView: View {
    let model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.dismiss) private var dismiss
    @State private var legal: LegalDocument?

    var body: some View {
        let t = Theme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header(t)
                clearedCard(t)
                section("Lighter Pro", t) { planRows(t) }
                section("Appearance", t) { appearancePicker(t) }
                section("About", t) { aboutRows(t) }
                if !model.appVersion.isEmpty {
                    Text("Lighter \(model.appVersion)").font(.footnote)
                        .foregroundStyle(Color(hex: t.textSecondary))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 32)
        }
        .scrollBounceBehavior(.basedOnSize)
        .appCanvas()
        .onAppear { model.dismissPaywallMessage() }
        .sheet(item: $legal) { doc in
            LegalView(document: doc, onlineURL: doc.title == "Privacy Policy" ? model.links.privacyPolicy : model.links.termsOfUse)
        }
        .presentationDetents([.large])
        .presentationBackground(.clear)
    }

    // MARK: Header

    private func header(_ t: Theme) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text("Settings").font(.display(44)).foregroundStyle(Color(hex: t.text))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 12)
            Button("Done") { dismiss() }
                .font(.body.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.top, 12)
    }

    // MARK: Cleared so far

    private func clearedCard(_ t: Theme) -> some View {
        let stats = model.lifetime
        return VStack(alignment: .leading, spacing: 8) {
            Text("Cleared so far").font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: t.textSecondary))
                .accessibilityAddTraits(.isHeader)
            if stats.isEmpty {
                Text("Nothing yet").font(.display(40)).foregroundStyle(Color(hex: t.text))
                Text("Your total appears here after your first delete.")
                    .font(.subheadline).foregroundStyle(Color(hex: t.textSecondary))
            } else {
                if stats.freedBytes > 0 {
                    Text(Formatting.size(stats.freedBytes)).font(.display(48))
                        .foregroundStyle(Color(hex: t.text))
                    Text("from \(stats.deleted.formatted()) \(stats.deleted == 1 ? "photo or video" : "photos and videos") since you started.")
                        .font(.subheadline).foregroundStyle(Color(hex: t.textSecondary))
                    Text(Formatting.roomForPhotos(freedBytes: stats.freedBytes))
                        .font(.subheadline.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                        .padding(.top, 4)
                } else {
                    Text("\(stats.deleted.formatted())").font(.display(48))
                        .foregroundStyle(Color(hex: t.text))
                    Text(stats.deleted == 1 ? "photo or video deleted since you started." : "photos and videos deleted since you started.")
                        .font(.subheadline).foregroundStyle(Color(hex: t.textSecondary))
                }
                Text("Space returns once Recently Deleted empties.")
                    .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
                    .padding(.top, 2)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    // MARK: Sections

    private func section<Content: View>(_ title: String, _ t: Theme,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: t.textSecondary))
                .padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content() }
                .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
    }

    @ViewBuilder private func planRows(_ t: Theme) -> some View {
        row(model.isPro ? "Lighter Pro · unlimited deletions"
                        : "Free · \(DeletionAllowance.dailyFree) deletions a day", t)
        if model.hasStore {
            if !model.isPro {
                divider(t)
                action(model.proPrice.map { "Unlock Pro – \($0)" }
                       ?? (model.priceFailed ? "Price unavailable" : "Loading price…"), t,
                       enabled: model.proPrice != nil) { await model.unlockPro() }
            }
            divider(t)
            action("Restore Purchases", t) { await model.restorePurchases() }
            if let m = model.purchaseMessage {
                Text(m).font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
                    .padding(.horizontal, 16).padding(.bottom, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityAddTraits(.updatesFrequently)
            }
        }
    }

    @ViewBuilder private func aboutRows(_ t: Theme) -> some View {
        Button { model.openPhotoSettings() } label: {
            HStack {
                Text("Photo Access"); Spacer()
                Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 52)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens this app's page in iOS Settings")
        if let url = model.links.rateOnAppStore { divider(t); link("Rate on the App Store", url, t) }
        if let email = model.links.supportEmail, let url = URL(string: "mailto:\(email)") {
            divider(t); link("Contact Support", url, t)
        }
        if let url = model.links.supportPage { divider(t); link("Support Page", url, t) }
        // Once the pages are hosted these open in the browser; until then the bundled copy opens in the app.
        divider(t)
        if let url = model.links.privacyPolicy { link("Privacy Policy", url, t) }
        else { legalRow("Privacy Policy", t) { legal = .privacy } }
        divider(t)
        if let url = model.links.termsOfUse { link("Terms of Use", url, t) }
        else { legalRow("Terms of Use", t) { legal = .terms } }
    }

    private func legalRow(_ title: String, _ t: Theme, _ open: @escaping () -> Void) -> some View {
        Button(action: open) {
            HStack {
                Text(title); Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 52)
        }
        .buttonStyle(.plain)
    }

    // MARK: Appearance

    /// Custom control: the system segmented picker does not scale with Dynamic Type,
    /// so at accessibility sizes the three choices stack.
    private func appearancePicker(_ t: Theme) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 8)) : AnyLayout(HStackLayout(spacing: 8))
        return layout {
            ForEach(AppearanceSetting.allCases, id: \.self) { option in
                let selected = model.appearance == option
                Button { model.setAppearance(option) } label: {
                    HStack(spacing: 6) {
                        if selected { Image(systemName: "checkmark").font(.footnote.weight(.bold)) }
                        Text(option.title)
                    }
                    .font(.body.weight(selected ? .semibold : .regular))
                    .foregroundStyle(Color(hex: t.text))
                    .frame(maxWidth: .infinity, minHeight: 44)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color(hex: t.text, opacity: selected ? 0.16 : 0.0))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color(hex: t.text, opacity: selected ? 0.5 : 0.15), lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
                .accessibilityLabel("\(option.title) appearance")
            }
        }
        .padding(12)
    }

    // MARK: Rows

    private func row(_ text: String, _ t: Theme) -> some View {
        Text(text).foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 16).padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
    }

    private func action(_ title: String, _ t: Theme, enabled: Bool = true,
                        _ run: @escaping () async -> Void) -> some View {
        Button { Task { await run() } } label: {
            Text(title).foregroundStyle(Color(hex: t.text))
                .padding(.horizontal, 16).padding(.vertical, 8)
                .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!enabled || model.isPurchasing)
        .opacity(enabled ? 1 : 0.5)
    }

    private func link(_ title: String, _ url: URL, _ t: Theme) -> some View {
        Link(destination: url) {
            HStack {
                Text(title); Spacer()
                Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 16).padding(.vertical, 8).frame(minHeight: 52)
        }
    }

    private func divider(_ t: Theme) -> some View {
        Rectangle().fill(Color(hex: t.text, opacity: 0.12)).frame(height: 1).padding(.horizontal, 16)
    }
}
