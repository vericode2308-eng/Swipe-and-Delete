# Lighter — App Plan

This document wins on scope. If another document disagrees with it, this one is
right and the other must be fixed.

Companion documents: `DESIGN_BRIEF.md` (screens and look), `BUILD_PLAN.md`
(architecture, stages, tests), `ASO_PLAN.md` (App Store), `MASTER.md`
(change log), `CLAUDE.md` (standing rules).
Design canvas: https://claude.ai/artifact/Jn3jbGXcMaqwmxhM4HLq5z

## Core
- **Core function:** clear out your iPhone photos by swiping: left deletes,
  right keeps.
- **Core loop:** pick an album or a quick clean-up filter → swipe each photo left or right → review the
  marked ones → delete → celebrate → pick the next album.
- **Time to value:** the first swipe happens within 2 taps of a granted
  permission (tap an album, then swipe).

## Requirements

| ID | Requirement |
|---|---|
| R-01 | Ask for Photos access. Support full, limited (with "Manage selection") and denied (with "Open Settings"). |
| R-02 | List albums: All Photos, Screenshots, Videos, Selfies, Favourites and the user's own albums, each with a cover and a count. Hide empty albums. |
| R-03 | Opening an album always starts at its first item (oldest first). Nothing from an earlier visit is remembered. |
| R-04 | Swipe left = mark for deletion. Swipe right = keep. Buttons do the same. |
| R-05 | One Undo reverses the last decision, repeatedly back to the first item. |
| R-06 | Album chips on the Swipe screen switch album and start from item 1. Switching discards current marks after a confirm ("Discard 9 marks?") if any exist (owner confirmed, D-23). |
| R-07 | Review shows every marked item. Tapping one unmarks it. |
| R-08 | Delete runs one iOS delete prompt for all marked items. Cancel stays on Review with marks intact. |
| R-09 | Deleted items go to Recently Deleted (30 days); the app says so before and after deleting. |
| R-10 | Done screen: a short celebration with the total size cleared, counts (reviewed, kept, deleted) and "Room for about N more photos". |
| R-11 | Free plan: up to **50 deletions per calendar day** (device's local time). Swiping, keeping and reviewing are always unlimited. |
| R-12 | Pro: one-time purchase (**$4.99**, StoreKit 2, non-consumable) removes the daily limit. Restore Purchases is always available. |
| R-13 | Paywall appears only when the user taps Delete with more marked than today's allowance left. It offers **Unlock Pro** and **Delete N now**, where N = deletions left today (50 on a fresh day; the first N marked, in order). The marks left over are dropped, not kept for tomorrow (D-22). Never on launch. |
| R-14 | Settings sheet (from a gear button on Albums; replaces the About sheet, D-24): space cleared so far (D-26), Pro status, Unlock Pro, Restore Purchases, Appearance (D-25), Rate on the App Store, Privacy Policy, Terms of Use, version. |
| R-15 | Light and dark looks. They follow the iPhone's appearance setting unless the user picks Light or Dark in Settings (D-25). |
| R-16 | Full VoiceOver, Dynamic Type up to AX5, Reduce Motion and Reduce Transparency support. |
| R-17 | The app never uploads anything. No account, no server, no analytics. |
| R-18 | **Quick clean-up** section at the top of Albums with three filters. Each opens the normal swipe flow (nothing is ever deleted automatically). Free for everyone, whole library (D-19). |
| R-19 | **Duplicates:** exact copies anywhere in the library, plus near-identical shots taken within 60 seconds of each other. Shown set by set; the card says "Set 3 · 2 of 3". |
| R-20 | **Pages & Things:** photos with no people that Apple's photo-quality check flags as "utility" (pages, notes, documents, receipts, things snapped as a reminder) or scores very low (blurred, accidental shots). Screenshots and videos excluded (they have their own albums). |
| R-21 | **From WhatsApp:** the "WhatsApp" album that WhatsApp creates when "Save to Camera Roll" is on. Received and forwarded photos are both in it; WhatsApp does not mark which were forwarded. Row hidden if the album does not exist. |
| R-22 | The clean-up scan runs on the iPhone (Apple Vision), only while the app is open, from local thumbnails (no iCloud downloads). Rows show progress ("Checking 1,240 of 4,812") and fill in as results arrive. Pauses in Low Power Mode or when the phone is hot. |

## Non-goals
Adding any of these needs a new dated row in the decision log first.

- A "Later" or "Skip" choice; saved progress; remembering kept photos.
- Whole-library storage totals ("you could free 8 GB"). The clean-up scan
  finds photos; it does not report storage. *(Duplicate detection was a
  non-goal until D-18.)*
- Automatic deletion or "select all and delete" from a filter: every photo
  is still swiped.
- Telling forwarded WhatsApp photos from received ones (not possible).
- Filters beyond the three in R-18 (blurry-only, people, places, large
  videos…) unless a new decision adds them.
- Statistics or history beyond the Done screen and the single "cleared so far" total in Settings (D-26): no charts, per-album history or streaks.
- Video compression, editing, sharing, cloud backup.
- Accounts, sign-in, sync, analytics, ads.
- Subscriptions.
- Settings beyond the rows in R-14 (no notifications, haptics toggle, accounts or data export).

## Failure paths

| Situation | Behaviour |
|---|---|
| App killed or backgrounded mid-album | Marks are lost; nothing is deleted. Reopening starts the album from item 1 (owner decision, see D-02). |
| User cancels the iOS delete prompt | Stay on Review; marks and daily count unchanged. |
| Delete fails | Non-blocking message, stay on Review, daily count unchanged. |
| Double tap on Delete | The button locks after the first tap until the prompt resolves. |
| Item deleted elsewhere mid-swipe | Skipped silently; dropped from marks before delete. |
| iCloud-only photo, offline | "Not downloaded" placeholder; Keep and Delete still work. |
| Permission revoked while open | Return to Welcome with "Open Settings". |
| Purchase failed / cancelled / pending / restricted | Plain message on the paywall; "Delete 50 now" still works. |
| Daily count | Increases only after iOS confirms the deletion. Resets at local midnight. |
| App closed mid-scan | Scan stops; what was already analysed is kept (D-21) and the scan continues from there next time. |
| Photo only in iCloud, no local thumbnail | Skipped by the scan; still reachable in its normal album. |
| Filter wrongly includes a good photo | The user swipes right (Keep). Nothing is deleted without a swipe and the Review screen. |
| Every copy in a duplicate set is marked | Review shows "All copies of 2 sets are marked" so the user can keep one. |
| No duplicates / no matches found | Row says "None found" and is not a button. |

## Owner questions still open
- URL for privacy, terms and support pages (support email is settled: support@vericodestudio.com, MASTER Change 34). Confirm the 13+ audience and India governing law.
- Apple team ID for `project.yml`.

## Decision log

| # | Date | Decision | Status |
|---|---|---|---|
| D-01 | 2026-11-18 | Only two choices: swipe left deletes, swipe right keeps. No "Later". | Active |
| D-02 | 2026-11-18 | No sessions or memory: every album starts from the beginning each time. Overrides the standing rule "resume after the app is killed" for this app. | Active |
| D-03 | 2026-11-18 | Keep the app very simple; no extra features. | Active |
| D-04 | 2026-11-18 | Swipe screen is a side-by-side carousel (previous peek left, next peek right). | Active |
| D-05 | 2026-11-18 | Visual direction: neumorphism + glassmorphism (grey, LEDs). | Superseded by D-06 |
| D-06 | 2026-11-18 | Visual direction "Dusk": slate, blurred photo backdrop, serif titles, pastel accents. | Active |
| D-07 | 2026-11-18 | Strong glassmorphism on every screen; glass always over colour. | Active |
| D-08 | 2026-11-18 | "Storage-size estimates" were a non-goal. | Superseded by D-09 |
| D-09 | 2026-11-18 | Done screen shows the size cleared by this delete, with an achievement animation. | Active |
| D-10 | 2026-11-18 | Money: free download + one-time Pro. | Active |
| D-11 | 2026-11-18 | Free limit: 50 deletions per day. Pro: unlimited. | Active |
| D-12 | 2026-11-18 | Pro price: $4.99 one-time. | Active |
| D-13 | 2026-11-18 | Name "Swipe & Delete"; bundle ID `com.vericodestudio.swipeanddelete` (widget `.widgets`, tests `.tests`, IAP `.pro`). | Superseded by D-17 |
| D-14 | 2026-11-18 | Keep pill-shaped (capsule) main buttons. Exception to the standing rule "buttons are rounded rectangles". | Active |
| D-15 | 2026-11-18 | Add a light look alongside Dusk, following the system appearance. | Active |
| D-16 | 2026-11-18 | Add an About sheet for Restore, Rate, Privacy and Acknowledgements (required by the standing rules once Pro exists). Not a Settings screen. Owner confirmed. | Superseded by D-24 |
| D-17 | 2026-11-18 | App name **Lighter**; App Store title "Lighter: Swipe Photo Cleaner". Reason: at least 6 App Store apps already use "Swipe & Delete", one exactly "Swipe & Delete - Photo Cleaner". Bundle ID `com.vericodestudio.lighter` confirmed by the owner (not yet registered). | Active |
| D-18 | 2026-11-18 | Add **Quick clean-up** filters: Duplicates, Pages & Things (no people: pages, notes, documents, accidental shots), From WhatsApp. They open the same swipe flow. Reverses the non-goal "duplicate or similar-photo detection". | Active |
| D-19 | 2026-11-18 | The filters are free for everyone on the whole library. Pro still only removes the 50-a-day deletion limit. | Active |
| D-20 | 2026-11-18 | Minimum **iOS 18** (was 17): needed for Apple Vision's photo-quality check (`isUtility`, aesthetics score) behind Pages & Things. | Active |
| D-21 | 2026-11-18 | The scan's results (per-photo labels and image fingerprints, not swipe progress) are kept on the iPhone so the scan does not repeat on every launch. D-02 still holds: swiping always starts from item 1. Owner confirmed ("Keep d21"). | Active |
| D-22 | 2026-11-18 | After **Delete N now** on the paywall, the marks beyond N are dropped, not kept for the next day (keeps D-02: nothing is remembered). | Active |
| D-23 | 2026-11-18 | Confirmed: switching album with marks asks "Discard 9 marks?" first (R-06). | Active |
| D-24 | 2026-11-19 | Owner asked for a proper Settings page. It replaces the About sheet (gear button on Albums) and holds Pro and Restore, Appearance, "cleared so far", and legal and support links. Photo-access status was offered and not chosen. | Active |
| D-25 | 2026-11-19 | Appearance setting: System (default), Light or Dark. Stored on the device (`settings.appearance`). Changes R-15. | Active |
| D-26 | 2026-11-19 | Settings shows the total space and number of photos cleared since install, to motivate. Counted only after iOS confirms a delete; stored on the device (`stats.bytes`, `stats.deleted`). Narrows the non-goal on statistics. D-02 still holds: swipe progress is never remembered. | Active |
| D-27 | 2026-11-19 | Owner asked to remove Acknowledgements. The row and text are gone from the app. The font's licence file (`App/Resources/Fonts/OFL.txt`) stays in the bundle. Open owner question: the OFL asks that its copyright notice and licence travel with the font; confirm this is enough. | Active |
