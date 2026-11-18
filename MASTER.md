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

## Owner decisions
See the decision log in `APP_PLAN.md` (D-01 onwards).
