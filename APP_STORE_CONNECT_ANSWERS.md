# App Store Connect: fill-in answers for Lighter

Written 24 November 2026 from the code, `APP_PLAN.md`, `ASO_PLAN.md`, `RELEASE_CHECKLIST.md` and `MASTER.md` (Change 42). Same page order as the Focus Four Pro template. Items marked **OWNER** need your decision. Items marked **CHECK** may change when the app changes.

Rule applied throughout: nothing is advertised until it is built and verified in the build (CLAUDE.md 10.2). Quick clean-up (Duplicates, Pages & Things, From WhatsApp) is built, but its accuracy on a large library is still an open device check, so it is **left out of the listing for 1.0** and can be added in a later update.

## 1. App Information

| Field | Answer |
|---|---|
| Name (29/30) | `Lighter – Swipe Photo Cleaner` (en dash; D-28) |
| Subtitle (29/30) | `Delete Pics & Free Up Storage` |
| Primary category | Photo & Video |
| Secondary category | Utilities (optional) |
| Content Rights | No, it does not contain, show or access third-party content (it shows the user's own photos only) |
| License agreement | Standard Apple EULA |
| Bundle ID, SKU, Apple ID, language | Locked: `com.vericodestudio.lighter`, English (U.S.) |

### Age rating: Capabilities
| Capability | Answer |
|---|---|
| Unrestricted Web Access | **No** (Settings links open Safari; there is no in-app browser) |
| User-Generated Content | **No** |
| Social Media | **No** |
| Messaging and Chat | **No** |
| Advertising | **No** |
| Parental controls / age assurance | No |

All content questions: None / No. Expected rating 4+. If the console shows more, stop and ask. **OWNER:** the Terms assume a 13+ audience (open question in APP_PLAN). The 4+ rating is about content; make sure the Terms and the rating do not contradict each other.

## 2. App Privacy
**Do you collect data? No → "Data Not Collected".** Then click **Publish**.

Why: the code has no network calls, SDKs or analytics (security audit 2026-11-18). Photos are read and analysed on the iPhone (Apple Vision) and never leave it. The only stored data is on-device settings (`UserDefaults`: daily count, totals, appearance, scan results). The purchase is handled by Apple. `PrivacyInfo.xcprivacy` matches: tracking false, no collected data types, UserDefaults reason CA92.1.

| Field | Answer |
|---|---|
| Privacy Policy URL | `https://vericodestudio.com/products/lighter/privacy/` |
| User Privacy Choices URL | Empty |

**CHECK before submitting:** Change 41 says the live pages were not compared with the current `legal/` text, and the VeriCode site copy still has the old section 8 wording. Copy the rebuilt files in and deploy first.

### App Accessibility (labels are optional; tick only what is verified)
| Feature | Answer | Reason |
|---|---|---|
| Dark Interface | **Yes** | Light, Dark and System appearance; screenshots exist in both |
| Reduced Motion | **Yes** | `accessibilityReduceMotion` handled in 4 files |
| Larger Text | **Yes, with a caveat** | AX5 screenshot exists for Albums only. Tick after one more AX5 pass of Swipe, Review and Settings |
| VoiceOver | **Not yet** | Labels, hints and traits are in the code, but the full-album VoiceOver pass is still an open device check |
| Voice Control | Not yet | Not tested |
| Differentiate Without Color Alone | Not yet | The code never reads the setting; the design uses icon plus word, but this is unverified |
| Sufficient Contrast | Not yet | The brief sets ≥ 4.5:1, but the shipped build was not measured |
| Captions, Audio Descriptions | No | Not applicable (the app does not supply video) |

## 3. Pricing and Availability

| Field | Answer |
|---|---|
| Price | **Free** (free download with one-time Pro, D-10) |
| Availability | All regions you can handle tax for |
| Pre-orders | Off |
| Paid Apps agreement, tax, banking | **Required**, because of the in-app purchase |
| EU trader status | **OWNER:** declare trader or non-trader. You sell a paid unlock under a business name, so trader is the likely answer; the address then shows publicly in the EU |

### In-app purchase: Lighter Pro (create this before submitting)
| Field | Answer |
|---|---|
| Type | **Non-Consumable** (the form defaults to Consumable) |
| Reference name | `Lighter Pro` |
| Product ID | `com.vericodestudio.lighter.pro` (exactly as in `StoreKitPurchases.swift` and `Products.storekit`; cannot change later) |
| Price | **$4.99 USD** base price (D-12); check the regional prices Apple generates |
| Display name (11/30) | `Lighter Pro` |
| Description (41/45) | `Unlimited deletions every day. Paid once.` |
| Family Sharing | **On in App Store Connect** (owner's choice; cannot be turned off once on). `Products.storekit` still says `familyShareable: false`, which only affects Xcode testing |
| Availability | Same as the app |
| Review screenshot | Full-size capture (1206×2622) of the paywall **with the real price loaded**. Captured: `media/screenshots/05-paywall-dark.png` (1206×2622, RGB, shows "Unlock Pro – $4.99"). To redo it: Select all in Recents with 51+ photos, Review, Delete |
| Review notes | `Unlocks unlimited deletions per day (free plan: 50 a day). To see it: in any album mark more than 50 photos, open Review and tap Delete; the paywall appears. Restore Purchases is in Settings (gear on the Albums screen).` |

Notes:
- The description in `Products.storekit` is 56 characters, over Apple's 45. It is a local test file only; the App Store Connect text above is what counts. Say if you want the file shortened to match.
- The first IAP must go in with the app version: on the version page, add it under In-App Purchases and Subscriptions and submit both together.
- Ignore the Subscriptions page. Apply for the Small Business Program (15%).

## 4. App Compliance
| Question | Answer |
|---|---|
| Uses encryption | None of its own (the app makes no network calls). `ITSAppUsesNonExemptEncryption = NO` is set, so the question should not appear. If it does: exempt, no documents |
| China mainland notices | Only if distributed there. **OWNER:** simplest is to exclude China mainland, or ask me |
| Digital Services Act (EU trader) | See section 3 |

## 5. Version page (iOS App Version 1.0.0)

### Screenshots
- iPhone (6.9" or 6.5" set): up to 10 PNGs, RGB, no alpha, readable at thumbnail size. iPad: empty (iPhone-only app). App Previews: empty.
- Plan from `ASO_PLAN.md`: 1 swipe mid-drag, 2 Albums, 3 Review, 4 Done, 5 Paywall (labelled Pro). The Quick clean-up shot waits until that feature is verified.
- **Status:** `media/screenshots/` has current Albums, Swipe, Select grid and Settings in both looks. **Missing or outdated:** Review (only an older iOS-prompt shot), Done (celebration), Paywall (needs an Xcode run with the StoreKit config so the price loads), Welcome (predates this build). The `app-store-screenshots/` folder is an untracked generator and is not committed. Use only simulator shots with clean content; the simulator library holds earlier app screenshots, so swipe shots may show a nested app screen. Capture on a clean library. Also confirm Apple's sample photos may be used in marketing.

### Promotional Text (102/170)
```text
Swipe left to delete, right to keep. A calm, beautiful way to clear your camera roll. No subscription.
```

### Description (1,613/4,000)
```text
Lighter clears your camera roll the quick way: swipe left to delete, swipe right to keep.

ONE GESTURE
Pick an album and swipe through your photos one at a time. Left marks a photo for deletion, right keeps it. Prefer buttons? Delete, Undo and Keep are always on screen. Undo takes you back, as far as the first photo. You can also open a grid and select many photos at once.

CHECK BEFORE ANYTHING GOES
Nothing is deleted while you swipe. Review shows every photo you marked, and you can tap one to unmark it. Then iOS asks you once to confirm. Deleted photos stay in Recently Deleted for 30 days, so you can still change your mind.

SEE WHAT YOU CLEARED
When you finish, Lighter shows how much space you cleared and how many photos you reviewed, kept and deleted. Settings keeps a running total.

ALL YOUR ALBUMS
All Photos, Screenshots, Videos, Selfies, Favourites and your own albums, each with a cover and a count. Videos play with sound, and iCloud photos can be kept or deleted too.

CALM BY DESIGN
A quiet glass look in Light and Dark, with a serif wordmark and no alarms about your phone being full. Works with Dynamic Type, Reduce Motion and Reduce Transparency.

PRIVATE
Your photos never leave your iPhone. No account, no ads, no analytics, no tracking.

FREE, OR PAID ONCE
Swiping, keeping and reviewing are always unlimited. The free plan deletes up to 50 photos a day. Lighter Pro is a single one-time purchase that removes that daily limit. No subscription. Restore Purchases is in Settings.

Deleted photos stay in Recently Deleted for 30 days, so the space comes back when that album is emptied.
```

Claims checked against APP_PLAN: 50 deletions a day, Recently Deleted 30 days, select grid, albums list, privacy, no subscription, Restore in Settings. "Videos play with sound" and "iCloud photos can be kept or deleted" come from the plan's failure paths and Stage 8; video sound is still an open device check, so **remove that sentence if you do not test it first**.

### Keywords (97/100)
```text
camera,roll,gallery,album,screenshot,declutter,tidy,remove,space,organize,sort,video,clear,memory
```
No spaces after commas; no repeats of title or subtitle words; no competitor names; no "duplicate" until Duplicates is verified. **OWNER:** check popularity in Apple Search Ads and swap weak words.

### URLs, version, copyright
| Field | Answer |
|---|---|
| Support URL | `https://vericodestudio.com/products/lighter/support/` (all four live pages returned 200 on 24 Nov; re-check) |
| Marketing URL | `https://vericodestudio.com/products/lighter/` |
| Version | `1.0.0` |
| Copyright | `2026 VeriCode` — **OWNER:** must match your developer account name |
| Routing App Coverage, App Clip, iMessage, Game Center | Empty |

### Build
Build **1.0.0 (1)** was uploaded on 24 Nov ("Upload succeeded"). Processing is not confirmed: wait for it to finish in TestFlight, then pick it here. If you change any code, raise `CURRENT_PROJECT_VERSION` first; an uploaded build cannot be reused. Export compliance: answer "No" to non-exempt encryption if asked.

### App Review Information
| Field | Answer |
|---|---|
| Sign-in required | **Untick** |
| Name, phone (with country code) | **OWNER** |
| Email | `support@vericodestudio.com` |
| Attachment | Empty |

Notes:
```text
No account or sign-in. Lighter has no server: it makes no network calls, and photos never leave the iPhone. The review device needs some photos in its library.

How to test: allow photo access. On Albums, open any album. Swipe left to mark a photo for deletion, swipe right to keep; Delete, Undo and Keep buttons do the same. Open Review to see marked photos, tap one to unmark, then tap Delete. iOS shows its own confirmation; photos go to Recently Deleted.

Free plan: up to 50 deletions a day. Mark more than 50 photos and tap Delete in Review to see the Lighter Pro paywall ("Unlock Pro" or "Delete N now"). Lighter Pro is a one-time non-consumable purchase (com.vericodestudio.lighter.pro). Restore Purchases is in Settings, opened with the gear button on Albums.

Quick clean-up on Albums (Duplicates, Pages & Things, From WhatsApp) scans on the device with Apple Vision. It never deletes anything automatically.

No ads, analytics, tracking, subscriptions or push notifications.
```

### Version release
**Manually release this version.**

## 6. Before you press Add for Review
- Wait for build processing; install the TestFlight build on a real iPhone.
- Device checks still open (RELEASE_CHECKLIST): confirmed delete and Done screen on a real library, sandbox purchase and Restore, video sound, VoiceOver, AX5, iPhone SE, new paywall, clean-up accuracy.
- Create the IAP, sign the Paid Apps agreement, tax and banking, declare EU trader status.
- Capture the missing screenshots (Review, Done, Paywall with real price).
- Deploy the updated legal pages and confirm they match `legal/`.
- Set the App Store link in the app (Rate row stays hidden until it exists) only if you want it in 1.0; that needs a new build.
- Confirm the font licence is enough (D-27), the 13+ audience and a quick trademark search for "Lighter" in class 9.
