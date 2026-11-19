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
| 07 | about |

| File | Build / commit | Date | Device |
|---|---|---|---|
| 01-welcome-undetermined-dark.png / -light.png | Change 42 build (721f8ba + uncommitted Swipe work) | 2026-11-19 | iPhone 17 simulator |
| 01-welcome-denied-dark.png / -light.png | same | 2026-11-19 | iPhone 17 simulator |
| 02-albums-dark.png / -light.png | same; the Quick clean-up panel is part of this screen ("None found" for 16 photos) | 2026-11-19 | iPhone 17 simulator |
| 02-about-dark.png / -light.png | same; About sheet with Photo Access, Contact Support, Privacy, Terms | 2026-11-19 | iPhone 17 simulator |
| 03-swipe-dark.png / -light.png | same; ring carousel, dot pill, Select, Review chip | 2026-11-19 | iPhone 17 simulator |
| 04-review-dark.png | same; Review with 1 photo marked | 2026-11-19 | iPhone 17 simulator |
| 04-review-ios-prompt-dark.png | same; the real iOS delete prompt (answered "Don't Allow", nothing deleted) | 2026-11-19 | iPhone 17 simulator |
| 09-albums-ax5.png | same; Albums at accessibility-extra-extra-extra-large | 2026-11-19 | iPhone 17 simulator |
| 10-privacy-policy-dark.png | same; Privacy Policy read in the app (top) | 2026-11-19 | iPhone 17 simulator |
| 11-terms-of-use-dark.png | same; Terms of Use read in the app (top) | 2026-11-19 | iPhone 17 simulator |

## Not recaptured (may be out of date; recapture before App Store use)
- 03-swipe-end-dark.png (end card, 2026-11-18)
- 07-swipe-video-card.png, 08-video-fullscreen-playing.png (video, 2026-11-18)
- Missing: paywall, Done screen, light looks of Review, Privacy and Terms.

## Notes
- The simulator library holds earlier screenshots of the app, so some swipe cards show a picture of the app. Use a clean library of real photos for the App Store images.
- The swipe shots include the uncommitted ring-carousel work from another session; its card edges are clipped at the top and bottom.
- `simctl io screenshot` cannot overwrite some existing files ("Operation not permitted"); write to a temp file and copy.
