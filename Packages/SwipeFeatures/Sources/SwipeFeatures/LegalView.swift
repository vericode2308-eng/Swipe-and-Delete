import SwiftUI
import SwipeCore
import SwipeUI

/// Reads a Privacy Policy or Terms of Use in the app, with no network.
struct LegalView: View {
    let document: LegalDocument
    var onlineURL: URL?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let t = Theme.resolve(scheme)
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(document.title).font(.display(36)).foregroundStyle(Color(hex: t.text))
                    .accessibilityAddTraits(.isHeader)
                    .padding(.trailing, 64)      // clear of the Done button
                ForEach(Array(document.blocks.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .heading(let text):
                        Text(text).font(.headline).foregroundStyle(Color(hex: t.text))
                            .accessibilityAddTraits(.isHeader).padding(.top, 10)
                    case .paragraph(let text):
                        Text(markdown(text)).font(.body).foregroundStyle(Color(hex: t.text))
                    case .bullets(let items):
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                HStack(alignment: .firstTextBaseline, spacing: 10) {
                                    Text("•").accessibilityHidden(true)
                                    Text(markdown(item))
                                }
                                .font(.body).foregroundStyle(Color(hex: t.text))
                                .accessibilityElement(children: .combine)
                            }
                        }
                    }
                }
                if let onlineURL {
                    Link(destination: onlineURL) {
                        HStack {
                            Text("Read online"); Spacer()
                            Image(systemName: "arrow.up.right").font(.footnote.weight(.semibold))
                        }
                        .foregroundStyle(Color(hex: t.text))
                        .padding(.horizontal, 16).frame(minHeight: 52)
                    }
                    .glass(in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .padding(.top, 12)
                }
            }
            .frame(maxWidth: 640, alignment: .leading)
            .frame(maxWidth: .infinity)
            .padding(20)
            .padding(.top, 24)
        }
        .appCanvas()
        .presentationBackground(.clear)
        .overlay(alignment: .topTrailing) {
            Button("Done") { dismiss() }
                .font(.body.weight(.semibold)).foregroundStyle(Color(hex: t.text))
                .frame(minWidth: 44, minHeight: 44).padding(.trailing, 12).padding(.top, 8)
        }
    }

    private func markdown(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(s)
    }
}
