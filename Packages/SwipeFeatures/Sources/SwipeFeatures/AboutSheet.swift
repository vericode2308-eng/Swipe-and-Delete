import SwiftUI
import SwipeCore
import SwipeUI

/// Pro, Restore and Unlock rows arrive with purchases in Stage 7.
/// Rate and Privacy rows show only once the owner supplies the links.
struct AboutSheet: View {
    let model: AppModel
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss
    @State private var showsAcknowledgements = false

    var body: some View {
        let t = Theme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Lighter").font(.display(40)).foregroundStyle(Color(hex: t.text))
                    .accessibilityAddTraits(.isHeader)
                VStack(spacing: 0) {
                    row("Free · \(DeletionAllowance.dailyFree) deletions a day", t)
                    if let url = model.links.rateOnAppStore { divider(t); link("Rate on the App Store", url, t) }
                    if let url = model.links.privacyPolicy { divider(t); link("Privacy Policy", url, t) }
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
