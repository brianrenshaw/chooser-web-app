# Who's First? Web App Process Doc

[[toc-levels:2]]
[[toc]]

## Why This Exists

A group of people often needs to randomly pick one person to "go first" — for chores, games, decisions, anything. Coin flips only handle two people, drawing straws needs straws, and counting-out rhymes have a deterministic flaw. Phone-based "decide who's first" apps often feel slow, ad-stuffed, or force one interaction style on every group.

This project is a single-page mobile web app that does one thing: choose who goes first. Together preserves the original ritual—everyone holds a finger on the screen, the app waits for stragglers, runs a tension-building countdown, then lights up one finger. Tap In supports groups that cannot all touch at once: each person taps once to create a numbered entry, then the group explicitly starts the pick. Both modes use the same black background, glowing neon language, escalating feedback, and fair on-device random selection.

The interface uses one compact, whimsical icon toggle in the upper-left rather than a persistent segmented control. In Together it shows the orbit-and-fingers artwork; in Tap In it becomes a trail of numbered tokens. The accessible label and tooltip describe the mode the control will switch to, and the toggle is disabled during a countdown.

The same code is wrapped with Capacitor into a native iOS app so the chooser can use the iPhone's real Taptic Engine for haptics, which the web platform does not expose on iOS Safari.

## How the Ecosystem Works

There are three deployment targets that all run the same `web/` source:

1.  **Plain mobile web** at `https://brianrenshaw.github.io/chooser-web-app/`. Anyone with a phone browser can use it, no install. Hosted on GitHub Pages, deployed via a GitHub Actions workflow on every push to `main`.
2.  **iOS home-screen PWA**. The user opens the GitHub Pages URL on iPhone, taps Safari's share menu, then "Add to Home Screen". The app launches fullscreen with no browser chrome thanks to the `apple-mobile-web-app-capable` meta tag. Same code, same limitations as plain web (audio click instead of real haptics).
3.  **Native iOS app** via Capacitor. The `web/` folder is bundled into a thin Swift WebKit shell (`ios/App/App.xcworkspace`). On native, the app detects the Capacitor runtime and routes feedback through the `@capacitor/haptics` plugin, which calls the real iOS Taptic Engine APIs.

The web bundle is the single source of truth. `npx cap sync ios` copies `web/*` into `ios/App/App/public/` so the native app gets every change. There is no build step, no bundler, no transpiler, no framework. Editing `web/app.js` in place is the workflow.

## What It Produces

This is an interactive UI, not a data pipeline, so there are no output files in the data sense. The "outputs" are runtime artifacts:

The following table describes Together's runtime UI states. Every fresh launch starts in Together.

| State | Visible result |
|---|---|
| `IDLE` | Black screen, faint hint text "Place two or more fingers." |
| `WAITING` | One glowing neon ring per finger, slowly pulsing. Hint text fades. Each ring has its own hue. |
| `COUNTDOWN` | Same rings, pulse rate accelerates from 1200ms period down to 150ms over `COUNTDOWN_MS`. |
| `REVEALED` | One ring scales to 1.5x, brightens, and holds. The other rings fade to opacity 0. |

Tap In has a separate, sequential flow:

| Phase | Visible result |
|---|---|
| Collecting | Each completed tap adds the next numbered, colored ring to a deterministic centered grid. Ring size begins shrinking after five entries so the layout can support up to 50. |
| Ready | With at least two committed entries and no tap in progress, the control reads `Pick from N`. Undo removes the newest entry; Clear requires confirmation. |
| Countdown | The button snapshots the current group and immediately starts the shared one-second countdown; Tap In does not use Together's 1.5-second settling wait. |
| Revealed | One number glows as the winner. Pick again draws from the same pool, where repeats are allowed; New group clears every entry and remains in Tap In. |

The deployed artifacts are:

*   `https://brianrenshaw.github.io/chooser-web-app/` — the live web app
*   `ios/App/App.xcworkspace` — the native iOS Xcode workspace used for physical-device, archive, and App Store builds

## How the Automation Works

There is one automated cycle: the web deploy.

1.  Developer pushes a commit to `main` that touches `web/**` or `.github/workflows/pages.yml`.
2.  GitHub Actions fires the workflow defined in `.github/workflows/pages.yml`.
3.  Workflow checks out the repo, runs `actions/configure-pages@v5`, uploads the `web/` directory as a Pages artifact, then deploys it via `actions/deploy-pages@v4`.
4.  GitHub Pages serves it at the canonical URL within ~30–60 seconds.

The Pages source was switched from "Deploy from a branch" to "GitHub Actions" mode. The branch-deploy mode only supports `/` or `/docs` as the source root. Since the project keeps web sources in `web/` (so Capacitor can use it as `webDir`), the workflow approach was the cleanest fit.

The iOS app deploy is fully manual: open Xcode, hit Cmd+R, select the iPhone as run target. There is no CI for the native build.

Management URLs:

*   Workflow runs: `https://github.com/brianrenshaw/chooser-web-app/actions`
*   Pages settings: `https://github.com/brianrenshaw/chooser-web-app/settings/pages`
*   Repo: `https://github.com/brianrenshaw/chooser-web-app`

## How the Core Logic Works

The app has two mode-specific flows driven by Pointer Events. State transitions, timing, temporary Tap In entries, and rendering are all in `web/app.js`.

### Together state machine

The four states live in the `STATE` constant at the top of `app.js`. State transitions:

*   `IDLE` (default). Two or more fingers down → `WAITING`.
*   `WAITING`. A `setTimeout` is set for `WAIT_MS` (1500ms). Any new `pointerdown` or `pointerup` cancels the timer and re-enters `WAITING` (which sets a fresh timer). If the finger count drops below 2, go to `IDLE`. If the timer fires with at least 2 fingers down, go to `COUNTDOWN`.
*   `COUNTDOWN`. `requestAnimationFrame` loop runs for `COUNTDOWN_MS` (1000ms) and accelerates the pulse animation. A new `pointerdown` cancels back to `WAITING` (so latecomers reset the round). A `pointerup` is allowed; the countdown continues with remaining fingers unless the count drops below 2.
*   `REVEALED`. The winner is picked with an unbiased Web Crypto random index (falling back to `Math.random()` where Web Crypto is unavailable). Winner gets `.winner` class, others get `.loser`. The first new pointerdown clears the displayed result, registers that finger, and starts the next round.

### Tap In flow and invariants

*   Switching to Tap In begins with an empty group; a fresh app launch still defaults to Together.
*   Each completed pointer gesture can commit at most one entry. Entries receive sequential numbers from 1 through 50, a color, and a position in the centered grid.
*   Undo removes only the newest committed entry, so its number is reused by the next tap. Clear requires confirmation. New group clears the entire group without switching back to Together.
*   Pick is unavailable until at least two entries are committed and no pointer gesture is pending. It snapshots the current group and starts the shared one-second countdown immediately, without the 1.5-second late-joiner wait.
*   Winner selection uses the same unbiased Web Crypto random-index helper as Together, with the existing `Math.random()` fallback. Pick again selects from the unchanged snapshot, so the same number may win consecutive picks.
*   Opening Help & About preserves committed Tap In entries. If the page becomes hidden while collecting, only an unfinished pointer gesture is discarded. If it becomes hidden during the countdown, the countdown is cancelled and the committed group returns to collecting.
*   Tap In has no persistence. Reloading or closing the app discards the group, and the next launch starts in Together.

### Why Together has a late-joiner wait

Without `WAITING`, a slow finger landing 200ms after the round started would not be a fair contender. The 1500ms wait gives everyone a window to commit. Any new finger during the wait restarts the timer, so the round only proceeds once all fingers have been still for the full window.

The earlier spec called for 3000ms here. It was shortened to 1500ms by request because the longer wait felt sluggish in playtesting.

### Why pointer events

Touch events (`touchstart`, `touchmove`, `touchend`) work but require a different code path from mouse events and have inconsistent multi-touch semantics across browsers. Pointer Events unify mouse, pen, and touch into one model with a stable `pointerId` per finger, which is exactly the key Together's `pointers` Map and Tap In's one-entry-per-gesture guard need. iOS caps simultaneous touches at 5, which limits Together but not Tap In's sequential group of up to 50.

### Why the golden-angle hue distribution

Random hues collide. A fixed palette of N colors caps the player count and looks repetitive across rounds. The golden angle (137.508 degrees) is the rotation that maximally separates points placed sequentially around a circle. Each new finger picks `(lastHue + 137.508) % 360`. The first round starts from `Math.random() * 360`, so colors vary each session but always look distinct from each other.

The colors are computed in OKLCH color space where supported because OKLCH is perceptually uniform. In HSL, yellow at 60% lightness looks washed out next to blue at 60% lightness; in OKLCH, equal lightness numbers produce equal perceived brightness. Older WebKit versions receive an HSL fallback so the rings remain visible.

### Why the audio click

The Web Vibration API (`navigator.vibrate`) is supported on Android Chrome but not iOS Safari (still, as of 2026). On iOS web, there is no haptic API at all, no entitlement, no flag. The audio click is a workaround: a short WebAudio oscillator with a percussive envelope plays through the speaker, simulating an impact. It is not a haptic, but it is enough to give the moment some weight when haptics are unavailable.

When the same code runs inside Capacitor on iOS, `window.Capacitor.isNativePlatform()` returns true and `Capacitor.Plugins.Haptics` is available. The `nativeHaptics()` helper returns the plugin only on native; on web it returns null, and the code falls through to the audio click. The same `tick()` and `revealHaptic()` functions handle both branches, so there is one source of truth for "feedback at this moment."

### Why "winner sees it most" cannot be literal

iOS Taptic Engine vibrates the entire device. There is no API to direct haptic energy to one of multiple touch points. So when six people are touching the phone, the winner does not literally feel a different vibration than the losers. The reveal moment is engineered to feel dramatic for the whole device (six rapid HEAVY impacts, then a 300ms sustained vibrate, then a SUCCESS notification haptic), and the visual reinforcement of the winner's ring expanding while the others fade gives the winner the perception that the haptic was for them.

## Key Files

The following table lists every file that matters for this project.

| File | Location | Purpose |
|---|---|---|
| `index.html` | `web/` | Entry point. Viewport/PWA metadata, the compact Together/Tap In icon toggle, the `#stage` chooser, and the Help/About dialog. |
| `app.js` | `web/` | The whole app: both mode flows, pointer handling, temporary entries, random selection, rendering, and haptics. |
| `style.css` | `web/` | Black background, animated mode-toggle artwork, neon ring and numbered-grid styles, pulse keyframes, winner/loser transitions. |
| `support.html` | `web/` | Public instructions and troubleshooting for Together and Tap In. |
| `privacy.html` | `web/` | Public policy covering temporary touch and numbered-entry processing. |
| `icon.svg` | `web/` | Favicon and native-art source. Black square with a gradient neon ring and SVG glow filter. |
| `apple-touch-icon.png` | `web/` | 180x180 PNG fallback for iOS home screen icon (older iOS does not accept SVG). |
| `.nojekyll` | `web/` | Tells GitHub Pages not to run Jekyll on the artifact. |
| `capacitor.config.json` | repo root | Capacitor config: appId, appName, webDir points at `web/`. |
| `package.json` | repo root | npm manifest. Capacitor 7 deps: core, cli, ios, haptics. |
| `pages.yml` | `.github/workflows/` | GitHub Actions workflow that deploys `web/` to GitHub Pages on push. |
| `App.xcworkspace` | `ios/App/` | Xcode workspace (open this, not the .xcodeproj) for the native iOS build. |
| `Podfile` | `ios/App/` | CocoaPods dependencies (managed by `npx cap sync`, do not hand-edit). |
| `.gitignore` | repo root | Excludes `node_modules/`, `ios/App/Pods/`, build outputs. |

External dashboards and management URLs:

*   GitHub repo: `https://github.com/brianrenshaw/chooser-web-app`
*   Live site: `https://brianrenshaw.github.io/chooser-web-app/`
*   Pages settings: `https://github.com/brianrenshaw/chooser-web-app/settings/pages`
*   Actions runs: `https://github.com/brianrenshaw/chooser-web-app/actions`

## Directory Layout

```text
chooser-web-app/
├── .github/
│   └── workflows/
│       └── pages.yml              GitHub Actions workflow that deploys web/ to Pages
├── .gitignore                     Excludes node_modules, Pods, build outputs
├── capacitor.config.json          Capacitor app config (appId, webDir=web)
├── docs/
│   └── finger-chooser-web-app-process-doc.md   This document
├── ios/                           Generated by `npx cap add ios`, gitignored except App/
│   └── App/
│       ├── App/                   Swift sources, Info.plist, web bundle copied to public/
│       ├── App.xcodeproj/         Xcode project (do not open this directly)
│       ├── App.xcworkspace/       Open this in Xcode for native builds
│       ├── Podfile                CocoaPods deps, managed by cap sync
│       └── Pods/                  CocoaPods install output, gitignored
├── node_modules/                  npm install output, gitignored
├── package.json                   npm manifest, Capacitor 7 deps
├── package-lock.json              npm lockfile
└── web/                           The single source of truth for app code
    ├── .nojekyll                  Disable Jekyll on Pages
    ├── app.js                     State machine, pointer handling, haptics, rendering
    ├── apple-touch-icon.png       180x180 PNG icon for iOS home screen
    ├── icon.svg                   Browser tab favicon, neon circle with SVG glow
    ├── index.html                 Entry point with PWA meta tags
    └── style.css                  Visual styles, animations, ring effects
```

## How to Run Operations

### Local development

Serve the web folder over HTTP and open the LAN URL on a phone on the same Wi-Fi.

1.  `cd /Users/brianrenshaw/Projects/chooser-web-app/web`
2.  `python3 -m http.server 8765`
3.  Find your Mac's LAN IP: `ipconfig getifaddr en0`
4.  Open `http://<lan-ip>:8765/` on a phone on the same Wi-Fi
5.  Tap In can be exercised with a mouse or one-finger touch, but Together multi-touch and native haptics must be tested on a real device.

### Deploy to web (GitHub Pages)

The deploy is automatic on push.

1.  Make changes inside `web/`
2.  `git add web/...`
3.  `git commit -m "..."`
4.  `git push`
5.  Watch the run at `https://github.com/brianrenshaw/chooser-web-app/actions`. The workflow finishes in about 30 seconds.
6.  Hard-reload the live URL on your phone. Mobile Safari caches `app.js` aggressively; appending `?v=N` to the URL forces a refresh.

### Build and run the iOS app

The iOS project supports local physical-device runs and paid-team App Store distribution. Xcode is set to version 1.0 (build 2) locally. App Store Connect and TestFlight still contain the validated Together-only build 1, so build 2 needs a fresh archive, validation, and upload before the two-mode release can be submitted.

1.  After any change to `web/`, run `npx cap sync ios` from the repo root. This copies `web/` into `ios/App/App/public/` and refreshes plugin registrations.
2.  Open the Xcode workspace: `npx cap open ios` (or open `ios/App/App.xcworkspace` directly, never the `.xcodeproj`).
3.  In Xcode, select the **App** target. In the Signing & Capabilities tab, ensure your Personal Team is selected.
4.  Plug in the iPhone via USB. First time, tap "Trust This Computer" on the phone.
5.  Select the iPhone as the run destination from the device picker at the top of Xcode.
6.  Hit Cmd+R. First build is slow.
7.  First launch on the device, iOS will refuse with "Untrusted Developer." On the iPhone: Settings → General → VPN & Device Management → tap your Apple ID → Trust. Then tap the app icon.

### Manually trigger a Pages deploy

If you want to redeploy without a new commit:

1.  `https://github.com/brianrenshaw/chooser-web-app/actions/workflows/pages.yml`
2.  Click "Run workflow" → "Run workflow"

### View deploy logs

Workflow runs are at `https://github.com/brianrenshaw/chooser-web-app/actions`. Click any run to see step-by-step logs and the resulting Pages URL.

## How to Modify

### Change the wait or countdown duration

In `web/app.js`, top of the file:

*   `WAIT_MS` controls the late-joiner window (default 1500ms)
*   `COUNTDOWN_MS` controls the tension countdown (default 1000ms)

`WAIT_MS` applies only to Together. Tap In begins the same one-second countdown immediately after an eligible `Pick from N` action. After a Together result is revealed, the first new pointerdown immediately clears the old result and registers that finger for the next round.

After editing, push to deploy the web version, and run `npx cap sync ios` plus a Cmd+R rebuild for the iOS version.

### Change the pulse speed range

In `web/app.js`:

*   `PULSE_BASE_MS` is the slow pulse period at the start (default 1200ms)
*   `PULSE_FAST_MS` is the fast pulse period at the end of the countdown (default 150ms)

The countdown easing is `t * t` (quadratic), so the pulse speeds up gently at first and rapidly at the end. Change to linear `t` for a constant ramp.

### Change the color palette

In `web/app.js`, the `nextHue()` function uses a golden-angle increment. To use a fixed palette instead, replace `nextHue` with an array lookup. To change the chroma or lightness of the rings, edit the `oklch(...)` calls in `addRing()`:

*   `--ring-color: oklch(72% 0.28 ${hue})` — the ring border color
*   `--ring-glow: oklch(82% 0.22 ${hue})` — the box-shadow glow color

Higher chroma (the second number, max ~0.4) means more vivid. Higher lightness (the first number) means brighter.

### Change the haptic feel

In `web/app.js`:

*   `fingerLandHaptic()` — single LIGHT impact on each new finger
*   `tick(intensity)` — countdown ticks. `intensity` is the eased countdown progress (0 to 1). Currently MEDIUM below 0.2, HEAVY above.
*   `revealHaptic()` — six HEAVY impacts at 0/70/140/210/290/380ms, then a 300ms sustained vibrate at 420ms, then a SUCCESS notification at 760ms.

Capacitor's haptics plugin styles are `LIGHT`, `MEDIUM`, `HEAVY`, plus `SOFT` and `RIGID` on iOS 13+. Notification types are `SUCCESS`, `WARNING`, `ERROR`.

### Add a new state

States are string constants in the `STATE` object. To add one:

1.  Add the constant: `STATE.NEW_STATE = 'NEW_STATE'`
2.  Write an `enterNewState()` function that calls `cancelTimers()` and sets `state = STATE.NEW_STATE`
3.  Update `handlePointerDown`, `handlePointerEnd` to handle pointer events in that state
4.  Add transitions from existing states by calling `enterNewState()` where appropriate

### Change Tap In behavior

Keep these product invariants together when modifying Tap In:

*   At most one committed entry per pointer gesture and at most 50 entries per group
*   Sequential numbering with Undo reusing the removed newest number
*   Pick enabled only at two or more committed entries with no pending pointer
*   No settling wait; use a snapshot of the group for the shared one-second countdown
*   Pick again keeps the pool and allows repeated winners; New group clears the pool and stays in Tap In
*   Deterministic centered layout, with numbered rings shrinking after five entries
*   Committed entries survive Help/About but never reload, app close, or New group

### Change the GitHub Pages deploy schedule

There is no schedule. The workflow runs on push to `main` when `web/**` or the workflow file changes, and on manual `workflow_dispatch`.

### Change the iOS bundle ID or app name

Bundle ID and app name are set in `capacitor.config.json` (`appId`, `appName`). After editing, run `npx cap sync ios` to propagate the change into the Xcode project.

## Known Quirks and Edge Cases

*   **iOS Safari has no Web Vibration API.** `navigator.vibrate()` silently no-ops on iOS web. Real haptics only work in the Capacitor-wrapped iOS app via `@capacitor/haptics`. The audio click is the iOS web fallback.

*   **AudioContext is locked until first user gesture on iOS.** The `ensureAudio()` call in `handlePointerDown` is what unlocks it. The very first finger placed in a session may produce no audio click; subsequent ones will.

*   **Mobile Safari aggressively caches `app.js`.** Hard reload is unreliable on iOS. Append `?v=N` to the URL, increment N, to bypass cache.

*   **Free Apple ID signing has hard limits.** Sideloaded iOS app expires every 7 days, requires reconnecting the phone to the Mac to refresh, and is bound to one device. Sharing the iOS app to other people requires the Apple Developer Program ($99/year) and TestFlight or Ad Hoc distribution.

*   **iOS caps simultaneous touches at 5.** Six simultaneous fingers will not all register in Together. Tap In is the sequential alternative and supports up to 50 entries.

*   **Tap In state is intentionally temporary.** Numbers are not player profiles. They, their colors, internal identifiers, and tap positions exist only in memory and are never persisted or transmitted.

*   **`pointerleave` was tried and removed.** The earlier version listened for `pointerleave` to clean up off-screen pointers, but it could prematurely remove a finger that dragged near the viewport edge. `pointercancel` is sufficient and behaves correctly.

*   **GitHub Pages "Deploy from branch" mode does not support `/web` as a source.** Only `/` or `/docs` are valid for that mode. The project uses the GitHub Actions deploy mode instead (`build_type: workflow`), which is why `pages.yml` exists. Do not flip Pages back to "Deploy from branch" or the URL will start serving the repo root and break.

*   **Capacitor's iOS template still uses CocoaPods.** Not Swift Package Manager. CocoaPods must be installed (`brew install cocoapods`) before `npx cap add ios` will work.

*   **Capacitor 7 needs Xcode 16+.** The project currently builds with Xcode 26.6. Older Xcode may not build the generated project.

## If You Are Setting This Up From Scratch

Prerequisites:

*   macOS with Homebrew
*   Node.js 20 or newer (for `npx`)
*   Xcode 16 or newer, with command-line tools pointing at the Xcode app (not just CommandLineTools)
*   CocoaPods (`brew install cocoapods`)
*   GitHub CLI (`gh`) authenticated as the target account
*   A free Apple ID for sideloading, or paid Apple Developer Program for distribution

Step-by-step:

1.  Clone the repo: `git clone https://github.com/brianrenshaw/chooser-web-app.git`
2.  `cd chooser-web-app`
3.  Install npm dependencies: `npm install`
4.  Verify the web build serves locally: `cd web && python3 -m http.server 8765`, then open the LAN URL on a phone.
5.  Point xcode-select at the full Xcode app (not CommandLineTools): `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` (use `Xcode-beta.app` if applicable)
6.  Accept the Xcode license: `sudo xcodebuild -license accept`
7.  If `ios/` does not exist (fresh clone before iOS scaffold), run `npx cap add ios`. If it exists, run `npx cap sync ios` to refresh plugin pods.
8.  Open the workspace: `npx cap open ios`
9.  In Xcode, select the App target. Signing & Capabilities tab. Sign in with your Apple ID. Pick your Personal Team. Edit the bundle ID to something globally unique if you get a registration conflict.
10.  Plug in iPhone, select it as run destination, hit Cmd+R.
11.  On the iPhone, trust the developer certificate at Settings → General → VPN & Device Management.

To set up the Pages deploy on a fresh fork:

1.  Push to `main`. The workflow will run.
2.  Switch the Pages source to "GitHub Actions": `gh api -X PUT repos/<user>/<repo>/pages -f 'build_type=workflow'`
3.  Confirm: `gh api repos/<user>/<repo>/pages` should show `build_type: workflow`.

## History

For the current App Store preparation status, see [`docs/app-store-readiness.md`](app-store-readiness.md).

The following table tracks meaningful changes.

| Date | Change |
|---|---|
| 2026-05-01 | Initial finger chooser web app committed: `index.html`, `style.css`, `app.js`, `.nojekyll`. Pages enabled in legacy "Deploy from branch" mode. |
| 2026-05-01 | Neon-circle favicon added. SVG with gradient and glow filter for browser tabs, 180x180 PNG fallback for iOS home screen. |
| 2026-05-01 | Repo restructured: web sources moved to `web/`, Capacitor 7 added at root, GitHub Actions Pages workflow replaces branch-deploy mode. Capacitor Haptics wired into `app.js` with audio-click fallback for non-native runtimes. |
| 2026-05-01 | iOS platform added via `npx cap add ios`. App built and signed with free Apple ID, installed on physical iPhone. |
| 2026-05-01 | Haptic feedback strengthened. `fingerLandHaptic`, `tick`, and `revealHaptic` split out. Reveal volley extended to six HEAVY impacts plus sustained vibrate plus SUCCESS notification. |
| 2026-05-02 | Process documentation written. |
| 2026-05-02 | Fixed `tick` shadowing bug in `enterCountdown()` (renamed inner rAF callback to `step`). Countdown haptic ticks now actually fire and escalate as designed. |
| 2026-08-29 | Began App Store readiness pass: fixed Xcode/CocoaPods build setting, updated Capacitor 7, added replay guidance and older-iOS color fallback, added About/Privacy/Support, replaced default native branding, and added privacy/export metadata. |
| 2026-08-30 | Registered `com.brianrenshaw.fingerchooser` under the paid Apple team, changed v1 to iPhone-only, added the public support email, and verified signed archive plus App Store IPA export. The App Store Connect app record still requires the signed-in New App form. |
| 2026-08-30 | Implemented Together/Tap In with one compact animated icon toggle, set the Xcode project to build 2, and prepared five 1320×2868 replacement screenshots covering both modes. TestFlight/App Store Connect still show build 1 and its Together-only listing; build 2 still needs archive/upload, listing updates, and fresh device QA before submission. |
