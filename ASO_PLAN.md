# Lighter — ASO Plan

Read this before touching metadata, screenshots, pricing, review prompts or
release. Never advertise a feature that is not built and verified.
Store text drafts live in `store_drafts/`, one file per field, with character counts.

## Name and search (researched 2026-11-18)

### Final draft fields (also in `store_drafts/`)
| Field | Limit | Draft | Length |
|---|---|---|---|
| App name | 30 | `Lighter: Swipe Photo Cleaner` | 28 |
| Subtitle | 30 | `Delete Pics & Free Up Storage` | 29 |
| Keywords | 100 | `camera,roll,gallery,album,screenshot,declutter,tidy,remove,space,organize,sort,video,clear,memory` | 97 |
| Home-screen name | ~12 | `Lighter` | 7 |

Why this split:
- The **title** carries the heaviest-weighted words: *swipe*, *photo*,
  *cleaner* → matches "photo cleaner", "swipe photo cleaner", "swipe photos".
  Search results usually cut titles at about 26 characters, so the key words
  sit early; "Lighter: Swipe Photo Clean…" still reads.
- The **subtitle** adds *delete*, *pics*, *free up*, *storage*.
- The **keyword field** adds words not already in the title or subtitle
  (repeating words gives no extra ranking), with no spaces after commas, no
  competitor names and no features we do not have (no "duplicates", no "AI").
  **Once Duplicates (D-18) is built and verified**, swap a weak word (likely
  "memory") for "duplicate"; until then the draft stays as it is (rule 10.2).
  Never put "WhatsApp" in the name, subtitle or keywords (trademark).
  Apple combines words across fields, so "camera" + "roll" covers "camera
  roll", "clean" + "up" via subtitle + title covers "clean up photos".
- en-US spelling ("organize") in the US keyword field. A later en-GB
  localisation can add "organise", "photos", "snaps" as extra keywords.

### Name research
- **"Swipe & Delete" is crowded.** At least six App Store apps use it:
  "Swipe & Delete - Photo Cleaner" (Bigrowth), "Swipe & Delete Photos",
  "Swipe & Delete Photo Declutter" (swipedelete.app), "Photo Swipe : Swipe &
  Delete", "Photos Cleaner: Swipe & Delete", "Photo Purge: Swipe & Delete".
  The first is identical to our earlier draft title, so it was dropped (D-17).
- **Ruled out:** Dusk (an existing Photo & Video camera app), Afterglow
  ("Afterglow: Photo Tidy" exists), Pare ("Pare Down" is a swipe photo
  editor), Sift (Siftly, PicSift, SiftZen, SwipeSift), Keepsake (too close
  to the well-known Keepsafe photo vault).
- **Lighter:** no photo app found with this name. It matches the calm look
  and the Done screen ("Screenshots is 1.2 GB lighter").
- The category is very crowded with "Swipe…/Photo Cleaner…" names, so a
  real brand word helps recall and helps with guideline 4.3 (not a copy).

### Before submitting (owner, on the Mac)
- Check exact availability by reserving the name in App Store Connect (the
  real test; a web search can miss apps).
- Check keyword popularity in Apple Search Ads (Keyword Planner shows a
  popularity score), and swap low-scoring keyword-field words.
- Quick trademark search for "Lighter" in class 9 (software) in the main
  markets (USPTO, UKIPO/EUIPO).

### Sources
- Competitor listings: apps.apple.com/us/app/swipe-delete-photo-cleaner/id6508167708,
  apps.apple.com/us/app/swipe-delete-photos/id6753584228,
  apps.apple.com/us/app/swipe-delete-photo-declutter/id6477321134,
  apps.apple.com/us/app/photo-swipe-swipe-delete/id6742195794,
  apps.apple.com/us/app/photos-cleaner-swipe-delete/id6742649462,
  apps.apple.com/us/app/photo-purge-swipe-delete/id6468278116,
  apps.apple.com/us/app/dusk/id6762052388,
  apps.apple.com/app/id914281628 (Pare Down).
- Field limits and practice: apptweak.com/en/aso-blog/app-name-guidelines-and-best-practices,
  apptamin.com/blog/app-store-optimization-aso-app-name-and-keywords/,
  gummicube.com/blog/app-store-keyword-rules-to-remember.

## Positioning
- One gesture: left deletes, right keeps. Nothing to learn.
- Calm, beautiful glass design instead of alarm-style "your phone is full"
  cleaners.
- No subscription. Free with 50 deletions a day; Pro is a one-time $4.99.
- Private: photos never leave the iPhone; no account; no tracking.
- Quick clean-up (after it is verified): duplicates, pages and notes, and
  WhatsApp saves, found on the iPhone, each still swiped by the user.

## Pricing
- Free download; non-consumable `com.vericodestudio.lighter.pro` at
  the $4.99 tier (D-12).

## Screenshots (after the build is verified)
1. Swipe screen mid-drag — "Swipe left to delete. Right to keep."
2. Albums — "Start with any album."
3. Review — "Check before anything goes."
4. Done celebration — "See the space you cleared."
5. Paywall terms (labelled Pro) — "No subscription. One-time Pro."
6. Quick clean-up rows (after verification) — "Duplicates and notes, found
   for you."
Native sizes, RGB without alpha, captured from the real build, both looks
considered; no screenshot with a StoreKit "price unavailable" state.

## Review prompt
See `BUILD_PLAN.md` → ReviewPromptPolicy. A permanent "Rate on the App Store"
row lives in the About sheet.

## Claims never to make
"Official", "frees space instantly" (space returns after Recently Deleted
empties), fake reviews or endorsements, any feature from the non-goals list.

## Owner questions
- Support email; privacy, terms and support page URLs.
- App Store Connect record and the Pro product (same ID as the code).
