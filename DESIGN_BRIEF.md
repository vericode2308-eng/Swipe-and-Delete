# Lighter — Design Brief

Read this before any UI work. Scope comes from `APP_PLAN.md`.
Mock-ups: https://claude.ai/artifact/Jn3jbGXcMaqwmxhM4HLq5z

## 1. Visual language

Calm, polished, slightly cinematic. Frosted glass over colour, an elegant
serif for titles, soft pastel accents. Two looks that follow the iPhone's
appearance setting (D-15): **Dusk** (dark) and **Dawn** (light).

### Tokens

| Token | Dusk (dark) | Dawn (light) | Use |
|---|---|---|---|
| Base | Slate `#262E3B` | Mist `#EEF1F6` | Under every blur |
| Photo backdrop | Current photo, blur 50, slate scrim 55 % | Current photo, blur 50, mist scrim 60 % | Swipe, Welcome, Done |
| Colour field | Blobs `#5E7AA6`, `#9A6F80`, `#3F6B66`, blur 70–80 | Blobs `#A9BCDA`, `#E3C3CD`, `#B7D6CF`, blur 70–80 | Behind glass with no photo |
| Glass | White 12 %, blur 24, saturation 170 %, edge white 34 %, top highlight white 45 %, shadow black 28 % r15 y10 | White 55 %, blur 24, saturation 170 %, edge white 80 %, top highlight white 100 %, shadow `#28374F` 12 % r15 y10 | Buttons, chips, dock, panels |
| Glass (caption) | Slate 32 %, same blur | White 70 %, same blur | Captions and tags over photos |
| Text | `#F4F6FA`, secondary `#C9D2E0` | `#1F2633`, secondary `#566072` | |
| Primary pill | Mist `#E6ECF5`, text `#1F2633` | Slate `#262E3B`, text `#F4F6FA` | One per screen |
| Delete | Blush `#F2B8A8` (icon), button text `#2A1A16` | Fill `#F2B8A8`, icon/text `#A4472F` | ✕, DELETE tag, Delete N button |
| Keep | Sage `#A9DCCD` | Icon/text `#2F7A66` | ✓, KEEP tag |
| Display font | Cormorant Garamond 600 (wordmark 500 italic) | same | Titles, dates, big numbers |
| Body font | SF Pro (system) 300–600 | same | Everything else; caps labels tracked +1.5 |
| Radius | Card 30, tiles 22, panels 24–34, pills fully round | same | |
| Spacing | 4-pt grid: 4, 8, 12, 16, 20, 24, 32 | same | |

Contrast: every text/background pair ≥ 4.5:1 (body) and ≥ 3:1 (large text,
icons) in both looks, checked over the lightest and darkest photo scrim.

### Rules
- **The photo is the decoration.** The Swipe background is the current photo,
  heavily blurred; it cross-fades (0.5 s) to the next.
- **Glass everywhere, always over colour** (blurred photo or colour field),
  never over the flat base.
- **Capsule main buttons** (D-14): primary actions are full-width pills.
  Chips are capsules too. Round icon buttons for Delete / Undo / Keep.
- One primary pill per screen. Everything else is glass.
- Colour is never the only cue: blush always with ✕ or "Delete", sage always
  with ✓ or "Keep".
- Serif only for titles, dates and big numbers.
- Copy uses **British spelling** (colour, favourites). Code identifiers stay
  as they are.
- Reduce Transparency → glass becomes solid (`#323B4B` Dusk, `#FFFFFF` Dawn)
  with the same edge.
- Animations are few and calm. Under Reduce Motion: cross-fades only.

### SwiftUI recipe (in `SwipeUI`)
- `.appBackdrop(photo:)`: `Image.resizable().scaledToFill().blur(radius: 50)`
  plus the scrim colour for the current scheme.
- `.appCanvas()`: base colour plus the three blurred blobs.
- `.glass(in: shape)`: `.background(.ultraThinMaterial, in: shape)`, a tint
  fill for the scheme, an edge stroke, a top-highlight gradient stroke and the
  shadow. Falls back to solid under Reduce Transparency.
- Tokens live in one `Theme` with light/dark variants. Bundle Cormorant
  Garamond (SIL OFL; list it in Acknowledgements).
- `#Preview`s for every component in light, dark and AX3.

## 2. Screens

### 1. Welcome
- Full-bleed landscape illustration (drawn in code), fading into the base.
- Italic wordmark "Lighter", line "A calmer camera roll, one photo at a
  time."
- A glass panel with two glass rows: "← Swipe left to delete" (blush icon),
  "→ Swipe right to keep" (sage icon).
- Primary pill **Allow Photo Access**. Footnote "Your photos never leave this
  iPhone."
- Denied or restricted → the pill reads **Open Settings**, with one line on why.

### 2. Albums
- Colour-field backdrop. Serif title "Albums" and an ⓘ glass button (About).
- **Quick clean-up** (D-18): serif heading, small caption "Found on this
  iPhone", then one large glass panel with three rows (58 pt high, radius 18):
  round tinted icon · name · one-line detail · count · chevron.
  - Duplicates — two overlapping squares, mist tint — "Same or near-identical
    shots" — "86 in 31 sets".
  - Pages & Things — page icon, blush tint — "Notes, documents, no people" —
    "212".
  - From WhatsApp — chat-bubble icon (never the WhatsApp logo), sage tint —
    "Saved from your chats" — "1,480". Hidden if there is no WhatsApp album.
  - While scanning: the detail line becomes "Checking 1,240 of 4,812" with a
    2 pt progress hairline under the row; the count grows as results arrive.
    Reduce Motion: no animated hairline, text only.
  - Nothing found: "None found", dimmed, not a button.
- Glass filter chips: All / Smart Albums / My Albums.
- Two-column grid of album tiles (radius 22) with a glass caption bar: name and
  count. Empty albums hidden.
- Limited access → a glass row "Limited access · Manage selection".

### 3. Swipe (side-by-side carousel)
- Background: the current photo, blurred, under the scrim.
- Top bar: glass back button, serif album title with "38 of 1,206", glass
  **Review** button with a trash icon and the marked count.
- Album chips under the title. Selected = primary colour, others = glass.
  Switching album with marks shows a confirm ("Discard 9 marks?").
- **Carousel:** the current card (radius 30) in the centre. The next photo
  peeks from the right edge. The previous photo peeks from the left with a
  ✓/✕ badge; tapping it = Undo.
- Caption on the card (caption glass): date in serif, type in caps (PHOTO /
  SCREENSHOT / LIVE PHOTO / VIDEO · 0:14).
- From a clean-up filter the title is the filter name. In Duplicates the
  caption adds a small glass chip "Set 3 · 2 of 3"; sets follow each other
  with no divider cards. Album chips are hidden for
  filters (back returns to Albums).
- **Drag:** the card follows the finger with tilt (max 12°). A DELETE or KEEP
  glass tag fades in, the card tints blush or sage, the matching dock button
  grows.
- **Commit** at 30 % of the width or on a fast flick: the card flies off that
  way (spring 0.3 s, damping 0.8), the next card slides in, the decided card
  becomes the left peek. Below the threshold it springs back.
- **Glass dock** (capsule): ✕ Delete · Undo (small) · ✓ Keep.
- Videos show a play button; Live Photos play on long-press; tap opens a
  zoomable full-screen view.
- End of album → a "That's all" card with **Review deletions**.
- Haptics: light impact on commit, none while dragging.

### 4. Review
- Colour-field backdrop. Glass back button, serif "9 to delete", line "Tap a
  photo to keep it instead."
- A 3-column grid inside a large glass panel. Each tile has a glass ✕ badge;
  tapping dims it and shows ✓.
- Glass note: "Deleted photos stay in Recently Deleted for 30 days. With iCloud
  Photos on, they're removed from your other devices too."
- Duplicates only: if every copy of a set is marked, a glass note "All
  copies of 2 sets are marked. Tap one to keep it." (a reminder, never a
  block).
- Free plan only: a small line above the button, "Free plan: 50 deletions a
  day · 32 left today". Pro users never see it.
- Primary pill (blush) **Delete 9 photos** → iOS prompt. Zero marked → back to
  Albums.

### 5. Paywall (sheet, only from Review — R-13)
- Shown when marked > today's allowance.
- Serif title "Delete them all", line "Free plan deletes up to 50 photos a day.
  You've marked 72."
- Glass panel listing what Pro adds, with real numbers: "Unlimited deletions,
  every day", "One-time purchase: $4.99 (shown in local currency), no
  subscription", "Everything else stays the same".
- Primary pill **Unlock Pro – $4.99**. Glass button **Delete 50 now** (the
  first 50 marked). Text buttons **Restore Purchases** and **Not now**.
- Price comes from StoreKit; if it cannot load, show "Price unavailable" and
  disable the pill, never a fake price.

### 6. Done (celebration — D-09)
About 3 seconds; **Back to Albums** works from the first frame and a tap
skips to the end.

| Time | What happens |
|---|---|
| 0–1.0 s | The deleted photos drift into the centre, shrink and fade, 70 ms apart |
| 0.5–1.9 s | A ring (mist → sage → blush) around a glass disc fills while the size counts up: "0 MB" … "640 MB" … "1.2 GB", ease-out. Label "CLEARED" |
| 1.9 s | Sage check pops on the ring (spring overshoot), soft glow, 22 sparkles burst and fade, success haptic |
| 2.0–3.0 s | "Beautifully done" / "Screenshots is 1.2 GB lighter." rises in, then the glass stats strip (reviewed · kept · deleted, counting up), then the glass chip "Room for about 400 more photos" |

- Footnote: "Space returns once Recently Deleted empties. Changed your mind?
  Restore within 30 days."
- "Room for about N more photos" = bytes ÷ 3 MB, rounded to a friendly number.
- Reduce Motion: final state with a 0.3 s fade, plus the haptic.
- Sparkles cover the whole screen layer, never clipped to a container.

### 7. About (sheet from Albums ⓘ — R-14)
- Pro status ("Pro · thank you" or "Free · 50 deletions a day").
- Rows: Unlock Pro (free only), Restore Purchases, Rate on the App Store,
  Privacy Policy, Acknowledgements (Cormorant Garamond, SIL OFL), version.

## 3. Accessibility (every screen, as it is built)
- Every action has a button. VoiceOver custom actions on the card: Delete,
  Keep, Undo. Announce "Marked for deletion, 39 of 1,206".
- The card is one element: "Photo, 14 March 2024".
- Dynamic Type to AX5: album grid → one column; titles on their own line; no
  truncation of content; dock buttons keep 44 pt minimum.
- Clean-up rows read as one element: "Duplicates, 86 photos in 31 sets,
  button". While scanning: "Checking photos, 1,240 of 4,812".
- Done reads as "1.2 gigabytes cleared. 38 reviewed, 31 kept, 7 deleted."
- Check iPhone SE and the largest iPhone in both looks.
