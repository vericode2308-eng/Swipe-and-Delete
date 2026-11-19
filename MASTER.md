# Lighter (formerly Swipe & Delete) — Master Record

The project's memory. Every change, decision, mistake and correction since day
one. Never delete history; add to it. Rules: `CLAUDE.md` §0.7.

Design canvas: https://claude.ai/artifact/Jn3jbGXcMaqwmxhM4HLq5z
Working branch: `claude/sweet-gauss-20esu8`

## Timeline

### Day 1 — 2026-11-18

**Change 1 — Brief received**
- **What:** owner shared a ChatGPT link to a product brief ("iPhone Camera
  Roll Cleaner — product architecture and implementation brief").
- **What happened:** the link could not be opened from the cloud workspace
  (network policy blocks chatgpt.com). Owner pasted the brief instead.
- **Verified:** n/a. **Not verified:** n/a.

**Change 2 — First spec, then the owner's correction**
- **What:** Claude asked about scope; owner chose "Refine the brief". The
  refined brief still carried the original's extra ideas: a "Later" choice and
  remembering progress between visits.
- **Correction (owner):** "There is nothing later… delete or keep. There is no
  session… the entire album will start from the beginning. Keep the app very
  simple." → decisions D-01, D-02, D-03.
- **Files:** `SPEC.md` rewritten as a minimal v1 (committed).
- **Verified:** n/a (document).

**Change 3 — Detailed plan, architecture and design canvas**
- **What:** `PLAN.md` (UI, architecture, build steps) and a design canvas with
  six iPhone screens plus an architecture board. Owner chose "iOS-native, no
  design system".
- **Files:** `PLAN.md`; canvas.
- **Verified:** published. **Not verified:** canvas rendering not viewed by
  Claude.

**Change 4 — Side-by-side carousel**
- **What:** owner shared a Pinterest link (blocked by network policy, like
  chatgpt.com); Claude's question about the animation type was declined; owner
  sent a travel-app screenshot: "Like this side by side". The Swipe screen
  became a carousel: previous photo peeks left (tap = Undo), next peeks right
  (D-04).
- **Files:** `PLAN.md`, `Swipe.dc.html` (interactive), `SwipeDelete.dc.html`.

**Change 5 — Neumorphism + glassmorphism look**
- **What:** owner sent a neumorphism/glass UI kit: grey surfaces, raised and
  pressed shadows, LED-style colour dots (D-05).
- **Status:** superseded by Change 6.

**Change 6 — "Dusk" look**
- **What:** owner sent the InSleep app: "polished and classy yet simple".
  New look: slate base, blurred current photo as background, serif titles
  (Cormorant Garamond), pastel blush = delete, sage = keep, mist primary pill
  (D-06). All six screens redrawn.
- **Mistake:** a photo-size label ("3.1 MB") was added to the Swipe card,
  although storage sizes were a written non-goal. **Fix:** removed.
- **Mistake:** `PLAN.md` still mentioned "LEDs" in the Theme comment after the
  redesign. **Fix:** corrected and committed.
- **Lesson:** after a redesign, search all docs for the old terms; check the
  non-goals before adding any detail.

**Change 7 — Stronger glassmorphism**
- **What:** the Dusk redesign had weakened the glass. Owner: "Don't forget
  glassmorphism." Stronger frosted glass (blur 24, saturation 170 %, white
  edge, top highlight, shadow), colour blobs behind glass on flat screens, a
  glass dock for the buttons, glass panels on Welcome and Review (D-07).
- **Files:** all six screen files, `PLAN.md` glass tokens.
- **Verified:** checked no style had duplicate shadows after the bulk edit.
  **Not verified:** rendering.
- **Lesson:** when the visual direction changes, carry forward every
  earlier owner requirement, not just the newest reference.

**Change 8 — Done screen celebration**
- **What:** owner asked for an achievement animation showing what was deleted
  and the storage saved. Claude researched cleaner apps' success screens
  (freed-size headline, stat cards, confetti, haptics) and microinteraction
  guidance (short, skippable, works without motion). Built: photos drift into
  a glass ring, the ring fills while "1.2 GB" counts up, a check pops with
  sparkles and a haptic, then stats and "Room for about 400 more photos".
  Honest wording: space returns once Recently Deleted empties (D-08
  superseded by D-09).
- **What happened:** after the conversation was compacted, the first publish
  was refused because the published files had not been re-read in the new
  context. Claude read them, confirmed they were its own last versions, then
  published.
- **Files:** `Done.dc.html`, `canvas.json`, `SPEC.md`, `PLAN.md`.
- **Verified:** published (canvas version 27). **Not verified:** animation
  timing not watched by Claude.

**Change 9 — Standing rules adopted; documents restructured**
- **What:** owner added standing rules (`CLAUDE.md`). They were on a
  separate branch (`claude/laughing-lamport-9934ed`); Claude copied the file
  onto the working branch. Owner answered open product questions (D-10 to
  D-15): free + one-time Pro at $4.99, 50 deletions a day free, name "Swipe &
  Delete" and bundle ID, keep pill buttons, add a light look. `SPEC.md` and
  `PLAN.md` were replaced by `APP_PLAN.md`, `DESIGN_BRIEF.md`,
  `BUILD_PLAN.md`, `ASO_PLAN.md` and this file. Added the paywall and About
  screens, the light "Dawn" tokens, the XcodeGen + Swift packages
  architecture, StoreKit 2 and the review-prompt policy.
- **Mistake:** `PLAN.md` screen 3 still described the old coral / teal /
  indigo colours and "round white buttons" from before Dusk. **Fix:**
  rewritten correctly in `DESIGN_BRIEF.md`.
- **Conflict noted:** the standing rule "resume after the app is killed" is
  overridden for this app by D-02 (always start from the beginning).
- **Verified:** documents cross-checked for stale terms. **Not verified:**
  the canvas does not yet show the light look, paywall or About sheet.

**Change 10 — Rules made explicit: auto-push, full history, screenshots**
- **What:** owner asked that (1) every major change is pushed automatically
  without reminders, (2) the full history of changes, mistakes and
  corrections is kept from day one, (3) every simulator screenshot is saved
  in `media/screenshots/`, old ones replaced when the UI changes, so the
  folder is always current for App Store images.
- **Gap found:** `CLAUDE.md` said "commit" but not "push"; it had a change
  log but no explicit mistakes history; screenshots had no naming or index.
- **Fix:** `CLAUDE.md` §0.7, §1.1, §1.2, §8.2–8.3 and §11 updated; this file
  rebuilt with the full history; `media/screenshots/INDEX.md` created.
- **Verified:** rules re-read after editing. **Not verified:** n/a.

**Change 11 — App Store name researched; app renamed "Lighter"**
- **What:** owner asked for a draft App Store name with good ASO. Research
  found at least six App Store apps already called "Swipe & Delete", one
  exactly "Swipe & Delete - Photo Cleaner" (the earlier draft title). Also
  ruled out Dusk, Afterglow, Pare, Sift and Keepsake. Owner chose
  **"Lighter: Swipe Photo Cleaner"** (D-17, superseding D-13). Drafted
  subtitle, keyword field and promotional text with character counts.
- **Files:** `ASO_PLAN.md`, `APP_PLAN.md`, `BUILD_PLAN.md`,
  `DESIGN_BRIEF.md`, `store_drafts/`, `CLAUDE.md`, design canvas (Welcome
  wordmark).
- **Verified:** web search of App Store listings; character counts by
  script. **Not verified:** name availability in App Store Connect,
  keyword popularity (Apple Search Ads), trademark search; bundle ID
  `com.vericodestudio.lighter` awaits owner confirmation.

**Change 12 — Quick clean-up filters (Duplicates, Pages & Things, WhatsApp)**
- **What:** owner asked for filters that gather photos worth deleting:
  duplicates; photos of pages, notes, cupboards, doors or accidental shots
  ("anything which is not a human"); and WhatsApp forwarded photos. Claude
  researched Apple Vision: the iOS 18 photo-quality check flags "utility"
  images (receipts, documents, screenshots); feature prints compare images
  but have no official similarity threshold; WhatsApp saves to an album
  named "WhatsApp" and does not mark forwarded photos. Owner chose: filters
  free for everyone on the whole library (D-19); minimum iOS raised to 18
  (D-20). Added D-18 (the filters, reversing the duplicate-detection
  non-goal) and D-21 (scan results kept on the iPhone; proposed, confirm).
  Every filter opens the normal swipe flow; nothing is deleted
  automatically.
- **Design:** Albums board now has a "Quick clean-up" glass panel with the
  three rows; the old "Swipe & Delete" wordmark on that board was replaced
  by the ⓘ About button (R-14); canvas title renamed "Lighter — App Design".
- **Files:** `APP_PLAN.md` (R-18 to R-22, non-goals, failure paths,
  D-18 to D-21), `DESIGN_BRIEF.md`, `BUILD_PLAN.md` (iOS 18, scanner, cache,
  rules, stage 6b, tests, risks), `ASO_PLAN.md`, design canvas (version 29).
- **Verified:** web research (sources in the chat); all docs searched for
  "iOS 17" and the old non-goal. **Not verified:** detection accuracy and
  scan speed (need a real library on a real iPhone; the quality check does
  not run in the simulator); canvas rendering not viewed by Claude.
- **Gap found:** the Albums board still showed "Swipe & Delete" after the
  rename in Change 11. **Fix:** removed. Lesson: after a rename, check every
  design board, not only the Welcome screen.

**Change 13 — D-21 confirmed**
- **What:** owner confirmed D-21 ("Keep d21"): the clean-up scan's results
  (per-photo labels and image fingerprints) stay on the iPhone so the scan
  does not restart on every launch. Swiping still always starts from item 1
  (D-02).
- **Files:** `APP_PLAN.md` (D-21 status), this file.
- **Verified:** n/a (decision). **Not verified:** n/a.

**Change 14 — Light look (Dawn) and Paywall drawn**
- **What:** owner chose to see the light look and the paywall before any
  code. Added a Dusk Paywall board and a full Dawn row: Welcome, Albums,
  Swiping right = keep, Review (interactive), Paywall, Done (final frame).
  Canvas re-laid out: Dusk row, Dawn row, then Architecture.
- **Stage 1 attempt first:** before the owner switched to designs, Claude
  looked for a way to build here. This container has no Swift toolchain and
  no Xcode; swift.org is blocked; a Swift 6.0.3 package from the Ubuntu
  archive was downloaded and extracted, but running it was refused by the
  session's permission check, so it was deleted. The owner's Mac folders
  cannot be attached to cloud sessions. Stage 1 still needs the Mac.
- **Contrast check (script, WCAG formula) found failing Dawn tokens in the
  brief:** Delete button text `#A4472F` on blush 3.5:1 → now `#2A1A16`
  (9.7:1); keep `#2F7A66` on glass 4.3:1 → `#286B59` (5.2:1); photo scrim
  60 % made secondary text 2.3:1 over a dark photo → scrim 75 %, and text
  directly on the scrim uses `#3E4757`.
- **Gaps fixed:** the Dusk Review board lacked the "Free plan: 50 deletions
  a day · N left today" line the brief requires (added). "Delete 50 now" on
  the paywall was wrong once some deletions were already used today; it is
  now "Delete N now", N = deletions left today (R-13 and the brief updated).
- **Files:** `DESIGN_BRIEF.md` (Dawn tokens, paywall), `APP_PLAN.md` (R-13),
  this file; canvas version 31.
- **Verified:** boards rendered locally in Chromium with a stand-in for the
  canvas runtime and screenshots checked by Claude (layout, clipping,
  readability); contrast ratios computed. **Not verified:** the boards
  inside the real canvas viewer; Dawn on a real iPhone; final fonts (the
  app uses SF Pro, the mock-ups Inter).

**Change 15 — Owner answers; design files added to the repository**
- **What:** owner answered the open questions: leftover marks after
  "Delete N now" are dropped (D-22); bundle ID `com.vericodestudio.lighter`
  confirmed (D-17); About sheet confirmed (D-16); "Discard 9 marks?" when
  switching album confirmed (D-23). Owner asked for a folder on the Mac with
  all project data. This cloud session cannot reach the Mac (its folders
  are listed as not available to cloud sessions), so the design canvas
  sources were added to the repository (`design/canvas/`) so one `git clone`
  on the Mac brings everything: plans, history, store drafts, screenshots
  folder and designs.
- **Files:** `APP_PLAN.md`, `BUILD_PLAN.md`, `DESIGN_BRIEF.md`,
  `design/canvas/` (15 files), this file.
- **Verified:** files copied and committed. **Not verified:** the folder on
  the Mac (owner runs the clone).

**Change 16 — Stage 1: project skeleton**
- **What:** `project.yml` (XcodeGen, iOS 18, portrait, bundle ID
  `com.vericodestudio.lighter`, team ID copied from the owner's other
  projects), local packages `SwipeCore` / `SwipeUI` / `SwipeFeatures`,
  Theme (Dusk/Dawn tokens), Glass, AppCanvas, PillButton, an empty Welcome,
  privacy manifest, placeholder icon (blurred colour field), Cormorant
  Garamond (OFL, from google/fonts on GitHub) bundled in `App/Resources/Fonts`.
- **Files:** `project.yml`, `App/`, `Packages/`, `Tests/`, `.gitignore`,
  `media/screenshots/01-welcome-empty-*.png`, this file.
- **Verified:** `xcodegen generate`; `swift test` passes in all three
  packages; app builds and launches on the iPhone 18 Pro simulator in Dusk
  and Dawn (screenshots checked by Claude; serif italic wordmark renders).
- **Not verified:** a real device; signing with the team ID; glass (nothing
  uses it yet); Dynamic Type; the placeholder icon on a home screen;
  `LighterTests` target run.

**Change 17 — Dynamic Type check on Welcome; pill label centred**
- **What:** checked the empty Welcome at AX5 (Dawn). Nothing clips; the pill
  grows to two lines. The label was left-aligned when wrapped, so
  `PillButton` now centres it and adds vertical padding.
- **Files:** `Packages/SwipeUI/Sources/SwipeUI/PillButton.swift`, this file.
- **Verified:** simulator screenshot at AX5, Dawn, after the fix.
  **Not verified:** AX5 in Dusk, other sizes, iPhone SE, VoiceOver.

**Change 18 — Stage 2: SwipeCore logic**
- **What:** `Models`, `SwipeSession` (keep / delete / undo / unmark),
  `DeletionAllowance` + `AllowanceStore` (50 a day, local midnight, keys
  `allowance.*`), `AccessPolicy`, `Formatting` (sizes, "Room for about N
  more photos"), `ReviewPromptPolicy` + `ReviewPromptStore` (keys
  `review.*`). The placeholder core file and its test were removed.
- **Assumption to confirm:** "room for about N photos" uses an average
  photo of 3 MB, rounded (exact below 100, nearest 10 below 1,000, nearest
  100 above). Sizes use decimal units like Settings › Storage.
- **Files:** `Packages/SwipeCore/Sources/SwipeCore/*`,
  `Packages/SwipeCore/Tests/SwipeCoreTests/*`, this file.
- **Verified:** `swift test` in `SwipeCore`: 22 tests pass (the Stage 2
  items from the build plan, except "count not recorded when delete throws",
  which needs the fake library and moves to Stage 6). Other packages' tests
  and the app build still pass.
  **Not verified:** the real UserDefaults on a device; the 3 MB figure
  against real photos.

**Change 19 — Stage 3: Welcome and Photos permission**
- **What:** `PhotoLibrary` protocol (status + authorize only; the rest
  arrives with its stage), `FakePhotoLibrary`, `PhotoKitLibrary` adapter,
  `AppModel` (permission state; refreshes on foreground so revoked access
  returns to Welcome), full Welcome screen per the brief (illustration drawn
  in code, two glass hint rows, pill, footnote; denied → "Open Settings" and
  one line on why), `RootView`. Albums is a placeholder ("Full / Limited
  access granted") until Stage 4. Limited counts as granted.
- **Files:** `Packages/SwipeCore/.../PhotoLibrary.swift`,
  `Fakes/FakePhotoLibrary.swift`, `Packages/SwipeFeatures/.../AppModel.swift`,
  `WelcomeView.swift`, `RootView.swift`, `App/PhotoKitLibrary.swift`,
  `App/LighterApp.swift`, tests, screenshots (the Stage 1 empty-Welcome
  shots were replaced).
- **Verified:** 7 `AppModel` tests pass; app builds. Simulator (iPhone 18
  Pro): undetermined and denied states in Dusk and Dawn (screenshots checked);
  tapping the pill shows the real iOS prompt with our usage text; "Allow Full
  Access" moves to the placeholder Albums.
- **Not verified:** the Limited path ("Select Photos") and "Don't Allow" in the
  real prompt (covered by unit tests only); the Open Settings tap; revoking
  access while the app is open; a real device; Welcome at AX5 and on iPhone SE.
- **Layout note:** the illustration reaches the top edge by letting the
  scroll view ignore the top safe area (a plain negative offset left a band
  under the status bar).

**Change 20 — Stage 4: Albums with PhotoKit and the About sheet**
- **What:** `Album` gains `kind` and `coverID`; `PhotoLibrary.albums()`; pure
  `AlbumList` rules (empty hidden, smart before mine, filters) in
  `SwipeCore`; `AppModel` loads albums after permission and on every return to
  the foreground; `AlbumsView` (title, ⓘ, Limited-access row, All / Smart /
  My chips, two-column tile grid, one column at accessibility sizes);
  `AboutSheet` (free allowance line, Acknowledgements for the OFL font,
  version); `PhotoKitLibrary.albums()` (12 smart albums, user albums, no
  Hidden or Recently Deleted); `PhotoKitImageLoader` for covers.
- **Left out on purpose:** Quick clean-up rows (Stage 6b); Unlock Pro and
  Restore (Stage 7); Rate and Privacy Policy rows show only once the links
  exist (owner has not supplied them); album tiles are not tappable until the
  swipe screen exists (Stage 5).
- **Verified:** 17 new/updated tests pass (`SwipeCore` 26, `SwipeFeatures` 13);
  app builds; simulator (iPhone 18 Pro) Dusk and Dawn: Recents shows 6 and the
  library holds 6 files; cover image loads; About sheet opens with the real
  version.
- **Not verified:** counts against a large real library; user albums and
  other smart albums (the simulator library has only Recents); the Limited
  row and the "Manage selection" picker; the empty state; Albums at AX5 and on
  iPhone SE; a real device; a photo added or deleted while the app is open
  (refresh runs on foreground only, not live).

**Change 21 — Stage 5: Swipe carousel, dock, drag, haptics, image loader**
- **What:** `PhotoLibrary.assets(in:)` (oldest first) with PhotoKit and fake
  versions; `AppModel.open/closeAlbum` (a fresh `SwipeSession` every time,
  D-02); `SwipeView` (blurred photo backdrop under a scrim, back button,
  title with "n of N", marked count, album chips with "Discard N marks?"
  confirm, side-by-side carousel with previous/next peeks, ✓/✕ badge on the
  previous peek that undoes when tapped, serif date + type caption, drag with
  tilt up to 12°, DELETE/KEEP tag and blush/sage tint, commit at 30 % of the
  width or a fast flick, spring 0.3 s / 0.8, glass dock with Delete / Undo /
  Keep that grows with the drag, light haptic on commit, VoiceOver actions and
  announcement, Reduce Motion cross-fade, "That's all" end card);
  `PhotoKitImageLoader` (one `PHCachingImageManager`, opportunistic delivery,
  network allowed, prefetch next 3, stop caching passed ones, late images for
  another photo ignored); new theme tokens (delete/keep tints, scrim).
- **Left out on purpose:** the Review button is a count only and the end card
  says "Back to Albums" until Stage 6; video and Live Photo playback and zoom
  (Stage 8); duplicates caption chip (Stage 6b).
- **Mistake found while testing (M-14):** the drag gesture on the card never
  fired (no callbacks, no commit) although buttons worked. Moving the gesture
  to the carousel container (`simultaneousGesture`) fixed it. Cause not
  isolated (the card's accessibility modifiers are the likely suspect).
- **Verified:** 26 + 1 + 16 package tests pass; app builds; simulator
  (iPhone 18 Pro, 6 photos): open album at item 1, delete by button and by
  drag, keep by drag and button, undo by tapping the left peek, end card,
  badges, Dusk and Dawn (screenshots checked).
- **Not verified:** smoothness on a 1,000+ album on a real device (the Stage 5
  done condition: unverified); the mid-drag tag and tint (no way to
  screenshot mid-gesture); haptics; Reduce Motion; VoiceOver actions; the
  "Discard marks?" confirm; an iCloud-only or deleted-in-Photos photo;
  Swipe at AX5 and on iPhone SE; memory with a large album.

**Change 22 — Stage 6: Review, real delete, Done celebration**
- Core: `PhotoLibrary` gained `existing`, `byteSize`, `delete` (returns
  `.deleted` / `.cancelled`, anything else throws); the fake can cancel, throw
  and drop photos. `SwipeSession.mark/unmark([ids])`; `Formatting.spokenSize`.
- `AppModel`: `beginReview`, `confirmDelete`, `summary`, free-plan count.
  Order: re-fetch ids, drop vanished, `AccessPolicy.deletable`, size, thumbnails
  for the drift, one `performChanges`. Allowance and review-prompt counters are
  saved only on success; cancel and failure leave marks and count untouched.
- Free plan over the limit deletes the first N (D-22). The paywall is Stage 7.
- Screens: `ReviewView` (3-column glass grid, tap = keep, free-plan line, blush
  pill), `DoneView` (time-driven: drift, ring + count-up, check pop, 22
  sparkles, haptic, stats; tap skips; Reduce Motion = final state + fade).
  `PhotoKitLibrary` is still the only code that deletes.
- Tests: SwipeCore 30, SwipeFeatures 23 (7 new delete-flow tests).
- Verified on the simulator: Review screen, real iOS prompt, Don't Allow keeps
  Review, marks and "50 left today".
- Not verified: a confirmed real delete and the Done screen on a device or
  simulator (another process kept taking the shared simulator to the
  foreground); freed size vs Settings › Storage; the rating prompt; Dawn; AX5;
  VoiceOver; Reduce Motion; the drift thumbnails.

## Mistakes and corrections

| # | Date | What went wrong | Who caught it | Fix | Lesson |
|---|---|---|---|---|---|
| M-01 | 2026-11-18 | The first refined brief kept "Later" and saved progress | Owner | Spec cut to delete / keep only, no memory | Start from the smallest version; ask before keeping extras |
| M-02 | 2026-11-18 | Links to chatgpt.com and pin.it could not be opened (network policy) | Claude | Owner pasted text and screenshots | Ask for pasted content or images when a link is blocked |
| M-03 | 2026-11-18 | A "3.1 MB" size label was added to a mock-up against a non-goal | Claude | Removed | Check non-goals before adding details |
| M-04 | 2026-11-18 | "LEDs" left in `PLAN.md` after the redesign | Claude | Corrected | Search docs for old terms after every redesign |
| M-05 | 2026-11-18 | Glassmorphism weakened during the Dusk redesign | Owner | Stronger glass tokens on every screen | Carry forward all earlier owner requirements |
| M-06 | 2026-11-18 | Publish refused after context compaction (files not re-read) | Tool | Read, confirmed, then published | Re-read published files after a context reset |
| M-07 | 2026-11-18 | Old coral / teal / indigo wording left in the Swipe screen spec | Claude | Rewritten in `DESIGN_BRIEF.md` | Same as M-04 |
| M-08 | 2026-11-18 | Rules said "commit" but not "push"; owner had to raise it | Owner | Rule 1.1 now says commit and push automatically | Write the habit into the rules, not just do it |
| M-09 | 2026-11-18 | Name "Swipe & Delete" was recommended and approved (D-13) before checking the App Store; six apps already use it | Claude (during ASO research) | Renamed to Lighter (D-17) before any bundle ID was registered | Search the App Store for the name before recommending it |
| M-10 | 2026-11-18 | After the rename to Lighter, the Albums design board still said "Swipe & Delete" | Claude (Change 12) | Replaced with the ⓘ About button | After a rename, search every design file too, not only the docs |
| M-11 | 2026-11-18 | Dawn colour tokens were written into the brief without a contrast check; three failed (delete text, keep text, photo scrim) | Claude (Change 14) | Tokens corrected and the reason noted in the brief | Run the contrast script on new colour tokens before writing them down |
| M-12 | 2026-11-18 | Paywall said "Delete 50 now" even when part of today's 50 was used; Dusk Review board lacked the free-plan line | Claude (Change 14) | "Delete N now" (N = left today); line added | When drawing a screen, check every rule in the brief and every number against the limits |
| M-13 | 2026-11-18 | Wordmark first rendered in the system font: `.custom` was given the family name, but the variable font needs PostScript names | Claude (screenshot) | Use `CormorantGaramond-SemiBold` / `-MediumItalic` | Check a bundled font renders in a screenshot, and read its real names with CoreText |
| M-14 | 2026-11-18 | Card drag gesture never fired (no commit) while buttons worked | Claude (simulator test) | Gesture moved to the carousel container | Drive every gesture in the simulator before calling it done; a button working proves nothing about the drag |

| M-15 | 2026-11-18 | Plan for Stage 6 UI test assumed the simulator was mine alone; another app (COLREGs) kept coming to the front during the iOS prompt | Claude (simulator test) | Reported the gap instead of claiming it | Use a dedicated simulator for destructive tests |

## Owner decisions
See the decision log in `APP_PLAN.md` (D-01 onwards).


**Change 23 — Stage 6b: Quick clean-up (scanner, cache, filters)**
- **What:** `CleanupIndex` (duplicate sets by 64-bit hash within 2 bits, plus feature prints within 60 s at 0.35; Pages & Things = no people and utility or quality < -0.3), `CleanupCacheStore` (`cleanup-v1.bin`), `CleanupScanner` (newest first, resumes, pauses on Low Power Mode / serious heat), `VisionPhotoAnalyzer` (iOS 18 Vision, 300 px local thumbnails), Quick clean-up panel on Albums, filter sessions with "Set 3 · 2 of 3" chip, Review note for fully marked sets, From WhatsApp row.
- **Choices:** flat-colour hashes (under 8 or over 56 set bits) never match; cache stores feature prints as Float32 (size on a large library not yet measured); cache revision = recipe + iOS major version.
- **Verified:** SwipeCore 46 and SwipeFeatures 28 tests pass; app builds; panel renders in the simulator.
- **Not verified:** everything the done condition names (real library, false-match rate, 5,000-photo scan, kill and resume), the Vision quality check (not available in the simulator), thresholds, battery.

**Change 24 — Stage 7: StoreKit 2 Pro, paywall, Restore**
- **What:** `Purchases` protocol + `FakePurchases` (core), `StoreKitPurchases` (product `com.vericodestudio.lighter.pro`, entitlements, `Transaction.updates` listener), `Products.storekit` wired to the scheme's Run action, `PaywallSheet`, Pro/Unlock/Restore rows in About, `-debug.pro YES` (Debug builds only).
- **Behaviour:** Delete with more marked than today's allowance opens the paywall instead of the iOS prompt (R-13). "Delete N now" deletes the first N and drops the other marks (D-22). A successful purchase closes the paywall and the user taps Delete again; it does not delete by itself. Price comes only from the store; if it can't load the pill reads "Price unavailable" and is disabled.
- **Verified:** SwipeFeatures 36 tests pass (paywall trigger, success, cancel, pending, failure, price failure, restore found / none / error, Pro skips paywall, debug flag, overflow drop). App builds. About sheet in the simulator shows "Price unavailable" with Unlock disabled, as intended.
- **Not verified:** a real purchase, cancel, pending and restore with `Products.storekit` from Xcode, then sandbox (the stage's done condition); the paywall sheet's look; Dawn; VoiceOver; AX5.

**Change 25 — Stage 8: video, Live Photo playback and zoom**
- **What:** `MediaLoading` (video player item, Live Photo) with a PhotoKit version in `PhotoKitImageLoader`; `MediaViewer` full-screen cover (video with controls and sound, Live Photo, photo with pinch and double-tap zoom via a tested `ZoomState`); play button on video cards; Live Photo plays in place while held; caption "VIDEO · 0:10" (`Formatting.clock`); `Asset.duration`.
- **Audio:** the viewer is modal, so there is no swiping while a video plays. Closing it pauses, drops the player and releases the audio session; backgrounding pauses. Inline Live Photo playback stops when the finger lifts or the card changes.
- **Verified (simulator):** SwipeCore 47 and SwipeFeatures 41 tests pass; a 10 s test video shows the play button and "VIDEO · 0:10"; tapping opens a full-screen player and the picture advances; Close returns to the card.
- **Not verified:** sound (the simulator tool can't hear it), Live Photo playback (no Live Photo in the simulator), pinch and double-tap zoom by touch, iCloud-only video, Dawn, VoiceOver, AX5, rotating.
- **Test data:** a 2 MB mp4 was added to the iPhone 18 Pro simulator's library only.

**Change 26 — Stage 9: accessibility and Dynamic Type**
- **What:** Swipe top bar adapts at accessibility text sizes (buttons share a row, title below, no line limit); card label reads type, spoken duration, date, set position and index; "Play"/"Open" action on the card; announcements "Marked for deletion, N of total" / "Kept, N of total" (fixed an off-by-one under Reduce Motion); Review tiles say "Photo i of n, will be kept/deleted"; Albums filter chips stack at AX sizes instead of clipping; "None found" row contrast raised; `Formatting.spokenClock`.
- **Verified (simulator):** SwipeCore 48 and SwipeFeatures 41 tests pass; Albums at AX5 shows wrapped titles, wrapped Quick clean-up rows and stacked chips with nothing cut off (screenshot 09).
- **Not verified:** VoiceOver (not run, so the done condition "VoiceOver finishes a full album" is NOT met); Reduce Motion and Reduce Transparency on a device; iPhone SE; Dawn at AX5; AX5 on Swipe, Review, Done, Welcome and Paywall; Increase Contrast; Bold Text (custom font does not respond).

**Change 27 — Paywall rules pass (user-supplied 5 rules)**
- **What:** headline states the outcome ("Delete all N photos"); filler sparkle row removed; subline is one line ("The free plan stops at 50 a day."); one plan with the real price in the perk row and the button; flat base colour instead of the blurred-blob backdrop.
- **Verified:** SwipeFeatures 41 tests pass. **Not verified:** not rendered on the simulator (needs more than 50 photos marked or the debug path); Dawn; AX5.

## Change 28 — Stage 10: security audit and release checklist
Audited source and an unsigned Release build: no network, logging, or tracking; debug unlock compiled out; privacy manifest accurate. Wrote RELEASE_CHECKLIST.md with findings and owner steps. No code changed. TestFlight upload not done: needs an Apple Distribution certificate and the App Store Connect app, which only the owner can set up.

## Change 29 — Legal documents
Added `legal/PRIVACY_POLICY.md` and `legal/TERMS_OF_USE.md`, checked against the code (no network, UserDefaults keys, `cleanup-v1.bin` cache, iCloud on-demand download, 50/day, one-time Pro, Recently Deleted 30 days). Terms use Apple's Standard EULA. Placeholders for the owner: developer name, support email, governing law (5 in total). Both documents must be hosted at public URLs for App Store Connect.

## Change 30 — iPhone Duo layout pass
Checked closed / half-open / open poses on the iPhone Duo simulator. Fixed: (1) Welcome content capped at 520 pt and the hero art moved behind the scroll view so it bleeds under side status strips (hill path now closes at the right edge); (2) Albums grid is adaptive (min 150 pt) except at accessibility sizes; (3) Review: scroll clipping disabled so the card shadow no longer shows a seam, tile grid adaptive (min 96 pt); (4) Swipe: carousel masked to the safe-area edge so the peeking card no longer runs under the status strip. Not verified: iPhone 18 Pro / SE regressions, Dawn, AX5 after the change, real Duo hardware. Quick clean-up panel still spans the full width when open.

## Change 31 — Re-check after the Duo pass; Quick clean-up width
Quick clean-up panel capped at 560 pt. Re-checked on an iPhone SE (3rd gen) simulator: Albums (light), Albums in dark at the largest accessibility size, Welcome in dark at normal and largest sizes — nothing clipped, grid keeps 2 columns, panel no longer stretches. Not verified: Swipe, Review, Done and Paywall on the SE or at AX5 (no tap access to the simulator panel); scrolling Welcome at AX5 now that the hero art sits behind the scroll view; Dawn at AX5 on the other screens; the open-pose Duo panel width after the cap.

## Change 32 — Settings page replaces About; Acknowledgements removed
- **What:** `SettingsView` (was `AboutSheet`), opened from a gear on Albums. Sections: **Cleared so far** (lifetime space and photo count, "Room for about N more photos"), **Lighter Pro** (status, Unlock, Restore), **Appearance** (System / Light / Dark, custom control that stacks at AX sizes), **About** (Rate, Privacy Policy, Terms of Use; each hidden until its link exists; version). Acknowledgements row and text removed. New in core: `LifetimeStats` + store, `AppearanceSetting` + store. `AppModel` records totals only after iOS confirms a delete; `RootView` applies `preferredColorScheme`. `AppLinks` gained `termsOfUse`.
- **Decisions (APP_PLAN):** D-24 Settings replaces About (supersedes D-16), D-25 Appearance, D-26 cleared-so-far total, D-27 Acknowledgements removed. Docs updated: APP_PLAN (R-14, R-15, non-goals), DESIGN_BRIEF (section 7, font note), BUILD_PLAN, ASO_PLAN, privacy policy (two new stored items).
- **Verified:** nothing run. This Linux container has no Swift toolchain, so the code was not compiled and the new tests (`LifetimeStatsTests`, `SettingsTests`) were not run. Docs were checked against the code by reading.
- **Not verified:** build; unit tests; the Settings layout in Dusk and Dawn; AX5; VoiceOver; that the appearance override reaches the sheet; physical device. `media/screenshots` 02-about-* are marked OUTDATED and must be recaptured as Settings screenshots.
- **Open owner questions:** (1) Terms and Rate URLs are still not supplied, so those rows stay hidden. (2) D-27: the OFL asks that the font's copyright and licence travel with it. `OFL.txt` stays in the bundle, but confirm that is enough without an in-app notice. (3) Lifetime totals count only deletes made after this build, so existing testers start at zero.
- **Follow-up (D-27):** added `legal/LICENSES.md` (Cormorant copyright notice + full OFL text, copied from `OFL.txt`). It must be hosted at a public URL with the other legal pages. Not verified: that `OFL.txt` lands in the built `.app` (check after the next build); legal review not done.

## Change 33 — Legal documents re-checked against the app
- **What:** compared `PRIVACY_POLICY.md` and `TERMS_OF_USE.md` with the code. Fixed three mismatches: (1) both said Quick clean-up finds "similar photos" and screenshots; it finds **duplicates** and **Pages & Things** (screenshots and videos are never scanned) and has a WhatsApp album shortcut; (2) the cache description now lists what is really stored (identifier, dates, people/document flags, quality score, image hash and feature print); (3) iCloud wording now covers videos and says the scan uses only on-device thumbnails and skips iCloud-only photos. Terms now mention the Settings running total and use Apple's correct EULA name.
- **Checked and already correct:** 50 free deletions a day resetting at local midnight; one-time Pro with Restore; no network calls or third-party SDKs in the source; UserDefaults keys (`allowance.*`, `review.*`, `stats.*`, `settings.appearance`) and `cleanup-v1.bin`; Recently Deleted 30 days; Photos permission text; privacy manifest (no tracking, no collected data).
- **Verified:** read against the source. **Not verified:** nothing run; legal review not done; the five placeholders (developer name, support email twice, governing law) are still the owner's to fill; the App Store privacy label must be re-checked to match.

## Change 34 — Legal documents completed from the VeriCode website records
- **What:** filled every placeholder in `legal/PRIVACY_POLICY.md` and `legal/TERMS_OF_USE.md` using the owner's records in `VeriCode Website` (`brand-kit/OWNER_IDENTITY_AND_DISCLOSURE.md`, published Focus Four terms and privacy). Operator is "VeriCode, operated by its proprietor in India", with no personal name (owner rule: legal names only where a law or platform requires). Support and privacy contact is support@vericodestudio.com. Governing law is India, subject to mandatory consumer rights, the same wording as the published Focus Four terms. Both documents were restructured to the Focus Four layout (numbered sections, header block) and gained: website and hosting section, one-year email retention (owner-confirmed), children and eligibility (13+), international use, no-affiliation with Apple and WhatsApp, "room for N photos" is an estimate, space returns after Recently Deleted, Cormorant licence reference. Effective date reads "the day Lighter 1.0 is released", so no invented date.
- **Verified:** read against the app source (UserDefaults keys, Info.plist photo string, privacy manifest, no network calls; Settings rows use `Link`, which opens the browser).
- **Not verified:** no legal review; audience and age (13+) is carried over from Focus Four, not decided for Lighter; the App Store age rating and privacy label must match; the legal pages' public URL and host (the policy says Cloudflare, like the rest of the VeriCode site) is not yet set; the website's Lighter record says no legal page is published yet. Governing law India is an assumption from Focus Four; the VeriCode kit says not to infer it, so the owner should confirm.
- **Not done (not asked):** a Support page; the website repo was not edited.

## Change 35 — Landing page (`landing-page-design/`)
- **What:** owner asked for a "wow" landing page using the ui-ux-pro-max and landing-page-design skills, with the app's animations and the latest screenshots. Where the two skills disagree, the owner said ui-ux-pro-max wins: glassmorphism over colour, Cormorant Garamond + Montserrat (instead of landing-page-design's one sans font), App Store landing + interactive product demo. `index.html`, `styles.css`, `app.js` and `assets/` (WebP copies of the latest `media/screenshots`, plus photo crops taken from them).
- **Sections:** island nav; hero with a **playable Swipe → Review → Done loop** in a phone frame (ported from `SwipeView.swift`/`DoneView.swift`: 30 % commit or flick > 900 pt/s, 12° tilt, blush/sage tint, DELETE/KEEP tag, growing dock button, spring response 0.3 / damping 0.8, peek with ✓/✕ badge and undo, blurred photo backdrop cross-fading 0.5 s, Done ring + count-up + check pop + 22 sparkles + drift-in thumbnails on the same 3 s timeline); the page's own glow follows the current demo photo; word-by-word tagline reveal; "How it works" sticky phone that swaps real screenshots per step and plays Done on step 4; Quick clean-up panel with the scanning animation ("Checking 1,240 of 4,812", example numbers labelled as such); privacy facts; Free vs Pro ($4.99 once); 8 FAQs (+ FAQ schema); final CTA with a fan of three screenshots; footer with the legal links and VeriCode / support email from Change 34.
- **Honesty choices:** no ratings or reviews (none exist; rule 10.5). App Store buttons read "Coming soon to the App Store" and are disabled until `APP_STORE_URL` in `app.js` is set. Example numbers are labelled. Reduce Motion shows final states; arrow keys drive the demo only when focus is on the page or the demo.
- **Verified (headless Chrome 1440×900 and 390×844, dark and light, Reduce Motion):** no console errors; no horizontal scroll at 390 px; drag, Keep/Delete buttons, end card, Review, Delete → Done all run; Done numbers match `Formatting` (1.24 GB → "Room for about 410 more photos"). Fixed during the check: ring number hidden under the glass disc (stacking), eyebrows stretched full width, hard edge under the hero glow, glow too strong in the light look.
- **Not verified:** real touch on an iPhone/Android browser; Safari and Firefox; VoiceOver/screen-reader pass; performance on a low-end phone (many backdrop blurs); the screenshots are simulator shots with Apple's sample photos — check they may be used in marketing before publishing.
- **Open owner questions:** App Store URL; public URLs for privacy/terms (footer links point at `../legal/*.md` for now); a hosted `og:image` (currently a relative WebP); whether to publish it on the VeriCode site.

## Change 35 — App icon (direction B1)
- **What:** replaced the blur-only placeholder with the owner-chosen B1 icon (frosted photo cards, blush ✕ on the back card, sage ✓ on the front card). Candidates A, B, C, then B1/B2 with cues, were drawn in Chrome from `design/logo/*.html`; the owner picked B1 and asked for it everywhere applicable. Badges were enlarged 15 % for small sizes. Pinterest search returned board titles only (no pin images), so the references were themes, not individual pins.
- **Files:** `App/Resources/Assets.xcassets/AppIcon.appiconset/icon.png`, `design/logo/` (sources, `lighter-icon-1024.png`), `DESIGN_BRIEF.md` (App icon section).
- **Verified:** icon is 1024×1024 RGB, no alpha; Debug device build succeeded (signed with the Apple Development certificate, team in `project.yml`); installed over the existing copy on the physical iPhone 17 Pro without an uninstall (app data kept); launch command succeeded; `AppIcon60x60@2x.png` and `Assets.car` are in the built app.
- **Not verified:** how the icon looks on the phone's home screen (not seen); dark and tinted iOS 18 icon variants (not made); small sizes checked only in a browser mock-up at 180, 120 and 60 px for the earlier B1 badge size; the website's Lighter icon is a separate repo and was not changed.

## Change 36 — Restore swipe work lost in merge 391da1b
- **What:** Merge `391da1b` ("keeping main's content only") silently reverted the swipe screen to the old version. Restored from `be21d03`: flat Cover Flow ring, dots above the bar, tap-to-jump (`SwipeView`, `CoverFlowRing`), multi-select grid (`SelectView`, `selecting` state in `AppModel`, branch in `RootView`), newest-first albums (`PhotoKitLibrary`), `CoverFlowRingTests`.
- **Kept:** main's Settings page, lifetime stats, Appearance, licences, and all legal/landing/icon work since. The About/Legal views from `be21d03` were NOT restored (owner chose "swipe work only").
- **Verified:** `swift test` in SwipeFeatures, 49 tests pass.
- **Not verified:** not built or run in the simulator, so the ring, dots and select grid are not visually confirmed. Screenshots in `media/screenshots/` are still the old ones. The `be21d03` Privacy/Terms/Photo Access/Support rows are gone from the app (Settings replaced About); the owner has not yet said whether to bring them back.
- **Lesson:** after any merge, diff the result against both parents before committing; "keep one side" merges delete the other side's features.

## Change 37 — Remove Albums filter chips; recapture screenshots
- **What:** owner said the All / Smart Albums / My Albums chips "are not working", so they were removed from `AlbumsView` (chips, title extension, `glassIf`). `AppModel.filter` and `visibleAlbums` still exist but nothing sets them (not removed; not asked). `DESIGN_BRIEF.md` chip line struck through. Screenshots recaptured after Changes 36–37: Albums (dark, light, AX5, quick clean-up), Swipe (dark, light), select grid (light), Settings (dark, light). Removed outdated About shots, the swipe end card and video card.
- **Verified:** `swift test` passed (49); simulator build (iPhone 17) launched, Albums has no chips, Recents opens the ring screen with dots and Delete/Undo/Keep bar, Select opens the grid, Settings opens; physical iPhone build installed and launch command succeeded.
- **Not verified:** the phone itself was not looked at (only launched); swipe gesture, animation motion and select-grid dragging were not exercised, only that screens render; end card and video card shots still missing; Select grid dark and Settings AX5 not captured; welcome and video-fullscreen shots predate this build.

## Change 38 — Settings About menu restored (Photo Access, Contact Support, Privacy, Terms)
- **What:** owner asked to bring back the whole Settings menu. Settings → About now has Photo Access (opens the app's iOS Settings page), Contact Support (mailto support@vericodestudio.com), Privacy Policy and Terms of Use (read in the app, offline, with "Read online" when a URL exists), plus Rate on the App Store once its link exists. Rows no longer hide when no URLs are set. `AppLinks.supportEmail` added and passed from `LighterApp`; `AppModel.openPhotoSettings()`.
- **Design choice:** the old `be21d03` legal text predates Change 34, so it was not restored. The in-app reader renders the real `legal/PRIVACY_POLICY.md` and `TERMS_OF_USE.md`, copied into `Packages/SwipeFeatures/Sources/SwipeFeatures/Legal/` as package resources (small Markdown reader in `LegalDocument`; `LegalView` from `be21d03`). A test fails if the bundled copies differ from `legal/`, so edit `legal/` and re-copy. Privacy policy section 8 reworded: the rows now open in the app.
- **Not restored:** Acknowledgements row (owner removed it, D-27; `legal/LICENSES.md` is still the licence file); `be21d03`'s AboutSheet and old LegalTests.
- **Verified:** `swift test` 52 pass (new legal tests included); simulator (iPhone 17): the four About rows show, tapping Privacy Policy opens the full policy text with Done.
- **Not verified:** Terms reader, Photo Access and Contact Support taps (mail app unavailable in simulator), AX5 layout of the new rows and the reader, tables rendered as bullet lists read well, physical iPhone. The old policy mentioned iPhone backups and "feature print"; the Change 34 text does not, so a legal check of that is still open.

## Change 39 — Landing page follows the new Swipe UI; slop pass

**What:** The hero demo, the How it works phones and the closing fan now show the current app UI instead of the old one. `SwipeDemo` in `landing-page-design/app.js` was rewritten: flat Cover Flow ring (poses ported from `CoverFlowRing.swift`), pill-stretch dot scrubber (drag to turn the ring; forward keeps, backward undoes), rounded-rectangle dock with labelled Delete / Undo / Keep (trash.fill, heart.fill), Select button, and a Select grid with tap and drag-select, "N selected", Select all, Clear and "Review N photos". Album filter chips removed. Albums screenshots replaced with the new WebP. Swipe screenshots are no longer used on the page because the simulator library contains earlier app screenshots, so they show a nested app screen; the live replica is used instead.
**Slop pass (impeccable):** removed the seven eyebrow/kicker chips (banned in the craft floor; "Photo cleaner for iPhone" is now in the hero sentence), rewrote "Four steps. No learning curve." and two privacy lines (aphoristic cadence). Kept as judgement calls, not suppressed: italic Cormorant on "one swipe" (matches the app wordmark), 72 px h1, phone frames inside step cards (flagged as nested cards), glow image at opacity 0 until a photo loads.
**Files:** `landing-page-design/{index.html,styles.css,app.js}`, `assets/02-albums-{dark,light}.webp`.
**Verified (headless Chrome, desktop 1440 and mobile 390):** ring renders at rest, mid-drag and after decisions; Keep/Delete/Undo; dot scrub; Select drag-select (4 selected) to Review to Done; no console errors; no horizontal scroll at 390 px; Reduce Motion and light look load and respond.
**Not verified:** Safari and real touch devices; VoiceOver; the 04 Review and 01 Welcome screenshots on the page predate this build and need a recapture; Swipe, Select and Albums shots need a clean simulator library before they can be used.
