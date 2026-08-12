# Cờ Cá Ngựa — Vietnamese Horse Race Board Game

Native SwiftUI iOS app for Cờ Cá Ngựa, the traditional Vietnamese 4-player race/dice
board game (the Vietnamese member of the Ludo/Pachisi family). Bundle
`com.quyenngo.cocangua`. Built 2026-07-31 as one app in a 5-app Vietnamese-games
lineup, following the house pattern from `Fanorona` (XcodeGen shape, PurchaseManager) and
`SamLoc` (Localization, tooling scripts, UpgradeView style). Structurally this app is
neither Fanorona's 1v1 board game nor SamLoc's 4-AI card game — it's a 4-player token
race, so the Core/ layer (Board/Token/Player/GameModel/AIEngine) is new, purpose-built
for this ruleset.

**Status: 🟡 READY FOR RESUBMISSION AFTER 2026-08-18, pending Apple's Guideline 5.6 hold.**
This app was one of 19 apps hit by an account-level "Developer Code of Conduct — Review
Suspended" flag (near-certainly triggered by submitting ~19 similar template-style apps
within an 8-day window, 2026-08-01 through 2026-08-08), not a per-app rejection.
Resubmission is hard-blocked until 2026-08-18. App id `6796833591`. The version originally
submitted 2026-08-01 was `1.0.0` (id `f0f6f1a1-2e0f-4722-b367-725743a76193`), build
`6410ad7b-b1f0-4bd3-bec4-ca254a9d5253`, reviewSubmission `be8d1659-eeed-4eb7-9a93-f103c398ce3c`,
release type automatic (`AFTER_APPROVAL`) — that reviewSubmission/build predate the pass
below and will need a fresh build attached at resubmission time (out of scope here, no ASC
calls were made in this pass). **Local marketing version is now `1.0.1` / build `2`** (bumped
2026-08-09, see review pass below) — bump again if further local changes land before the
window reopens.

## Pre-resubmission quality review (2026-08-09)

Full local-only review pass (no ASC calls, no App Store Connect changes — see hard
constraint above). Verdict: **this app was already in genuinely good shape**, unlike the
generic "low-differentiation template" framing of the 19-app wave — real bilingual
localization, real onboarding, a correct and complete ruleset implementation, no
placeholder/TODO/debug text anywhere in the codebase. This was the least-broken app in
the wave reviewed so far.

- **Build**: `xcodegen generate` + `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
  — clean, zero errors, zero warnings (verified with a `grep -i "warning:|error:"` over
  full build output, not just skimming).
- **Game logic**: walked `Core/Board.swift`, `Token.swift`, `Player.swift`,
  `GameModel.swift`, `AIEngine.swift` line by line against the documented house ruleset
  above — path model (0/1-51/52-57), leave-yard-on-6, exact-landing-to-finish,
  capture/safe-cell resolution, 3-consecutive-6s forfeit, win detection — every rule
  matches the spec exactly, no stubs, no shortcuts. Verified live on-device via the
  `CN_CAPTURE=midgame` and `CN_CAPTURE=nearwin` debug harness: board renders correctly
  (52-cell ring, 4 home-stretch diagonals converging on the center flag, yards, safe-cell
  stars), and the near-win capture confirmed the exact-landing legal-move logic + move-chip
  UI both work.
- **Placeholder/debug-text sweep**: `grep -rnE "TODO|FIXME|placeholder|Lorem ipsum|dummy|XXX"`
  across all Swift sources — zero hits. All `#if DEBUG` blocks (CN_CAPTURE/CN_LANG/
  CN_SKIP_ONBOARDING) are correctly compiled out of Release.
- **DEBUG isPro double-gating check** (recurring bug pattern in this developer's other
  apps): `PurchaseManager.isPro` is a single `@Published` source of truth, read the same
  way everywhere it's used (`HomeView`, `UpgradeView`). The `#if DEBUG`/`#else` split only
  changes *how* `isPro` is computed (unconditionally true except during
  `CN_CAPTURE=upgrade` screenshot capture, vs. real `Transaction.currentEntitlements` in
  Release) — there's no second cached flag anywhere that could desync from it. Not a bug
  here.
- **IAP wiring**: `PurchaseManager.swift` — StoreKit 2, verified + unverified
  transactions both grant `isPro` (documented rationale: don't silently drop legitimate
  purchases on JWS edge cases), transactions always finished, restore path present,
  10s timeout on product load. Looks correct; untested against a live sandbox account
  (no ASC/sandbox access in this pass per the hard constraint).
- **Onboarding**: real 3-page first-launch walkthrough (`OnboardingView`, shown once via
  `hasSeenOnboarding` AppStorage, re-accessible from Home's "How to Play" and from the
  in-game toolbar "?" button) plus a separate 7-section `RulesView` reference sheet.
  Confirmed present and wired correctly, not just referenced in CLAUDE.md.
- **Localization**: `en.lproj`/`vi.lproj` both 85 lines, **exact key parity** (diffed the
  sorted key sets — zero missing/extra keys either direction), every `L("...")` call and
  every dynamic key (`color.nameKey`, `difficulty.titleKey`, rules/onboarding tuple keys)
  resolves to a defined string. Vietnamese text read for quality: natural, correctly
  accented, no mojibake, no machine-translation tells.
- **Fix applied — haptic feedback (genuine differentiation, small scope)**: the app had
  *zero* haptics anywhere, unusual for a dice/board game. Added `Core/Haptics.swift`
  (cached `UIImpactFeedbackGenerator`/`UINotificationFeedbackGenerator` instances per
  Apple's latency guidance) and wired it into `GameView`: a light tap on every human die
  roll, a rigid tap on any capture (either side), and a success notification on reaching
  the goal / winning the match. Purely additive — no game-logic or gating changes.
- **Version bump**: `MARKETING_VERSION` `1.0.0` → `1.0.1`, `CURRENT_PROJECT_VERSION`
  `1` → `2`, in `project.yml` (both the base and target-level settings blocks — Xcode's
  `GENERATE_INFOPLIST_FILE` injects these from build settings at build time, not from
  the checked-in `Info.plist`, which xcodegen regenerates from `project.yml` on every
  `xcodegen generate` and will keep showing a stale placeholder `1.0`/`1` — confirmed via
  `PlistBuddy` against the actual built app bundle that `1.0.1`/`2` is what ships;
  the stale placeholder in the source `Info.plist` is cosmetic and harmless).

### What's still open

- No changes were made to App Store Connect (blocked by the 5.6 hold and by this task's
  explicit hard constraint) — a fresh archive/build still needs to be created and
  attached to a new reviewSubmission once 2026-08-18 passes, following the Deploy
  pattern below.
- IAP purchase/restore flow is code-reviewed but not sandbox-tested in this pass.
- No functional/logic bugs were found to fix — the only code change this pass is the new
  haptics feature; everything else was verification that confirmed the app was already
  correct.

## Polish pass (2026-08-12)

Part of the pre-2026-08-18 resubmission polish sweep across all 18 apps in the 5.6 wave
(user asked to check bugs, onboarding, UI professionalism, and ASO/SEO copy for each).

- **UI fix**: `GameView` was top-hugging its content, leaving a large dead black gap
  below the Quit button on tall screens (visible in the marketing screenshots — the
  board itself is width-bound at 1:1 aspect so it can't grow taller, but the surrounding
  whitespace was unbalanced). Added `Spacer(minLength: 0)` before `playerBadges` and
  after the Quit button so the content block centers vertically instead of sitting at
  the top with all the slack dumped below it. Bumped `VStack` spacing 10 → 16 for a bit
  more breathing room. Purely cosmetic, no logic touched.
- **Screenshots regenerated** (`capture_shots.py`) to reflect the layout fix — only
  `02-midgame.png` and `03-upgrade.png` changed (the only screens GameView affects;
  01-home/04-rules are OnboardingView/RulesView, untouched). Pushed to ASC via
  `asc_push_cocangua_screenshots.py`.
- **ASO keywords refreshed** in `asc_push_cocangua.py` and pushed live: dropped terms
  already covered by the indexed name/subtitle (e.g. "vietnamese ludo", "race game",
  "cờ việt nam", "đua ngựa") and added higher-value non-redundant search terms —
  `pachisi`/`parcheesi` (global Ludo-family search terms this app wasn't targeting) and
  `multiplayer`/`board` (en), `cá ngựa`/`pachisi`/`board game` (vi). Description and
  promotional text were already strong from the original submission — left unchanged.
  Pushed via `asc_push_cocangua.py` (App Info + version localizations updated
  successfully; the IAP localization PATCH 409'd with `IAP_VERSION_UNMODIFIABLE` —
  pre-existing, the IAP is locked while attached to the rejected version; not something
  this pass needed to touch, name/price were already correct).
- Onboarding, localization, and IAP-gating logic were re-checked against the 2026-08-09
  review findings above — still solid, no regressions.
- Version bump: `MARKETING_VERSION` 1.0.1 → 1.0.2, `CURRENT_PROJECT_VERSION` 2 → 3.

## Build staged for resubmission (2026-08-13)

Archived, exported, and uploaded a Release build ahead of the staggered resubmission — still
blocked until 2026-08-18 by the Guideline 5.6 account-level hold, this app resubmits
**2026-08-18 (solo test)** (batch 1). Build **1.0.2 (3)** uploaded via
`xcrun altool --upload-app` (Delivery UUID `adc79fb3-0592-4875-95ab-91c5b675fd06`), processed to `VALID` by Apple, and
attached to the existing `REJECTED` appStoreVersion (id `f0f6f1a1-2e0f-4722-b367-725743a76193`) via a direct
`PATCH appStoreVersions/{id}/relationships/build` API call — independently re-verified via a
follow-up `GET` on the same relationship, not just trusted from the PATCH's 204 response.

**Deliberately NOT done yet** — waiting for the user's explicit go-ahead on this app's
scheduled date, per the staggered resubmission plan:
1. Tick the Pro IAP into this version in the App Store Connect **web UI** — the API has no
   way to do this; it must be done from the version's own page (not the IAP's own page, which
   creates an orphaned draft submission — a mistake this portfolio hit once before).
2. Submit for review.

## Deploy / resubmit pattern

No Xcode account/Distribution cert on this machine — pass the ASC API key explicitly to
xcodebuild (see [[feedback_asc_release_and_signing]]):
```
xcodegen generate
xcodebuild -project CoCaNgua.xcodeproj -scheme CoCaNgua -configuration Release \
  -archivePath build/CoCaNgua.xcarchive -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016 \
  archive
xcodebuild -exportArchive -archivePath build/CoCaNgua.xcarchive -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016
xcrun altool --upload-app --type ios -f build/export/CoCaNgua.ipa \
  --apiKey G85WXB4AF5 --apiIssuer 2e969722-fc4d-444c-af74-7e0233efd016
```
Metadata scripts are idempotent — re-run after copy changes. No `asc_submit_cocangua.py`
exists; submission was done via one-off `reviewSubmissions` → `reviewSubmissionItems` →
`PATCH submitted=true` calls (copy the pattern from `asc_submit_woktonight.py` if
resubmitting).

## The ruleset — READ THIS BEFORE "FIXING" ANYTHING

This is a specific, deliberately-chosen, internally-consistent house ruleset, picked
instead of reconciling every regional Cờ Cá Ngựa / Ludo variant. **Do not "correct" it
against a different Ludo/Pachisi variant you might know** — several of these choices are
simplifications made on purpose for a quick single-sitting mobile session:

- **Players & tokens**: 4 players (you + 3 AI, or up to 4 local humans in Pass & Play),
  each with a colored home yard holding 4 tokens ("ngựa"/horses) and a fixed entry point
  onto a shared **52-cell outer track** (a square loop, 13 cells per side — 4 colors ×
  13 cells apart = 52). Each color also has its own **6-cell home stretch** (private
  lane from the outer track into that color's center goal).
- **Path model** (`Token.pathPosition`, see `Core/Board.swift`): 0 = in yard; 1...51 =
  on the shared track (51 = one full lap minus the entry cell itself); 52...57 = in the
  private home stretch; **57 = the goal cell**. A token must land on exactly 57 to
  finish — 51 (lap) + 6 (home stretch) = 57.
- **Turn structure**: roll one die. A token in the yard leaves (onto its color's entry
  cell) only on exactly 6. A token on the board moves forward by the roll; if that would
  overshoot the goal cell (57), that specific token simply has no legal move this turn
  (not "clamped to the goal" — genuinely unusable for that token, though other tokens may
  still have legal moves).
- **Rolling a 6**: after resolving that move, roll again immediately (extra turn).
  **Three 6s in a row forfeits the whole turn** — the third 6 doesn't move anything, turn
  passes to the next player. (A 6 that can't be used — e.g. all tokens in yard on a
  non-third 6 with no legal move — still earns the extra roll, matching how real Ludo
  plays; this isn't explicitly required by the spec but isn't contradicted by it either.)
- **No legal move at all**: turn passes with no move (e.g. all tokens in yard and roll≠6,
  or every on-board token would overshoot its goal).
- **Capture ("ăn quân")**: landing exactly on a cell occupied by an opponent's token
  sends it back to that player's yard (needs another 6 to leave again) — UNLESS the cell
  is a safe cell, in which case both tokens simply share it. A player's own tokens always
  freely share a cell (no self-capture, no blocking). Capture is only possible on the
  **shared track** — the private home stretch and yard never hold another color's token.
- **Safe cells**: each color's entry cell (4) + 4 star cells, one placed 8 cells past
  each entry (`(entryGlobalIndex + 8) % 52`) — **8 safe cells total**. Tokens there can
  never be captured.
- **Winning — first place only**: the instant one player gets all 4 tokens into their
  center goal, that player wins and the match ends immediately. This is deliberately
  simplified — there is **no 2nd/3rd/4th place tracking**, just first-place-ends-the-game,
  matching a quick single-sitting mobile session. Don't add ranking logic expecting to
  "complete" the match for the other 3 players.

## AI (`Core/AIEngine.swift`)

Given the rolled value, `GameModel.legalMoves(for:roll:)` enumerates every legal
token-move for the current player; `AIEngine.chooseMove` scores/selects among them:

- **Easy**: mostly random, light bias toward leaving the yard/capturing (weighted random
  pick, not a hard rule).
- **Normal**: greedy on the positive weights only — captures (heavy) + progress (further
  along a token's own path scores higher) + leaving the yard. Ignores exposure risk.
- **Hard**: same positive weights, plus a penalty if the destination cell is within
  exact capture range (1...6 cells behind, non-safe, on the shared track) of an opponent
  token — actively avoids obviously exposing itself.

## Monetization (hybrid framing — this app is 4-player, not 1v1 or fixed-4-AI)

`Core/PurchaseManager.swift` — copied from SamLoc's structure byte-for-byte, changed
only `productID = "com.quyenngo.cocangua.pro"` and the DEBUG capture-flag check
(`CN_CAPTURE != "upgrade"` gates `isPro`, so the paywall screenshot renders locked).

`Views/UpgradeView.swift` — 3 feature rows, SamLoc's visual style:
1. Hard AI difficulty for all 3 bots (free tier plays every bot at **Normal only** — the
   difficulty picker on Home is entirely hidden for free users, not just Hard-locked).
2. Local Pass & Play for up to 4 people sharing the device (free tier is solo-vs-3-AI
   only; the "Pass & Play" mode segment on Home is locked).
3. No ads, ever.

`Views/HomeView.swift` implements the gate: `GameSetupMode` picker (Solo vs. AI / Pass &
Play), and a `Stepper` for local player count (2...4) when Pass & Play + Pro. Free users
tapping a locked control land on `UpgradeView`.

## Structure

- `CoCaNgua/Core/` — `Board.swift` (track/safe-cell geometry + rendering-point math),
  `Token.swift`, `Player.swift`, `GameModel.swift` (turn state machine, legal-move
  enumeration, capture resolution, win detection, `#if DEBUG captureSetup(_:)` for
  screenshots), `AIEngine.swift`, `PurchaseManager.swift`, `Localization.swift`
  (app-agnostic, copied verbatim from SamLoc).
- `CoCaNgua/Views/` — `HomeView`, `GameView` (turn status, AI auto-play loop, move
  picker chips as a reliable fallback to tapping tokens directly), `BoardView` (the
  visual board — 52-cell ring + 4 home-stretch lanes + 4 yards + tokens, tap-to-move),
  `DieView` (real pip layouts, not a digit), `UpgradeView`, `OnboardingView` (3 pages),
  `RulesView` (7 sections).
- `CoCaNgua/{en,vi}.lproj/Localizable.strings` — real hand-written bilingual strings
  (not machine-translated), using "Cờ Cá Ngựa", "ngựa", "xúc xắc", "về đích", "ăn quân".
- `capture_shots.py` — `CN_CAPTURE` / `CN_LANG` DEBUG launch-arg driven, real in-app
  screenshots into `screenshots/final/{en,vi}/`.
- `make_icon.py` — real artwork (see "App-Store-readiness pass" below), no longer a
  stub.
- `project.yml` — XcodeGen. Regenerate `.xcodeproj` with `xcodegen generate` (or
  `./rebuild.sh`, which also runs the simulator + device build).

## Board rendering geometry (Views/BoardView.swift + Core/Board.swift)

The 52 track cells are placed at exactly-even points around the perimeter of a square
(13 per side, via `Board.trackPoint`) — purely a rendering convenience, game logic never
touches `CGPoint`. Each color's 6-cell home stretch is a straight lane from just inside
its entry corner to the board center (`Board.homeStretchPoints`); the lane is
deliberately confined to the **55%...97%** fraction of the corner-to-center line so it
doesn't visually overlap that color's yard box (`Board.yardAnchor`, ~13% inset,
20%-of-board-size box) — an earlier version had the first couple of home-stretch cells
rendering on top of the yard box, which read as a bug (a token that had clearly left the
yard looked like it was still sitting in it). If you resize the yard box or move its
anchor, re-check this overlap.

## Known judgment calls / simplifications from the build spec

- **Grammar-safe turn/event text**: per the sibling apps' documented "You" trap, no
  `%@`-substituted string is ever filled with "You" — `Player.name` is only ever
  literally "You" when `GameModel.humanCount == 1` (solo mode) and it's that player's
  turn, and `GameView` branches to a dedicated non-%@ string (`game.yourTurn`, etc.) in
  exactly that case. Verify this holds if solo-mode naming logic ever changes.
- **Live-formatted status/event text, not a stored log**: unlike SamLoc's `roundLog`
  (pre-localized strings stored in the model), `GameModel.lastEvent` stores structured
  data (`GameEvent` enum, no strings) and `GameView` formats it via `L()` at render time.
  This means a mid-game language switch never leaves stale English text behind — worth
  carrying forward to future siblings.
- **Move picker chips**: `GameView` shows a row of tappable move chips (🐴 + capture/goal
  icons) whenever it's a human's turn to move, in addition to direct on-board token
  taps in `BoardView`. This was a deliberate reliability choice — the board's token tap
  targets are small at mobile scale, so the chip row is the primary, reliable
  interaction path and board taps are a bonus.
- **AI turn-driving**: `GameView.maybeTriggerAI()` re-schedules itself after every AI
  roll/move (0.7s delay) rather than a fixed-step loop, so a 6-roll chain of AI extra
  turns plays out automatically and visibly, one step at a time.

## Verified

- `xcodegen generate` succeeds; `xcodebuild ... -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build`
  succeeds clean, no errors or warnings from app code.
- Installed and launched on simulator; walked through onboarding, home (solo + Pass &
  Play mode/difficulty pickers), a live mid-game board render, a near-win capture
  (verifies exact-landing-on-goal legal-move logic and the move-chip UI), the locked
  paywall, rules, and the Vietnamese locale — all via `CN_CAPTURE`/`CN_LANG`. No crashes.
- `./rebuild.sh`'s simulator build step passes; the **device/archive build step fails**
  with "No profiles for 'com.quyenngo.cocangua' were found" — expected, since the bundle
  ID isn't registered in App Store Connect yet. That registration + real signing is part
  of the later ASC step, not this build pass.

## App-Store-readiness pass (2026-07-31)

Icon, screenshots, and the legal site are done. Game logic was not touched.

- **App icon**: `make_icon.py` rewritten from the die-pip stub into real artwork — a
  bold solid horse-head silhouette (the Apple Symbols "♞" BLACK CHESS KNIGHT glyph,
  which renders as a clean filled shape, not an outline) in deep red on a gold
  rounded-square medallion/plaque, tilted -8°, on a rich royal-blue → near-black-navy
  gradient background (one dominant accent color rather than cramming all 4 player
  colors in). Matches the house single-emblem style (SamLoc's tilted "2♥" card).
  Verified 1024×1024 RGB PNG at
  `CoCaNgua/Assets.xcassets/AppIcon.appiconset/AppIcon.png`, reads clearly down to
  60px. Also fixed `Contents.json` in that asset catalog, which was missing the
  `"filename": "AppIcon.png"` key entirely — Xcode wouldn't have picked up any icon
  image without it, stub or real.
- **Screenshots**: `capture_shots.py` ran cleanly once pointed at an isolated
  simulator — see gotcha below — producing `screenshots/final/{en,vi}/01-home.png`
  through `04-rules.png` (8 images total). Every image was visually inspected
  (Read tool, not just a green script exit): correct English/Vietnamese text with
  proper diacritics and no mojibake, correct language per locale, the board renders
  the 52-cell outer track + 4 home-stretch diagonals converging cleanly on the center
  flag + 4 yards with tokens visible, distinct, and **not** overlapping (the
  documented home-stretch/yard overlap bug is confirmed fixed in these real captures),
  move/die UI legible, no placeholder text. One real bug found and fixed: the very
  first capture (`en/01-home.png`) had iOS's one-time "Ready for Apple Intelligence"
  system notification banner overlaid on a fresh simulator boot — fixed by adding a
  throwaway warm-up launch (5s, then terminate) before the real capture loop in
  `capture_shots.py`, so any first-boot system banner fires and clears before any
  real screenshot is taken.
  - **Gotcha for next time**: `find_device()` originally grabbed *any* booted
    "iPhone ... Pro Max" simulator. This machine had several sibling apps' simulators
    already booted and installed (`com.quyenngo.baucua`, `com.quyenngo.tienlen`, etc.
    — this is a 5+-app lineup, not just this one), and the very first run's screenshots
    silently came out as **Bầu Cua Pro's paywall and a Tiến Lên card-game screen** —
    a different app's UI entirely, not a CoCaNgua bug, but a shared-simulator
    contamination issue. Fixed by creating a dedicated `CoCaNgua-Capture` simulator
    (`xcrun simctl create`) and having `find_device()` prefer it by name over any
    generic "Pro Max" match. **Always visually inspect screenshots — a script that
    exits 0 proves nothing about which app was actually on screen.**
- **Legal site**: `~/Projects/cocangua-legal` — same template/CSS as
  `fanorona-legal` (index/privacy/support, same no-data-collection and StoreKit-only-
  IAP language), content adapted for this app (4-player race description; support
  page's "How to play" section covers leaving-the-yard-on-6, the extra-roll-on-6 with
  three-6s forfeit, exact-landing-to-finish, ăn quân capture, and the 8 safe cells;
  "Difficulty levels" section matches `PurchaseManager`/`UpgradeView` exactly — free
  tier is Normal-only AI solo vs. 3 bots, Pro unlocks Hard AI for all bots + local
  Pass & Play up to 4 players + no ads). Public GitHub repo
  `qngo9871-cmyk/cocangua-legal`, GitHub Pages enabled (`status: "built"`), live at
  **https://qngo9871-cmyk.github.io/cocangua-legal/** (index, privacy.html, and
  support.html all verified 200).

## TODOs for the App Store Connect step (not done here, out of scope)

- Register `com.quyenngo.cocangua` in ASC, set up a distribution provisioning profile
  (the device/archive build already fails today with "No profiles for
  'com.quyenngo.cocangua' were found" — expected until this is done).
- IAP product `com.quyenngo.cocangua.pro` setup in ASC, pricing, review notes.
- Upload the real icon/screenshots/legal-site URL from this pass into ASC metadata.
