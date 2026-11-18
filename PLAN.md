# Swipe and Delete — Detailed Plan

Companion to `SPEC.md`. UI mockups and the architecture diagram are on the
design canvas: https://claude.ai/artifact/Jn3jbGXcMaqwmxhM4HLq5z

---

## 1. UI

### Visual language: Neumorphism + Glassmorphism
Everything sits on **one soft grey surface**. Controls look pressed out of it
(raised) or pressed into it (inset). Frosted glass is used only over photos.
Colour appears only as small glowing "LED" dots and icons.

| Token | Value | Use |
|---|---|---|
| Surface | `#E6E9EE` | Every screen background and control fill |
| Shadow dark / light | `#C3C8D0` / `#FFFFFF` | Neumorphic pair |
| Raised | `8 8 18 dark, -8 -8 18 light` | Buttons, cards, album tiles |
| Pressed / inset | the same pair, `inset` | Tracks, pressed buttons, counters, Review grid well |
| Glass | white 28–35 %, blur 14, 1 px white 55 % border | Date label, DELETE/KEEP tag and badges over photos |
| Text | `#2B2F36`, secondary `#4F5560` (≥ 4.5:1 on surface) | |
| LED coral | `#EA580C` + glow `#F97316` | Delete |
| LED teal | `#14B8A6` + glow `#2DD4BF` | Keep |
| LED indigo | `#4F46E5` + glow `#818CF8` | Primary "go" actions |
| Font | Outfit (or SF Pro Rounded) | Titles 34–40 **Light 300**, body 15–17 Regular/Medium |
| Radius | Cards 30–34, buttons fully round, pills 17–23 | |

Rules
- Pressing a button switches it from raised to inset (150 ms). The swipe
  buttons do the same when a swipe commits.
- The album switcher is an **inset track** with the selected pill raised
  inside it, like the "MANUAL" toggle in the kit.
- The photo card sits in a raised 8 pt frame. Photos never get neumorphic
  shadows themselves.
- Neumorphism is low-contrast by nature: never rely on shadows alone to show
  state. Pair with an LED, an icon or a word. With Increase Contrast on, add a
  1 pt `#9AA1AC` border to all controls.
- In SwiftUI, a `NeuButtonStyle` uses
  `.shadow(color: dark, radius: 9, x: 8, y: 8).shadow(color: .white, radius: 9, x: -8, y: -8)`.
  Inset uses an overlay stroke with blur and mask, and glass uses
  `.background(.ultraThinMaterial)`.

### Screens
1. **Welcome**: illustration, the line "Swipe left to delete, right to keep",
   and an **Allow Photo Access** button. Below it: "Your photos never leave
   this iPhone."
   - Denied or restricted → the same screen with **Open Settings**.
2. **Albums**: a large title. A 2-column grid of smart albums (All Photos,
   Screenshots, Videos, Selfies) and a list of the user's own albums, each with
   a cover and a count. Limited access adds a **Manage selection** link.
   Empty albums are hidden.
3. **Swipe (side-by-side carousel)**: a light screen (soft grey `#E6E9EE`) based on the
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
5. **Done**: a check mark, plus "7 deleted · 31 kept" and **Back to
   Albums**.

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
    DoneView.swift
  Shared/
    Theme.swift                  // surface, shadows, LEDs, radii
    NeuStyles.swift              // NeuButtonStyle, .neuRaised(), .neuInset(), .glass()
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
| 6 | Review + delete + Done | iOS prompt; cancel keeps you on Review |
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
