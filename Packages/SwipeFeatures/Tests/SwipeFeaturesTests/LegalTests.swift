import Foundation
import Testing
@testable import SwipeFeatures

struct LegalTests {
    private func text(_ d: LegalDocument) -> String {
        d.blocks.map {
            switch $0 { case .heading(let s), .paragraph(let s): s; case .bullets(let a): a.joined(separator: " ") }
        }.joined(separator: "\n")
    }
    private func repoFile(_ name: String) throws -> String {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return try String(contentsOf: root.appendingPathComponent("legal/\(name).md"), encoding: .utf8)
    }

    /// The in-app copy must be the same file as the one published from `legal/`.
    @Test func bundledCopiesMatchLegalFolder() throws {
        for name in ["PRIVACY_POLICY", "TERMS_OF_USE"] {
            let bundled = try String(contentsOf: #require(Bundle.module.url(forResource: name, withExtension: "md", subdirectory: "Legal")), encoding: .utf8)
            #expect(bundled == (try repoFile(name)))
        }
    }
    @Test func documentsParse() {
        #expect(LegalDocument.privacy.title == "Privacy Policy" && LegalDocument.terms.title == "Terms of Use")
        for d in [LegalDocument.privacy, .terms] {
            #expect(d.blocks.count > 10)
            #expect(!text(d).contains("| ---") && !text(d).contains("fill in") && !text(d).contains("[ "))
        }
    }
    @Test func scanDisclosureMatchesWhatIsStored() {
        let p = text(.privacy)
        for word in ["people", "fingerprints", "identifier"] { #expect(p.contains(word)) }
    }
}
