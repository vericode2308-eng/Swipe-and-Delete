# Lighter — Build Plan

Scope: `APP_PLAN.md`. Look: `DESIGN_BRIEF.md`.

## 1. Setup
- Native SwiftUI, **iOS 18+** (D-20), Swift 6 strict concurrency, portrait only.
- **XcodeGen:** `project.yml` is the source of truth. `*.xcodeproj` is
  git-ignored; run `xcodegen generate` after a checkout or a `project.yml`
  change. `DEVELOPMENT_TEAM` lives in `project.yml` (owner to supply).
- Bundle ID `com.vericodestudio.lighter` (confirmed, D-17; registered on the
  first device build); tests `.tests`; Pro product ID `com.vericodestudio.lighter.pro`
  (non-consumable). Home-screen name: "Lighter".
- `Info.plist`: `NSPhotoLibraryUsageDescription`,
  `ITSAppUsesNonExemptEncryption = NO`, portrait only, `UIRequiresFullScreen`
  removed. Privacy manifest (`PrivacyInfo.xcprivacy`) declaring the
  UserDefaults API reason and no tracking. Placeholder icon from day one.
- No third-party packages. Bundled font: Cormorant Garamond (SIL OFL).
- `.gitignore`: build output, `*.xcodeproj`, `DerivedData`, generated media,
  `*.xcconfig` except `.example` templates, `.DS_Store`.

## 2. Architecture

```
App target ──▶ SwipeFeatures (screens) ──▶ SwipeUI (design system)
                      │                           
                      └──────────────▶ SwipeCore (pure logic, host tests)
                                            ▲
                         PhotoKit / StoreKit adapters live in the app target
                         behind SwipeCore protocols
```

```
App/
  LighterApp.swift               // @main; builds live services, injects AppModel
  PhotoKitLibrary.swift          // the ONLY code that deletes
  PhotoKitImageLoader.swift      // PHCachingImageManager, prefetch next 3
  StoreKitPurchases.swift        // StoreKit 2: product, purchase, restore, entitlements
  VisionPhotoAnalyzer.swift      // Vision: faces/people, quality (isUtility, score),
                                 // feature print, 64-bit image hash, from thumbnails
  Resources/ (Assets, fonts, PrivacyInfo.xcprivacy, Products.storekit)
Packages/
  SwipeCore/                     // no SwiftUI, no PhotoKit, no StoreKit
    Models.swift                 // Album, Asset, Decision, DeleteResult
    PhotoLibrary.swift           // protocol
    Purchases.swift              // protocol
    SwipeSession.swift           // keep / delete / undo / unmark
    DeletionAllowance.swift      // 50 a day, local-midnight reset, injected clock
    AccessPolicy.swift           // free vs pro: how many can be deleted now
    ReviewPromptPolicy.swift     // when to ask for a rating
    PhotoAnalyzer.swift          // protocol: analyse(asset) -> PhotoTraits
    CleanupIndex.swift           // pure rules: duplicate sets, Pages & Things
    CleanupScanner.swift         // walks the library, resumes, pauses, caches
    Formatting.swift             // bytes → "1.2 GB", "room for about N photos"
    Fakes/ FakePhotoLibrary.swift, FakePurchases.swift
    Tests/
  SwipeUI/                       // Theme (light/dark), Glass, Backdrop, AppCanvas,
                                 // PillButton, GlassChip, GlassDock, CelebrationRing
  SwipeFeatures/                 // WelcomeView, AlbumsView, SwipeView, PhotoCard,
                                 // ReviewView, PaywallSheet, DoneView, AboutSheet,
                                 // AppModel (@Observable navigation + auth state)
```

### Key types
```swift
public protocol PhotoLibrary: Sendable {
    func authorize() async -> AuthStatus              // .full, .limited, .denied
    func albums() async -> [Album]
    func assets(in album: Album) async -> [Asset]     // oldest → newest
    func byteSize(of ids: [String]) async -> Int64    // Done screen
    func delete(_ ids: [String]) async throws         // one performChanges
    func whatsAppAlbum() async -> Album?              // user album titled "WhatsApp"
}

public struct PhotoTraits: Codable, Sendable {        // one per analysed photo
    public let id: String, modified: Date, created: Date
    public let hasPeople: Bool                        // face or human body found
    public let isUtility: Bool                        // Vision quality check
    public let qualityScore: Float                    // -1 … 1
    public let imageHash: UInt64                      // exact / near-exact copies
    public let featurePrint: Data                     // near-identical shots
    public let visionRevision: Int                    // re-analyse if it changes
}

public struct CleanupIndex {                          // pure, host-tested
    public func duplicateSets(_ t: [PhotoTraits]) -> [[String]]
    public func pagesAndThings(_ t: [PhotoTraits]) -> [String]
}

public protocol Purchases: Sendable {
    func product() async throws -> ProProduct         // display price from StoreKit
    func purchase() async -> PurchaseOutcome          // .success, .cancelled, .pending, .failed
    func restore() async throws
    func isPro() async -> Bool                        // Transaction.currentEntitlements
}

@Observable @MainActor public final class SwipeSession {
    public let album: Album
    public let assets: [Asset]
    public private(set) var index = 0
    public private(set) var marked: [String] = []     // ordered, unique
    private var history: [Decision] = []
    public func keep(); public func delete(); public func undo()
    public func unmark(_ id: String)
    public var isFinished: Bool { index >= assets.count }
}

public struct DeletionAllowance {                     // persisted in UserDefaults
    public static let dailyFree = 50
    public func remaining(now: Date) -> Int
    public mutating func record(_ count: Int, now: Date)  // only after iOS confirms
}

public struct AccessPolicy {
    public let isPro: Bool
    public let allowance: DeletionAllowance
    public func deletable(marked: Int, now: Date) -> Int  // Pro → marked
    public func needsPaywall(marked: Int, now: Date) -> Bool
}
```

### Rules
- `SwipeSession` is created fresh every time an album opens and is never
  saved (D-02). The only stored data: the daily deletion count + its date,
  and the review-prompt counters (UserDefaults keys
  `allowance.date`, `allowance.count`, `review.*`; never rename without a
  migration).
- Pro status comes only from StoreKit entitlements, through one
  `AccessPolicy`. No scattered `if isPro` checks. A DEBUG launch argument
  `-debug.pro YES` exists only in Debug builds and a real purchase clears it.
- Before deleting: re-fetch the ids, drop missing ones, apply
  `AccessPolicy.deletable`, then one `performChanges`. Record the count only
  in the success branch.
- Freed size: sum `PHAssetResource.assetResources(for:)` `fileSize` values
  (KVC, undocumented; a missing value counts as 0 and the UI says "about").
  Computed on Review in the background.
- `ImageLoader`: screen-sized, `.opportunistic`, network allowed, prefetch
  next 3, stop caching passed ones, ignore late images for a different id.
- Observe `PHPhotoLibraryChangeObserver`; skip assets that vanish.
- Carousel: `ZStack` of prev / current / next `PhotoCard`, `DragGesture`
  offset + rotation, `.spring(response: 0.3, dampingFraction: 0.8)`, change
  `index` after the fly-off. Reduce Motion → cross-fade.
- Celebration: `keyframeAnimator` for the ring trim and check pop,
  `.contentTransition(.numericText(value:))` for the count-up, one `Canvas`
  in `TimelineView(.animation)` for the sparkles, attached to the whole
  screen. `.sensoryFeedback(.success, trigger:)`.
- **Clean-up scan** (D-18 to D-21): `CleanupScanner` runs at `.utility`
  priority while the app is open, newest photos first, from local 300 px
  thumbnails (`isNetworkAccessAllowed = false`; no local thumbnail → skip).
  Per photo: `DetectFaceRectanglesRequest` + `DetectHumanRectanglesRequest`,
  `CalculateImageAestheticsScoresRequest` (iOS 18; device only, not the
  simulator), `GenerateImageFeaturePrintRequest`, and a 64-bit difference
  hash. Pauses on Low Power Mode or thermal state `.serious`.
- **Cache:** `PhotoTraits` stored in Application Support (`cleanup-v1.bin`),
  keyed by `localIdentifier` + modification date + Vision revision; entries
  for deleted photos are dropped on the next scan. Holds no swipe progress
  (D-02). A corrupt or unreadable file is deleted and the scan starts again.
- **Duplicates:** (a) same image hash (Hamming distance ≤ 2) anywhere in the
  library; (b) feature-print distance below a threshold for photos taken
  within 60 s of each other. Start at 0.35 and tune on the owner's library
  (one public report: 0.2 missed duplicates, 0.5 grouped unrelated scenes).
  Sets ordered newest first; within a set, oldest first.
- **Pages & Things:** photo (not video, not screenshot), `hasPeople == false`
  and (`isUtility` or `qualityScore < −0.3`, tuned on device).
- **From WhatsApp:** fetch the user album whose title is exactly "WhatsApp";
  no scan needed.
- Review prompt (`ReviewPromptPolicy`): after a successful delete on the
  third completed album on at least the second distinct day, shown after the
  user taps Back to Albums. Never after an error, a purchase or on first run.
  At most once per 120 days.

## 3. Stages

| # | Stage | Done when |
|---|---|---|
| 1 | `project.yml`, packages, Theme light/dark, Glass, fonts, placeholder icon | App launches to an empty Welcome in both looks; `swift test` runs |
| 2 | `SwipeCore`: SwipeSession, DeletionAllowance, AccessPolicy, Formatting, ReviewPromptPolicy + tests | All core tests pass on the host |
| 3 | Welcome + permission (full / limited / denied) | All three states on a device |
| 4 | Albums with PhotoKit + About sheet (no purchases yet) | Counts match the Photos app |
| 5 | Swipe carousel, dock, drag, haptics, ImageLoader | Smooth on a 1,000+ item album on device |
| 6 | Review + delete + Done celebration | Prompt; cancel stays; freed size plausible vs Settings › Storage |
| 6b | Quick clean-up: scanner, cache, Duplicates, Pages & Things, From WhatsApp rows | Real library on device: sets look right, few false matches; scan of 5,000 photos finishes with the app open; killing the app mid-scan resumes |
| 7 | StoreKit 2 Pro, paywall, Restore, daily limit | Purchase / cancel / restore / pending with `Products.storekit` from Xcode, then sandbox |
| 8 | Video / Live Photo playback, zoom | Plays; audio stops on swipe |
| 9 | Accessibility + Dynamic Type AX5 + Reduce Motion / Transparency + iPhone SE pass | VoiceOver finishes a full album |
| 10 | Security audit, release checklist, TestFlight | A tester installs the processed build |

## 4. Tests
Host tests (`swift test` in `SwipeCore`):
- Undo after a delete-swipe removes it from marks; undo at index 0 does nothing.
- A new session for the same album starts at 0 with no marks.
- `unmark` removes only that id and keeps order.
- Allowance: 50 on a new day; recording 30 leaves 20; resets after local
  midnight; time-zone change does not give negative values.
- AccessPolicy: free with 72 marked and 50 left → deletable 50, paywall
  true; Pro → 72, paywall false.
- Count is not recorded when delete throws (fake library).
- Formatting: 0, 999 MB, 1.2 GB, "room for about N photos" rounding.
- CleanupIndex: identical hashes in different years form one set; two
  similar prints 30 s apart form a set, 2 minutes apart do not; a photo with
  people is never in Pages & Things; videos and screenshots are excluded.
- Scanner cache: changed modification date or Vision revision → re-analyse;
  corrupt file → deleted, scan restarts; deleted photo → entry dropped.
- ReviewPromptPolicy: thresholds and the "never after purchase/error" cases.

App-level checks (device, listed as Not verified until done):
- Cancelling the iOS prompt deletes nothing and keeps marks and count.
- A photo deleted in Photos mid-swipe is skipped without a crash.
- Limited access shows only the selected photos.
- iCloud-only photo offline shows "Not downloaded" and still allows Keep.

## 5. Risks
- `fileSize` KVC could change in a future iOS → fall back to "about" or hide
  the size; the celebration still works with counts.
- Guideline 4.3 (crowded "photo cleaner" category): the difference is the
  calm, glass, one-gesture experience and no subscription. Duplicate filters
  are common in this category, so the swipe flow must stay the centre.
- Guideline 3.1.1: the free plan stays genuinely useful (unlimited swiping,
  50 deletions a day).
- **Clean-up accuracy** can only be judged on a real library on a real
  iPhone (the quality check does not run in the simulator). Thresholds are
  starting points; tune them before release and record the values.
- Clean-up scan time and battery on 50k libraries: newest first, resumable,
  paused on Low Power Mode / heat; measure on device.
- The "WhatsApp" album title is set by WhatsApp; if it changes the row just
  hides.
- Large libraries (50k+): fetch with `PHFetchResult` lazily; never map the
  whole album into memory for "All Photos".
- **Environment:** this cloud container has no Xcode. Builds, simulator and
  device runs must happen on the owner's Mac (or with the Mac attached to the
  session). Anything not run there stays in "Not verified".
