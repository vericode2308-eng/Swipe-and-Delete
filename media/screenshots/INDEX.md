# Screenshots

Current UI of every screen, in both looks, for App Store images.
Rules: `CLAUDE.md` §8.2–8.3. Replace a file (and its row) whenever its screen
changes; never keep outdated shots.

Naming: `<NN>-<screen>-<state>-<light|dark>.png`

| NN | Screen |
|---|---|
| 01 | welcome |
| 02 | albums |
| 03 | swipe |
| 04 | review |
| 05 | paywall |
| 06 | done |
| 07 | settings |

| File | Build / commit | Date | Device |
|---|---|---|---|
| 01-welcome-undetermined-dark.png | Stage 3 (Welcome, undetermined) | 2026-11-18 | iPhone 18 Pro simulator |
| 01-welcome-undetermined-light.png | Stage 3 (Welcome, undetermined) | 2026-11-18 | iPhone 18 Pro simulator |
| 01-welcome-denied-dark.png | Stage 3 (Welcome, denied) | 2026-11-18 | iPhone 18 Pro simulator |
| 01-welcome-denied-light.png | Stage 3 (Welcome, denied) | 2026-11-18 | iPhone 18 Pro simulator |
| 02-albums-dark.png | Albums, no filter chips, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 02-albums-light.png | Albums, no filter chips, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 03-swipe-dark.png | Swipe: Cover Flow ring, dots, bar, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 03-swipe-light.png | Swipe: Cover Flow ring, dots, bar, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 03-select-grid-light.png | Multi-select grid, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 04-review-ios-prompt-dark.png | Stage 6 (Review with the real iOS delete prompt) | 2026-11-18 | iPhone 18 Pro simulator |
| 05-albums-quick-cleanup-dark.png | Albums with Quick clean-up panel, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 07-settings-dark.png | Settings, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 07-settings-light.png | Settings, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 09-albums-ax5.png | Albums at AX5 Dynamic Type, dark, Change 37 build (881bddc + chip removal) | 2026-11-19 | iPhone 17 simulator (1206x2622) |
| 08-video-fullscreen-playing.png | Stage 8: full-screen video playing (not re-checked against current build) | 2026-11-18 | iPhone 18 Pro simulator |

Still to recapture: swipe end card, video card (removed as outdated; need a Done state and a video in the simulator library). Note: the photos in the simulator library include earlier app screenshots, so the card inside the ring shows a nested app screen.
