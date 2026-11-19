import Testing
import SwipeCore
@testable import SwipeFeatures

struct LegalTests {
    private func text(_ d: LegalDocument) -> String {
        d.blocks.map {
            switch $0 { case .heading(let s), .paragraph(let s): s; case .bullets(let a): a.joined(separator: " ") }
        }.joined(separator: "\n")
    }
    private let full = AppLinks(supportEmail: "support@vericodestudio.com", developerName: "VeriCode", jurisdiction: "India")

    @Test func noPlaceholdersEverShow() {
        for d in [LegalDocument.privacy(), .terms(), .privacy(full), .terms(full)] {
            #expect(!text(d).contains("fill in") && !text(d).contains("["))
        }
    }
    @Test func missingDetailsAreLeftOut() {
        let t = text(.terms())
        #expect(!t.contains("Governing law") && !t.contains("Contact"))
        #expect(!text(.privacy()).contains("Contact"))
    }
    @Test func suppliedDetailsAppear() {
        let t = text(.terms(full)), p = text(.privacy(full))
        #expect(t.contains("laws of India") && t.contains("support@vericodestudio.com") && t.contains("VeriCode"))
        #expect(p.contains("support@vericodestudio.com") && p.contains("VeriCode"))
    }
    @Test func termsQuoteTheRealDailyLimit() {
        #expect(text(.terms()).contains("up to \(DeletionAllowance.dailyFree) items"))
    }
    @Test func scanDisclosureMatchesWhatIsStored() {
        let p = text(.privacy())
        for word in ["people", "feature print", "backups", "videos or screenshots"] { #expect(p.contains(word)) }
    }
}
