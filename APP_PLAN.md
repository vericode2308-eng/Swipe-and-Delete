# Swipe & Delete — App Plan

This document wins on scope. If another document disagrees with it, this one is
right and the other must be fixed.

Companion documents: `DESIGN_BRIEF.md` (screens and look), `BUILD_PLAN.md`
(architecture, stages, tests), `ASO_PLAN.md` (App Store), `MASTER.md`
(change log), `CLAUDE.md` (standing rules).
Design canvas: https://claude.ai/artifact/Jn3jbGXcMaqwmxhM4HLq5z

## Core
- **Core function:** clear out your iPhone photos by swiping: left deletes,
  right keeps.
- **Core loop:** pick album → swipe each photo left or right → review the
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
| R-06 | Album chips on the Swipe screen switch album and start from item 1. Switching discards current marks after a confirm if any exist. |
| R-07 | Review shows every marked item. Tapping one unmarks it. |
| R-08 | Delete runs one iOS delete prompt for all marked items. Cancel stays on Review with marks intact. |
| R-09 | Deleted items go to Recently Deleted (30 days); the app says so before and after deleting. |
| R-10 | Done screen: a short celebration with the total size cleared, counts (reviewed, kept, deleted) and "Room for about N more photos". |
| R-11 | Free plan: up to **50 deletions per calendar day** (device's local time). Swiping, keeping and reviewing are always unlimited. |
| R-12 | Pro: one-time purchase (**$4.99**, StoreKit 2, non-consumable) removes the daily limit. Restore Purchases is always available. |
| R-13 | Paywall appears only when the user taps Delete with more marked than today's allowance left. It offers **Unlock Pro** and **Delete 50 now** (the first 50 marked, in order). Never on launch. |
| R-14 | About sheet (from an ⓘ button on Albums): Pro status, Restore Purchases, Rate on the App Store, Privacy Policy, Acknowledgements. |
| R-15 | Light and dark looks that follow the iPhone's appearance setting. |
| R-16 | Full VoiceOver, Dynamic Type up to AX5, Reduce Motion and Reduce Transparency support. |
| R-17 | The app never uploads anything. No account, no server, no analytics. |

## Non-goals
Adding any of these needs a new dated row in the decision log first.

- A "Later" or "Skip" choice; saved progress; remembering kept photos.
- Duplicate or similar-photo detection; whole-library storage scans.
- Statistics or history beyond the Done screen of the current delete.
- Video compression, editing, sharing, cloud backup.
- Accounts, sign-in, sync, analytics, ads.
- Subscriptions.
- A Settings screen (the About sheet covers the required items).

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

## Owner questions still open
- Support email address and the URL for privacy, terms and support pages.
- Apple team ID for `project.yml`.
- Minimum iOS: 17 assumed (needed for `@Observable`, `PhaseAnimator`, `sensoryFeedback`).

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
| D-13 | 2026-11-18 | Name "Swipe & Delete"; bundle ID `com.vericodestudio.swipeanddelete` (widget `.widgets`, tests `.tests`, IAP `.pro`). | Active |
| D-14 | 2026-11-18 | Keep pill-shaped (capsule) main buttons. Exception to the standing rule "buttons are rounded rectangles". | Active |
| D-15 | 2026-11-18 | Add a light look alongside Dusk, following the system appearance. | Active |
| D-16 | 2026-11-18 | Add an About sheet for Restore, Rate, Privacy and Acknowledgements (required by the standing rules once Pro exists). Not a Settings screen. | Active (proposed by Claude, confirm) |
