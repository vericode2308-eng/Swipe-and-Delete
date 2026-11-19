import Foundation
import SwipeCore

/// The Privacy Policy and Terms of Use, readable in the app with no network.
/// The same text lives in `legal/*.md` for the web pages; keep them in step.
/// Details the owner has not supplied yet (developer name, support email,
/// jurisdiction) are left out of the text instead of shown as placeholders.
public struct LegalDocument: Equatable, Identifiable, Sendable {
    public var id: String { title }
    public enum Block: Equatable, Sendable {
        case heading(String)
        case paragraph(String)
        case bullets([String])
    }

    public let title: String
    public let updated: String
    public let blocks: [Block]

    public static let lastUpdated = "19 November 2026"

    public static func privacy(_ links: AppLinks = AppLinks()) -> LegalDocument {
        let publisher = links.developerName.map { "**\($0)**" } ?? "the developer of Lighter"
        var b: [Block] = [
            .paragraph("Lighter (“the app”) is an iPhone app that helps you review your photos and delete the ones you don't want. It is published by \(publisher) (“we”, “us”)."),
            .heading("The short version"),
            .bullets([
                "Lighter does not collect your data. We have no servers, no accounts and no analytics.",
                "Your photos are never uploaded, copied or sent anywhere by Lighter. All processing happens on your iPhone.",
                "We do not track you and we share nothing with third parties.",
            ]),
            .heading("What the app accesses"),
            .paragraph("Your photo library. Lighter asks for permission to your Photos so it can show your photos and videos, let you mark them to keep or delete, and delete the ones you confirm. You can choose full access or a limited selection, and you can change this at any time in iOS Settings > Photos > Lighter. Lighter only reads photos to display them and to analyse them on your device, and only deletes after you confirm in the standard iOS prompt."),
            .paragraph("iCloud photos. If a photo is stored in iCloud Photos and not on your iPhone, iOS may download it from iCloud so Lighter can show it to you. This is done by Apple's Photos service under your Apple Account. Lighter's own analysis never downloads from iCloud: it uses only copies already on your iPhone and skips the rest. Lighter does not send any photo to us or to anyone else."),
            .heading("What the app stores on your device"),
            .paragraph("All of the following stays on your iPhone and is removed when you delete the app:"),
            .bullets([
                "Daily deletion count and date, to apply the free plan's daily limit.",
                "Rating-prompt state (for example, how many albums you finished and when you last saw the prompt), so the app does not ask for a rating too often.",
                "Clean-up scan results. Quick clean-up analyses your photos (not videos or screenshots) on your iPhone using Apple's Vision framework to find duplicates and pages and things. For each photo it saves the photo's Photos-library identifier, its dates, whether it appears to show people, whether it looks like a page or note, a quality score, and two numeric fingerprints (a small hash and a Vision feature print). These cannot be turned back into the picture. They are saved in the app's private storage on your iPhone so the scan does not repeat, and we never receive them. Like other app data, they may be included in your iPhone backups (iCloud or computer), which Apple handles under your settings and Apple Account.",
                "Photos you have marked during a session are held only while you review them.",
            ]),
            .heading("Purchases"),
            .paragraph("Lighter offers an optional one-time in-app purchase, Lighter Pro. Payments are handled entirely by Apple through the App Store. We never see or store your payment details. The app checks your purchase status with Apple's StoreKit so it knows whether Pro is unlocked, and “Restore Purchases” asks Apple to confirm a previous purchase. Apple's own privacy policy governs that processing."),
            .heading("Data we collect, share or sell"),
            .paragraph("None. We do not collect personal data, we do not use advertising or analytics, we do not include third-party SDKs, and we do not sell or share any data. The app does not track you across other companies' apps or websites."),
            .heading("Children"),
            .paragraph("Lighter is not directed at children and collects no personal information from anyone, including children."),
            .heading("Your choices and rights"),
            .paragraph("Because we hold no data about you, there is nothing for us to export or erase. You control everything through iOS: revoke photo access in Settings, and delete the app to remove all data it stored. Photos you delete go to Recently Deleted in the Photos app for 30 days, where you can restore them. With iCloud Photos turned on, deletions also apply to your other devices signed in to the same Apple Account."),
            .heading("Changes"),
            .paragraph("If this policy changes we will update the date above and publish the new version in the app. Material changes will also be noted in the App Store listing or the app."),
        ]
        if let email = links.supportEmail {
            b += [.heading("Contact"), .paragraph("Questions about this policy: \(email)")]
        }
        return LegalDocument(title: "Privacy Policy", updated: lastUpdated, blocks: b)
    }

    public static func terms(_ links: AppLinks = AppLinks()) -> LegalDocument {
        let publisher = links.developerName.map { "**\($0)**" } ?? "the developer of Lighter"
        let limit = DeletionAllowance.dailyFree
        var b: [Block] = [
            .paragraph("These terms apply to your use of Lighter (“the app”), published by \(publisher) (“we”, “us”). By downloading or using the app you agree to them."),
            .heading("Apple's standard licence"),
            .paragraph("The app is licensed to you under Apple's Standard End User Licence Agreement (“Standard EULA”) for Apple-branded apps: https://www.apple.com/legal/internet-services/itunes/dev/stdeula/ . These terms add to it. If they conflict, the Standard EULA prevails."),
            .heading("What the app does"),
            .paragraph("Lighter lets you review the photos and videos in your Photos library and delete the ones you choose. It also offers a Quick clean-up that suggests duplicates and pages and things, and a shortcut to your WhatsApp album. Suggestions are only suggestions: you decide what to delete."),
            .heading("You are responsible for your photos"),
            .bullets([
                "Nothing is deleted until you confirm in the iOS prompt.",
                "Deleted items go to Recently Deleted in the Photos app and are removed permanently after 30 days unless you restore them earlier.",
                "If iCloud Photos is on, deletions also apply to your other devices signed in to the same Apple Account.",
                "Back up anything you can't afford to lose. We are not responsible for photos you choose to delete, or for suggestions that turn out to be wrong.",
            ]),
            .heading("Free plan and Lighter Pro"),
            .bullets([
                "The app is free to download. The free plan lets you review any number of photos and delete up to \(limit) items (photos or videos) per day (the day resets at local midnight).",
                "Lighter Pro is an optional, one-time, non-subscription purchase that removes the daily limit. The price is shown in the App Store and in the app before you buy.",
                "Payment is charged to your Apple Account at confirmation of purchase. Pro is not a subscription and does not renew.",
                "Pro is tied to your Apple Account. You can restore it on other devices with the same account using Restore Purchases.",
                "Refunds are handled by Apple under its own policies; request one at reportaproblem.apple.com.",
            ]),
            .heading("Acceptable use"),
            .paragraph("Do not copy, modify, reverse engineer or redistribute the app except as permitted by law or the Standard EULA, and do not use it to break any law."),
            .heading("Privacy"),
            .paragraph("How the app handles data is described in the Privacy Policy. In short, your photos stay on your device and we collect no personal data."),
            .heading("No warranty"),
            .paragraph("The app is provided “as is” and “as available”. To the extent the law allows, we make no warranty that it will be error-free or uninterrupted, and we are not liable for indirect or consequential loss, including loss of photos or data. Nothing here limits any right you have under law that cannot be excluded."),
            .heading("Changes"),
            .paragraph("We may update these terms. The date above shows the current version. Continued use after an update means you accept it."),
        ]
        if let place = links.jurisdiction {
            b += [.heading("Governing law"),
                  .paragraph("These terms are governed by the laws of \(place), without affecting any mandatory consumer rights you have where you live.")]
        }
        if let email = links.supportEmail { b += [.heading("Contact"), .paragraph(email)] }
        return LegalDocument(title: "Terms of Use", updated: lastUpdated, blocks: b)
    }
}
