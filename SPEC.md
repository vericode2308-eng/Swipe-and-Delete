# Swipe and Delete — Product Spec (v1)

A minimal iPhone app for clearing out the camera roll by swiping.

## Core idea
Pick an album. Swipe through every photo, starting at the first one.
- **Swipe left:** delete
- **Swipe right:** keep

Nothing else. There is no Later, no sessions, no history, no stats.

## Screens

### 1. Albums
- On first launch, ask for Photos access (full or limited).
- List the albums: All Photos, Screenshots, Videos, and the user's own albums.
  Each one shows a cover thumbnail and an item count.
- Tapping an album opens Swipe at that album's **first** item.

### 2. Swipe
- One photo or video fills the screen, aspect-fit, on a dark background.
- Swipe left to mark for deletion, swipe right to keep.
- Delete and Keep buttons are provided too (for accessibility and one-handed use).
- One **Undo** button reverses the last swipe.
- A small counter shows progress, e.g. "37 / 512".
- A **Done** button ends early.

### 3. Confirm
- Shown when the album runs out or when Done is tapped.
- Shows a grid of photos marked for deletion. Tap one to unmark it.
- **Delete N items** calls iOS's own delete prompt.
- If nothing is marked, return to Albums.

### 4. Done
- A short celebration (about 3 seconds, never blocks the button): the deleted
  photos drift into a glass ring, the ring fills while the cleared size counts
  up (e.g. "1.2 GB"), then a check pops with a soft sparkle burst and a
  success haptic.
- Shows reviewed / kept / deleted counts and "Room for about N more photos".
- Honest note: space comes back once Recently Deleted empties.

## Rules
- **No memory between visits.** Opening an album always starts from the
  beginning. Keep decisions are not saved, so kept photos show up again next time.
- Marks only exist in memory until the user confirms. If the app is closed
  first, the marks are lost and nothing is deleted.
- Deleted items go to iOS's *Recently Deleted* album (30-day recovery).
  iCloud Photos syncs the deletion to the user's other devices.
- The app never uploads anything and has no account or server.

## Tech
- SwiftUI, PhotoKit, iOS 17+. No persistence layer.
- Delete via one `PHPhotoLibrary.performChanges { PHAssetChangeRequest.deleteAssets(...) }`.
- Load screen-sized previews only, and prefetch the next 2–3 items.

## Out of scope
Later queue, saved progress, duplicate detection, similar-photo detection,
duplicate-size scans of the whole library, saved statistics or history,
video compression, cloud features. (The only size shown is the total of the
items just deleted, on the Done screen.)
