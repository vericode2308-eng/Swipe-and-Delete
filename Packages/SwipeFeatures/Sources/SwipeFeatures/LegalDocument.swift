import Foundation

/// The Privacy Policy and Terms of Use, readable in the app with no network.
/// The text is the bundled copy of `legal/*.md`; a test keeps the two identical.
public struct LegalDocument: Equatable, Identifiable, Sendable {
    public var id: String { title }
    public enum Block: Equatable, Sendable {
        case heading(String)
        case paragraph(String)
        case bullets([String])
    }

    public let title: String
    public let blocks: [Block]

    public static var privacy: LegalDocument { load("PRIVACY_POLICY", fallback: "Privacy Policy") }
    public static var terms: LegalDocument { load("TERMS_OF_USE", fallback: "Terms of Use") }

    static func load(_ name: String, fallback: String) -> LegalDocument {
        guard let url = Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Legal"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            return LegalDocument(title: fallback, blocks: [.paragraph("This document could not be loaded.")])
        }
        return parse(text, fallback: fallback)
    }

    /// Small Markdown reader: `#` title, `##` headings, `-` bullets, tables as bullets, the rest paragraphs.
    static func parse(_ markdown: String, fallback: String) -> LegalDocument {
        var title = fallback
        var blocks: [Block] = []
        var para: [String] = []
        var bullets: [String] = []
        func flush() {
            if !para.isEmpty { blocks.append(.paragraph(para.joined(separator: "\n"))); para = [] }
            if !bullets.isEmpty { blocks.append(.bullets(bullets)); bullets = [] }
        }
        for raw in markdown.components(separatedBy: "\n") {
            let line = raw.trimmingCharacters(in: .whitespaces)
            if line.isEmpty { flush(); continue }
            if line.hasPrefix("## ") { flush(); blocks.append(.heading(String(line.dropFirst(3)))) }
            else if line.hasPrefix("# ") { title = String(line.dropFirst(2)).replacingOccurrences(of: "Lighter — ", with: "") }
            else if line.hasPrefix("- ") { if !para.isEmpty { flush() }; bullets.append(String(line.dropFirst(2))) }
            else if line.hasPrefix("|") {
                let cells = line.split(separator: "|", omittingEmptySubsequences: true)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                if cells.allSatisfy({ $0.allSatisfy { "-: ".contains($0) } }) { continue }
                if cells.first == "Information" { continue }
                if !para.isEmpty { flush() }
                bullets.append(cells.count >= 2 ? "**\(cells[0]).** \(cells[1...].joined(separator: " "))" : cells.joined())
            } else { if !bullets.isEmpty { flush() }; para.append(line) }
        }
        flush()
        return LegalDocument(title: title, blocks: blocks)
    }
}
