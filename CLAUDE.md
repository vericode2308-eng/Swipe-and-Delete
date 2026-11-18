# Standing rules for building a new iPhone app (distilled from COLREGs Trainer)

Paste this into the new app's plan or its CLAUDE.md. Fill in the `<…>` placeholders once. Every rule below exists because it was decided, or because something went wrong without it.

---

## 0. How to work with me (owner)

1. **Plan first, build second.** Before code, produce and get approval for: `APP_PLAN.md` (scope, requirement IDs, non-goals, decision log), `DESIGN_BRIEF.md` (every screen, component, state, colour and accessibility rule), `BUILD_PLAN.md` (architecture, stages, test plan, risks), `ASO_PLAN.md` (store listing, pricing, review prompts). If documents disagree, `APP_PLAN.md` wins on scope.
2. **Keep the app simple.** My priority is "clean, easy and fun to use", not many features. Every feature needs a user need tied to the core loop. Anything else goes in a **non-goals** list and needs a new, dated decision-log entry before any code.
3. **Ask before deciding product questions** (scope, pricing, naming, bundle ID, account model, visual direction). Do not decide them silently. Cheap technical choices: pick a default, say so, continue.
4. **Record every owner decision** with its date in the `APP_PLAN.md` decision log. When a later decision overrides an earlier one, mark the old row "superseded" instead of deleting it, and update every doc that still states the old rule (I once had stale non-goal lists after features shipped).
5. **Be honest about verification.** Every change report has two lists: **Verified** (and how: unit tests, simulator, physical device) and **Not verified**. Never say "fixed" from a build alone. Never say "works on device" if you only ran the simulator. Never claim a bug is fixed from a fresh install alone.
6. **No unrequested work.** Do not create extra files, settings screens or features I did not ask for. If you notice something out of scope, report it; do not build it.
7. **One master record, from day one.** `MASTER.md` is the project's memory. It gets a numbered "Change N" for every change: what, why, files, how verified, what is not verified. It also keeps the full history since day one: every owner decision and correction, every mistake we made together and how it was fixed, and the lesson learned ("Mistakes and corrections" table). Never delete history; add to it. Update it in the same commit as the change. New lessons that apply to future apps are also added to section 11 of this file.
8. **Concurrent sessions:** other Claude/Codex sessions may edit the same folder. Before editing a file that already shows as modified in `git status`, or "fixing" an unexpected change, check `git log -p` for that file and ask me. Commit small and often.
9. **Model routing:** the model I pick does all substantive work. Haiku only for read-only search/lookup subagents. Never pass a model override to other subagents.

## 1. Git and repository hygiene

1. Commit **and push** automatically after each **major** change (a stage, feature, design update or document restructure) with a clear message; not for small edits. Do not wait for the owner to ask. Push to the session's working branch. End commit messages with the attribution line the session's system reminder gives (it changes between sessions; do not hard-code it).
2. `.gitignore` excludes everything that is not the code base: build output, generated Xcode project, generated media (PNG/PDF) except `media/screenshots/`, which is tracked because it is the source for App Store images, downloaded tools, local config, secrets.
3. Never edit the upstream/source repo I told you is read-only. Generate from it with a script instead.
4. Never hand-copy data that a script can export; keep the export script in the repo.
5. After changing code, run `graphify update .` (if the project uses graphify) and use `graphify query` before grepping.

## 2. Project setup

1. Native **SwiftUI**, iOS <min version>, Swift 6 strict concurrency, portrait unless stated.
2. **XcodeGen**: `project.yml` is the source of truth; the `.xcodeproj` is git-ignored; run `xcodegen generate` after any `project.yml` change or fresh checkout.
3. Architecture: one app target + local Swift packages (`<App>Core` pure logic with host tests, `<App>UI` design system, `<App>Features` screens). Core stays free of UI so `swift test` runs fast without a simulator.
4. **Bundle ID is permanent once registered.** Confirm it with me first. My prefix: `com.vericodestudio.<app>`; widget `.widgets`, tests `.tests`, IAP `.pro`. (COLREGs Trainer was first set up under the wrong prefix and had to be changed.)
5. Use my Apple team ID with automatic signing. Put `DEVELOPMENT_TEAM` in `project.yml`; do not rely on a command-line override.
6. App name: **search the App Store for the same or similar names before proposing one** (Swipe & Delete was approved, then found on six existing apps). Decide the **user-searched term** first (for COLREGs it was the acronym people search, not the web brand). Never revert a name I approved.
7. Privacy manifest, `ITSAppUsesNonExemptEncryption=NO`, correct `UIRequiresFullScreen` setting (see section 7), placeholder icon from day one.
8. **Secrets:** only a publishable/anon key may ship in the app, via a git-ignored xcconfig with a committed `.example` template. The app must still build and run without it. Service/secret keys live only in server-side functions, never in the repo, never in git history.

## 3. Product and content rules

1. Define the **core function in one sentence**, the **core loop**, and a **time-to-value** target (first meaningful action in ≤ 2 taps) before any screen is designed.
2. The reward is real value (understanding), not decoration. Celebrations are brief markers only.
3. Progress and "mastered" claims update **only after the data is saved**. If a save fails, show a non-blocking message, keep the user's flow going, and do not update progress.
4. Design the failure paths up front: app killed mid-task (resume), double tap (lock after the first), save failure, no network, silent mode / audio interrupted, purchase failed / cancelled / pending / restricted. Free content must stay usable in every one of them.
5. **Offline-first.** Bundle a full offline copy of content. Online updates, if any, must **fail closed**: a corrupt, truncated, older or wrong-schema download is rejected and never replaces the working copy. Test it.
6. Content comes from one source of truth (database or export script), validated on load with tests that run against the real exported file.
7. Do not copy competitors' text or diagrams. Draw diagrams in code (Canvas/Shape), never bitmap clip-art.
8. Never put an **unbuilt feature in the UI** (no disabled "Planned" chips, no "coming soon" sheets). A "coming soon" screen was replaced with the real feature; a disabled selector had to be removed later.
9. Persist with SwiftData/appropriate store. Never rename a stored key or enum raw value without a migration. If a rename would reset users' saved state, rename only the user-visible text and keep the key (we did this for "Practise" → "Practice").
10. Use item-based `.navigationDestination(item:)`; the path-array form pushed a blank screen on resume.
11. A live `@Query` view does not see a batch `modelContext.delete(model:)`. Delete fetched objects individually so the UI clears at once.
12. Deep links and widget URLs must never destroy unsaved work (for example, ignore a quick-start link while an exam is open). Treat every URL scheme input as untrusted.

## 4. Monetisation rules

1. Decide the model with me before building. Preferred: free download + one-time Pro unlock, StoreKit 2, no subscription unless I ask.
2. The free tier must be **genuinely useful** (App Store guideline 3.1.1: not a locked shell). Core reference content stays free.
3. Gate with a data flag + one `AccessPolicy` object, not scattered `if pro` checks. Entitlement is `.free` everywhere until the purchase flow exists.
4. Never show the paywall on launch. Conversion points only where the user hits a real limit. Locked items say what Pro adds, with **real counts** from the data. Locked cards must open the paywall, not be dead taps.
5. **Honest terms** on the paywall: price, what is included, one-time vs recurring, Restore Purchases, plain wording.
6. A real purchase must end any DEBUG entitlement override. The debug override must be compiled out of Release.
7. `Products.storekit` only applies when the app is launched from Xcode's scheme, not from `simctl`. Do not use a "price couldn't be loaded" screenshot for store assets.
8. Review prompt: only after a good result (≥ 70%) after ≥ 3 completed sessions on ≥ 2 days, shown after the user taps Done. Never during onboarding, mid-task, after an error or right after a purchase. No review gating ("do you like the app?"). Put a permanent "Rate on the App Store" row in Settings.

## 5. Accounts and privacy

1. Default: **no account**. If I ask for one, make it optional with a visible "Not now".
2. If there is any account: in-app account deletion is mandatory (guideline 5.1.1(v)); if Sign in with Apple exists, **revoke its tokens on deletion**; deletion runs in a server function that takes the user from the caller's token, never from the request body.
3. Never store passwords. Session in Keychain. Auth error text from the server is never shown to the user; map known codes to plain messages and use one fixed fallback ("Something went wrong. Try again.").
4. Pin third-party dependencies exactly, commit lockfiles (`Package.resolved`, `deno.lock`), and scan advisories before release.
5. Any third-party library the app links (for example Google Sign-In) must appear in Settings → About → Acknowledgements. Do not write "uses no third-party libraries" if it does.
6. The privacy policy, terms and support pages must **match the app's real behaviour**. Re-check them whenever accounts, analytics or data handling change. Fix the App Store privacy label at the same time.
7. Hosted backend (Supabase or similar): before release, check RLS and grants, storage buckets, secret exposure (repo, history, built `.app`), redirect allow-list, rate limits, leaked-password protection, and call the delete function once for real.

## 6. Design system rules

1. Read `DESIGN_BRIEF.md` before any UI work. Build tokens (colour, 4-pt spacing, radii, type) and components in `<App>UI` first, each with `#Preview`s in light, dark and AX3.
2. Design skills (`ui-ux-pro-max`, `write-swift`, `impeccable`) are inputs, not authority. **Verify their output against the brief.** A generated "design system" that was a web landing page (serif fonts, "avoid dark mode") was rejected outright. Reject web-only advice.
3. Semantic colours only; colour is never the only cue (icon + word + colour). Reserve special colour families (for example navigation-light colours) for the diagrams that need them.
4. Native iOS patterns first: system tab bar, navigation stack, sheets, system controls. Buttons are rounded rectangles; capsules only for chips.
5. Visual direction (glass, flat, etc.) is an owner decision. Once chosen, use the shared modifiers (`.glass`, `.appCanvas()`), never the old styles.
6. Copy: choose one spelling convention (British here) and apply it everywhere a user reads, but keep code identifiers and stored keys unchanged. Keep text consistent across the app, the store listing, widgets and the website.
7. Body text: justified only where it reads well; headings and short bullets left-aligned (we flip-flopped on this; decide once with me and write it in the brief).

## 7. Layout, accessibility and device checks (every screen, not at the end)

1. **Dynamic Type up to AX5.** At accessibility sizes: stack grids to one column, drop decorative icons, put titles on their own line, never break a word mid-word, never truncate text with `lineLimit` on content. System segmented controls do not scale; use a custom control that stacks at AX sizes.
2. Minimum tap target 44 pt. Large labels need padding so they do not touch the edges.
3. Hide the tab bar on immersive flows (question, exam, results) and scroll feedback into view after an answer (no animation under Reduce Motion). Do not compensate with ad-hoc bottom padding.
4. VoiceOver: announce answer feedback, mark section headers as headings, read scores as "4 of 5 correct", combine multi-part elements into one labelled element, give diagrams descriptions, give controls hints.
5. Dark mode: if the app has its own Appearance setting, the simulator's dark mode will not show; launch with the setting argument (`-settings.appearance dark`).
6. **iPhone Duo / large inner screens:** remove `UIRequiresFullScreen`, give fixed-height diagrams an aspect-ratio frame (1.6:1, max width) so labels do not overlap, keep content clear of the status strip, and check closed, half-open and open poses. Test the outer-screen onboarding headline.
7. iPhone SE layout, 5,000-attempt performance and a corrupt-store fallback are required hardening checks before release.
8. Run a dedicated UI/UX pass over every screen: text width, placeholders, alignment, spacing, empty/loading/error states. Fix flow bugs found, for example: the tab bar covering "Next", "End session" behaving like "Resume later", locked cards doing nothing, confetti clipped to a strip because it was attached to a scroll content instead of the whole screen.
9. Animations: few and calm, off or reduced under Reduce Motion, never on high-frequency actions.

## 8. Simulator and device testing

1. Drive the simulator with the **agent-device MCP** (session `<app>`, a fixed device name), not raw `simctl` taps. Boot the right device, install the fresh build, wait for the screen to settle, verify, then capture.
2. **Save every simulator screenshot** in `media/screenshots/`, never in temp folders. Name them `<NN>-<screen>-<state>-<light|dark>.png` (for example `03-swipe-dragging-left-dark.png`) so the folder reads in app order.
3. When the UI visibly changes, **delete the outdated screenshots and recapture** in the same commit. Never let stale ones accumulate; half the old shots were out of date after one reorder. The folder must always show the current UI of every screen, in both looks, ready for App Store images. `media/screenshots/INDEX.md` lists each file, the build/commit it came from and the date.
4. Check the build you launched is the build at HEAD (a stale `build/` folder caused a false "runner timed out"; delete it).
5. Android-style signing note carried over from my global rules: before installing a rebuilt app over an installed one, check signing; before uninstalling, say what data would be lost.
6. Physical device: automatic signing registers the bundle IDs on the first device build. `devicectl` install can fail once and succeed on retry. UI automation needs "Enable UI Automation" on the phone. Anything you cannot tap on the device goes in **Not verified** (purchase, audio, haptics, VoiceOver speech, widgets).
7. Use mock servers on `127.0.0.1` for auth/network flows; do not create real users or purchases without my explicit OK. Note that some backends reject `example.com` emails.
8. Tests: host tests for all logic (content validation, access policy, progress queries, auth client request shapes and error mapping); a small app-level test target for session models. Run before every commit that touches logic.

## 9. Security habits

1. Run a quick security audit after the core is built and again before release. Fix real findings and record them in the change log; keep the report outside the repo if it holds sensitive detail.
2. Re-audit when a feature adds downloads, accounts or network calls.
3. Never expose raw exception text in UI or local API routes.
4. Local dev tools (for example a screenshot editor) bind to `127.0.0.1` and reject non-loopback `Host` headers.
5. Do not send package names or user data to external services without asking; say plainly when an advisory scan was version-only.

## 10. App Store, ASO and release

1. Read `ASO_PLAN.md` before touching scope, metadata, screenshots, pricing, review prompts or release. Update it whenever a decision changes.
2. **Never advertise a feature until it is implemented and verified in the build.** Store text lives in `store_drafts/`, one plain-text file per field, with character counts. Rewrite the listing when the build changes (it was rewritten once to match the build).
3. Never claim "official", "approved by <authority>" or a "pass guarantee". Disclose any educational-only scope and the content source.
4. Guideline risks to design against: 4.2 (it must be a real native app), 4.3 (crowded category, needs a visibly different experience), 3.1.1 (free tier useful), 5.1.1(v) (account deletion).
5. Screenshots: native sizes, exact dimensions, RGB without alpha, non-blank, readable at thumbnail size, no fabricated reviews or endorsements, English-only unless I ask. Pro-only screens are captured with the debug entitlement argument and labelled as Pro in the creative. Never use a screenshot that shows a simulator error state.
6. Draft **App Review notes** early: where each feature is, how to restore the purchase, the optional account and its deletion path, offline use, widgets, no ads/tracking. Check every path and label against the source and re-tap them before submitting.
7. Legal pages (privacy, terms, support) published on a real URL, linked from Settings and from App Store Connect, and matching the app.
8. Support email, App Store ID, terms link, and the Pro product in App Store Connect (same product ID as the code) must exist before any real purchase test. Keep a list of these open owner questions and keep asking.
9. TestFlight: archive Release with `generic/platform=iOS`, export `app-store-connect` with an API key, raise `CURRENT_PROJECT_VERSION` for every upload, and keep `MARKETING_VERSION` in sync with App Store Connect. Keep build logs outside the repo. The upload is not "verified" until processing finishes and a tester installs it.
10. Release checklist before submission: tests green, Release build clean, DEBUG overrides compiled out, no secrets in the bundle, acknowledgements correct, privacy label correct, screenshots current, review notes current, physical-device pass done.

## 11. Things that went wrong before (do not repeat)

- Built a second, unsourced mechanic instead of reusing existing data. Keep one mechanic.
- A web-oriented design skill output was adopted without checking the brief.
- A unrequested set of Settings files appeared from another session. Check `git log` first.
- Product name reverted by a concurrent session. Protect approved names.
- Bundle ID prefix changed late. Confirm it on day one.
- Docs and non-goal lists went stale after features shipped. Update all docs with each decision.
- Screenshots, store text and legal pages drifted from the app. Re-check all three whenever the UI or data handling changes.
- A disabled, unbuilt control shipped in the UI. Remove it or build it.
- Acknowledgements claimed "no third-party libraries" after one was added.
- Simulator dark mode "didn't work" because the app had its own appearance setting.
- Paywall screenshot showed "price couldn't be loaded" because StoreKit config only applies from Xcode runs.
- Reporting items as done when only built, not run. Always split Verified / Not verified.
- Recommending an app name before searching the App Store for it.
- Relying on the owner to say "push". Push automatically after every major change.
- Docs kept old colour names and comments after a redesign ("LEDs", coral/teal/indigo). Search the docs for the old terms after every redesign.
- A small extra (a photo-size label) slipped into a mock-up against a written non-goal. Check the non-goals before adding any detail.
- Light-look colours were specified without a contrast check and three failed. Compute contrast for every new colour token before it goes in the brief.
