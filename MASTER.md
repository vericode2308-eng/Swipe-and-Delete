# Swipe & Delete — Master Change Log

Each change: what, why, files, how verified, what is not verified.

## Change 1 — Product spec
- **What:** simplified v1 spec (two choices, no memory, three screens).
- **Why:** owner asked for a very simple app (D-01–D-03).
- **Files:** `SPEC.md` (now folded into `APP_PLAN.md`).
- **Verified:** n/a (document). **Not verified:** n/a.

## Change 2 — UI, architecture and build plan; design canvas
- **What:** detailed plan, side-by-side carousel, then the Dusk look with
  strong glassmorphism; six interactive mock-ups and an architecture board.
- **Why:** owner's references (D-04–D-07).
- **Files:** `PLAN.md` (now split into `DESIGN_BRIEF.md` and
  `BUILD_PLAN.md`); canvas https://claude.ai/artifact/Jn3jbGXcMaqwmxhM4HLq5z
- **Verified:** canvas files published. **Not verified:** how the canvas
  renders was not checked by Claude.

## Change 3 — Done screen celebration
- **What:** photos drift into a glass ring, freed size counts up, check pop,
  sparkles, haptic; stats and "room for about N photos".
- **Why:** owner asked for a sense of achievement (D-09).
- **Files:** canvas `Done.dc.html`; plan docs.
- **Verified:** published (version 27). **Not verified:** animation timing
  not watched by Claude.

## Change 4 — Standing rules adopted; documents restructured
- **What:** brought `CLAUDE.md` onto this branch; replaced `SPEC.md` and
  `PLAN.md` with `APP_PLAN.md`, `DESIGN_BRIEF.md`, `BUILD_PLAN.md`,
  `ASO_PLAN.md` and this log. Added owner decisions D-10–D-15 (free + one-time
  Pro at $4.99, 50 deletions a day, name and bundle ID, keep pills, add a
  light look) and proposed D-16 (About sheet). Added the paywall and About
  screens, the light "Dawn" tokens, XcodeGen + packages architecture, Swift 6,
  StoreKit 2 and the review-prompt policy.
- **Why:** owner's standing rules (§0.1, §0.4, §0.7) and answers on
  2026-11-18.
- **Files:** `APP_PLAN.md`, `DESIGN_BRIEF.md`, `BUILD_PLAN.md`,
  `ASO_PLAN.md`, `MASTER.md`, `CLAUDE.md`; removed `SPEC.md`, `PLAN.md`.
- **Verified:** documents cross-checked for the old non-goal about storage
  sizes and old colour names. **Not verified:** the canvas does not yet show
  the light look, the paywall or the About sheet.
