# Swipe and Delete — Detailed Plan

Companion to `SPEC.md`. UI mockups and the architecture diagram are on the
design canvas: https://claude.ai/artifact/Jn3jbGXcMaqwmxhM4HLq5z

---

## 1. UI

### Visual language: "Dusk"
Calm, polished, slightly cinematic. Based on the InSleep reference: moody
slate-blue, blurred photo backgrounds, frosted glass, hairline outlines, and an
elegant serif.

| Token | Value | Use |
|---|---|---|
| Base | Slate `#262E3B` | Albums, Review; under every blur |
| Photo backdrop | Current photo, blur 50, slate scrim 55 % | Swipe, Welcome, Done |
| Glass (light) | white 12 %, blur 24, saturation 170 %, 1 pt white 34 % edge, 1 pt inner top highlight white 45 %, soft drop shadow | Buttons, pills, control dock, panels |
| Glass (dark) | slate 32 %, the same blur, edge and highlight | Captions and tags over photos |
| Colour field | 3 large blurred blobs (steel blue `#5E7AA6`, rose `#9A6F80`, pine `#3F6B66`) | Behind glass on screens with no photo backdrop |
| Text | `#F4F6FA`, secondary `#C9D2E0` (≥ 7:1 on slate) | |
| Primary pill | Mist `#E6ECF5`, text `#1F2633` | Allow access, Review, Back to Albums, selected album |
| Delete | Blush `#F2B8A8` | ✕ icon, DELETE tag, Delete N button (dark text) |
| Keep | Sage `#A9DCCD` | ✓ icon, KEEP tag |
| Display font | Cormorant Garamond 600 (wordmark: 500 italic) | Titles, dates, numbers |
| Body font | Inter / SF Pro 300–600 | Everything else; caps labels tracked +1.5 |
| Radius | Card 30, tiles 22, pills fully round | |

Rules
- **The photo is the decoration.** The swipe screen background is the current
  photo, heavily blurred. It cross-fades (0.5 s) when the next photo arrives,
  so the whole screen shifts mood with each image.
- **Glassmorphism everywhere.** Every control is a pane of frosted glass,
  and glass always sits over colour (the blurred photo or the colour field),
  never over flat slate.
- The swipe buttons sit in a floating **glass dock** (capsule). The Review
  grid and the Welcome hints sit in large glass panels.
- Colour stays soft and sparse: only blush and sage, always with an icon or a
  word.
- One light primary pill per screen. Everything else is glass or a hairline.
- Serif only for titles, dates and big numbers. Never use it for buttons or
  body text.
- SwiftUI: background = `Image(uiImage:).resizable().scaledToFill().blur(radius: 50)` plus
  `Color(slate).opacity(0.55)`. Glass = `.background(.ultraThinMaterial, in: shape)`, then
  `.overlay(shape.stroke(.white.opacity(0.34)))`, then a top highlight via
  `.overlay(shape.stroke(LinearGradient(white 45 % → clear), lineWidth: 1))`,
  then `.shadow(color: .black.opacity(0.28), radius: 15, y: 10)`. Bundle Cormorant
  Garamond (OFL licence).
- Reduce Transparency → replace glass with solid `#323B4B`.

### Screens
1. **Welcome**: illustration, the line "Swipe left to delete, right to keep",
   and an **Allow Photo Access** button. Below it: "Your photos never leave
   this iPhone."
   - Denied or restricted → the same screen with **Open Settings**.
2. **Albums**: a large title. A 2-column grid of smart albums (All Photos,
   Screenshots, Videos, Selfies) and a list of the user's own albums, each with
   a cover and a count. Limited access adds a **Manage selection** link.
   Empty albums are hidden.
3. **Swipe (side-by-side carousel)**: a light screen (blurred current photo over slate) based on the
   reference design. The top shows the album name as a large title, "38 of
   1,206", and a **Review** pill with a coral badge for the marked count.
   - **Album pills** sit under the title (All Photos, Screenshots, Videos,
     Selfies, your albums). The selected pill is indigo. Tapping a pill
     switches album and starts from item 1.
   - **Carousel:** one large rounded card (radius 30) sits in the centre. The
     **next** photo peeks in from the right edge and the **previous** photo
     peeks from the left edge with a small ✓/✕ badge. Tapping the left peek =
     Undo.
   - A soft blurred **glow** sits under the card. It is indigo at rest, turns
     coral while dragging left and teal while dragging right.
   - **Drag:** the card follows your finger with a slight tilt (max 12°). A
     DELETE or KEEP label fades in, the card tints coral or teal, and the
     matching round button grows.
   - **Commit** at 30% of the width or on a fast flick. The card flies off in
     that direction (spring, ~0.3 s), the right peek slides into the centre,
     and the decided card becomes the new left peek. Below the threshold the
     card springs back.
   - **Buttons:** round white buttons with ✕ Delete (coral) · Undo (small) ·
     ✓ Keep (teal). Each button plays the same fly-off animation.
   - Below the card: the date and type (Photo / Screenshot / Live Photo /
     Video 0:14). Videos show play; Live Photos play on long-press; tap opens
     a zoomable full-screen view.
   - End of album → an "End of album" card with **Review deletions**.
4. **Review**: "9 items to delete". A 3-column grid with a coral ✕ badge on
   each photo. Tap a photo to keep it instead: it dims and gets a teal ✓
   badge. A footnote explains Recently Deleted and iCloud. A coral **Delete 9
   items** button triggers the iOS prompt.
   - Zero marked → skip this screen and go back to Albums.
   - The user cancels the iOS prompt → stay on Review.
5. **Done (celebration)**: a sense of achievement in about 3 seconds.
   **Back to Albums** works from the first frame, and tapping the screen skips
   to the end.

   | Time | What happens |
   |---|---|
   | 0–1.0 s | The deleted photos (small tiles, like the Review grid) drift up into the centre, shrink and fade, staggered 70 ms apart |
   | 0.5–1.9 s | A thin ring (mist → sage → blush gradient) around a glass disc fills while the number counts up: "0 MB" … "640 MB" … "1.2 GB", with ease-out |
   | 1.9 s | A sage check badge pops on the ring (spring overshoot), with a soft glow, 22 tiny sparkles (dots and streaks in mist, sage, blush, white) bursting outward and fading, and `.sensoryFeedback(.success)` |
   | 2.0–3.0 s | "Beautifully done" / "Screenshots is 1.2 GB lighter." rises in, then a glass stats strip (38 reviewed · 31 kept · 7 deleted, counting up), then a glass chip "Room for about 400 more photos" |

   - The footnote says "Space returns once Recently Deleted empties", because
     iOS frees the space only after 30 days, or when the user empties
     Recently Deleted.
   - "Room for about N more photos" = bytes freed ÷ 3 MB, rounded.
   - With Reduce Motion, show the final state with a 0.3 s fade, plus the
     haptic. No tiles, sparkles or count-up.
   - Ideas taken from cleaner apps' success screens (freed-size headline,
     stat cards, confetti and haptics), kept quiet and classy: no rocket, no
     medal, no rating prompt.

### Accessibility
- All actions are reachable with buttons. VoiceOver custom actions on the card:
  "Delete", "Keep", "Undo".
- Announce after each decision ("Marked for deletion, 39 of 1,206").
- Dynamic Type: controls wrap. Reduce Motion: cross-fade instead of fly-off.
- Touch targets ≥ 44 pt.

---

## 2. Architecture

```
SwiftUI Views ──▶ @Observable state ──▶ Services ──▶ PhotoKit
```

### Project layout
```
SwipeAndDelete/
  App/
    SwipeAndDeleteApp.swift      // @main, injects AppModel
    AppModel.swift               // auth status, navigation path
  Photos/
    PhotoLibrary.swift           // protocol + Album/Asset value types
    PhotoKitLibrary.swift        // real PhotoKit implementation
    FakePhotoLibrary.swift       // previews + tests
    ImageLoader.swift            // PHCachingImageManager wrapper
  Swipe/
    SwipeSession.swift           // the only real logic
  Views/
    WelcomeView.swift
    AlbumListView.swift
    SwipeView.swift              // carousel: prev peek · card · next peek
    PhotoCard.swift
    AlbumPills.swift
    ReviewView.swift
    DoneView.swift            // celebration timeline
    CelebrationRing.swift     // ring + count-up + sparkles (Canvas/TimelineView)
  Shared/
    Theme.swift                  // slate, mist, blush, sage, fonts, radii
    Glass.swift                  // .glassPill(), .glassPanel(), BlurredBackdrop
SwipeAndDeleteTests/
  SwipeSessionTests.swift
```

### Key types
```swift
struct Album: Identifiable { let id: String; let title: String; let count: Int; let kind: Kind }
struct Asset: Identifiable { let id: String; let date: Date?; let mediaType: MediaType }

protocol PhotoLibrary {
    func authorize() async -> AuthStatus          // .full, .limited, .denied
    func albums() async -> [Album]
    func assets(in album: Album) async -> [Asset] // oldest → newest
    func byteSize(of ids: [String]) async -> Int64 // for the Done screen
    func delete(_ ids: [String]) async throws     // one performChanges call
}

@Observable final class SwipeSession {
    let album: Album
    let assets: [Asset]
    private(set) var index = 0
    private(set) var marked: [String] = []        // ordered, unique
    private var history: [Decision] = []          // undo stack

    func keep()   { record(.keep) }
    func delete() { marked.append(current.id); record(.delete) }
    func undo()   { /* pop history, index -= 1, unmark if needed */ }
    func unmark(_ id: String)                      // from Review
    var isFinished: Bool { index >= assets.count }
}
enum Decision { case keep, delete }
```

### Rules
- A new `SwipeSession` is created every time an album is opened. Nothing is
  saved. Closing the app forgets everything.
- `PhotoKitLibrary.delete` is the **only** code that changes the library. It
  runs `PHPhotoLibrary.shared().performChanges { PHAssetChangeRequest.deleteAssets(...) }`.
- Before deleting, re-fetch the ids and drop any that no longer exist.
- `ImageLoader` requests screen-sized images (`.opportunistic`,
  `isNetworkAccessAllowed = true`), prefetches the next 3 assets, and stops
  caching passed ones. A late image for a previous card is ignored (check the
  asset id).
- Observe `PHPhotoLibraryChangeObserver`. If the open album changes, keep the
  session going and skip missing assets.
- Carousel animation in SwiftUI: a `ZStack` of three `PhotoCard`s (prev,
  current, next) positioned with `offset`. Use a `DragGesture` for the current
  card's offset and rotation, and `withAnimation(.spring(response: 0.3,
  dampingFraction: 0.8))` on commit. Change `index` after the fly-off
  completes. Reduce Motion → cross-fade.
- **Freed size:** before deleting, sum each marked asset's
  `PHAssetResource.assetResources(for:)` sizes via the `fileSize` value
  (read with KVC; it is not a documented API, so treat a missing value as 0
  and show "about"). Do this off the main thread on the Review screen, and
  pass the total to Done as `DeleteResult(deleted:kept:reviewed:bytes:)`.
  Format with `ByteCountFormatter` (`.file`). iCloud-only originals still
  report their size.
- **Celebration in SwiftUI:** use `PhaseAnimator` or `keyframeAnimator` for
  the ring trim (`Circle().trim(from:0,to:p)` with an `AngularGradient`
  stroke), and `.contentTransition(.numericText(value:))` for the count-up.
  Draw the sparkles in one `Canvas` inside a `TimelineView(.animation)`, so
  it's one view rather than 22. The tiles are plain animated offsets. Use `.sensoryFeedback(.success, trigger: popped)`.
- Required `Info.plist` key: `NSPhotoLibraryUsageDescription`.

---

## 3. Build plan

| Step | What | Done when |
|---|---|---|
| 1 | Xcode project, Theme, `PhotoLibrary` protocol, Fake library | Previews show fake albums |
| 2 | `SwipeSession` + unit tests | keep/delete/undo/unmark tests pass |
| 3 | Welcome + permission flow (full / limited / denied) | All three states work on a device |
| 4 | Albums screen with real PhotoKit data | Counts match the Photos app |
| 5 | Swipe screen: card, buttons, drag gesture, haptics, ImageLoader | Smooth on 1,000+ item album |
| 6 | Review + delete + Done celebration | iOS prompt; cancel keeps you on Review; freed size matches Settings › Storage after emptying Recently Deleted |
| 7 | Video / Live Photo playback, zoom | Plays, audio stops on swipe |
| 8 | Accessibility + Reduce Motion pass | VoiceOver can finish a full album |
| 9 | TestFlight | Tested on a disposable photo set |

### Test checklist
- Undo after a delete-swipe removes it from the marked list.
- Re-opening an album starts at item 1 with nothing marked.
- Cancelling the iOS prompt deletes nothing and keeps the marks.
- A photo deleted in the Photos app mid-swipe is skipped without a crash.
- Limited access shows only the selected photos.
- An iCloud-only photo shows a spinner and then loads. Offline shows "Not
  downloaded" and still allows Keep.
