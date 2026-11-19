import SwiftUI
import SwipeCore
import SwipeUI

/// Pro status, Unlock and Restore (R-14).
/// Also Photo Access, Support, Privacy Policy and Terms of Use (D-27).
/// Rate and Support rows show only once the owner supplies the link or email.
struct AboutSheet: View {
    let model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var showsAcknowledgements = false
    @State private var legal: LegalDocument?

    var body: some View {
        let t = Theme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Lighter").font(.display(40)).foregroundStyle(Color(hex: t.text))
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    row(model.isPro ? "Lighter Pro · unlimited deletions" : "Free · \(DeletionAllowance.dailyFree) deletions a day", t)
                    if model.hasStore {
                        if !model.isPro {
                            divider(t)
                            action(model.proPrice.map { "Unlock Pro – \($0)" } ?? (model.priceFailed ? "Price unavailable" : "Loading price…"), t,
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
                    divider(t)
                    Button { model.openPhotoSettings() } label: {
                        HStack {
                            Text("Photo Access"); Spacer()
                            Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold))
                        }
                        .foregroundStyle(Color(hex: t.text))
                        .padding(.horizontal, 16).frame(minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens this app's page in iOS Settings")
                    if let url = model.links.rateOnAppStore { divider(t); link("Rate on the App Store", url, t) }
                    if let email = model.links.supportEmail, let url = URL(string: "mailto:\(email)") {
                        divider(t); link("Contact Support", url, t)
                    }
                    divider(t)
                    legalRow("Privacy Policy", t) { legal = .privacy(model.links) }
                    divider(t)
                    legalRow("Terms of Use", t) { legal = .terms(model.links) }
                    divider(t)
                    Button { withAnimation { showsAcknowledgements.toggle() } } label: {
                        HStack {
                            Text("Acknowledgements")
                            Spacer()
                            Image(systemName: showsAcknowledgements ? "chevron.up" : "chevron.down")
                                .font(.footnote.weight(.semibold))
                        }
                        .foregroundStyle(Color(hex: t.text))
                        .padding(.horizontal, 16).frame(minHeight: 52)
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(showsAcknowledgements ? "Collapse" : "Expand")
                    if showsAcknowledgements {
                        Text("Titles are set in Cormorant Garamond, © 2015 the Cormorant Project Authors, used under the SIL Open Font License, Version 1.1.")
                            .font(.footnote).foregroundStyle(Color(hex: t.textSecondary))
                            .padding(.horizontal, 16).padding(.bottom, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                if !model.appVersion.isEmpty {
                    Text("Version \(model.appVersion)").font(.footnote)
                        .foregroundStyle(Color(hex: t.textSecondary))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .appCanvas()
        .onAppear { model.dismissPaywallMessage() }
        .sheet(item: $legal) { doc in
            LegalView(document: doc, onlineURL: doc.title == "Privacy Policy" ? model.links.privacyPolicy : model.links.termsOfUse)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.clear)
        .overlay(alignment: .topTrailing) {
            Button("Done") { dismiss() }
                .font(.body.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                .frame(minWidth: 44, minHeight: 44).padding(.trailing, 12).padding(.top, 8)
        }
    }

    private func row(_ text: String, _ t: Theme) -> some View {
        Text(text).foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
    }

    private func action(_ title: String, _ t: Theme, enabled: Bool = true,
                        _ run: @escaping () async -> Void) -> some View {
        Button { Task { await run() } } label: {
            Text(title).foregroundStyle(Color(hex: t.text))
                .padding(.horizontal, 16).frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        }
        .buttonStyle(.plain)
        .disabled(!enabled || model.isPurchasing)
        .opacity(enabled ? 1 : 0.5)
    }

    private func legalRow(_ title: String, _ t: Theme, _ open: @escaping () -> Void) -> some View {
        Button(action: open) {
            HStack {
                Text(title); Spacer()
                Image(systemName: "chevron.right").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 16).frame(minHeight: 52)
        }
        .buttonStyle(.plain)
    }

    private func link(_ title: String, _ url: URL, _ t: Theme) -> some View {
        Link(destination: url) {
            HStack {
                Text(title); Spacer()
                Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold))
            }
            .foregroundStyle(Color(hex: t.text))
            .padding(.horizontal, 16).frame(minHeight: 52)
        }
    }

    private func divider(_ t: Theme) -> some View {
        Rectangle().fill(Color(hex: t.text, opacity: 0.12)).frame(height: 1).padding(.horizontal, 16)
    }
}
