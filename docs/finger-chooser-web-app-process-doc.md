# Who's First? Native App and Legacy Web Process

Last updated: August 30, 2026

## Product scope

Who's First? answers one narrow question: who goes first?

The production iPhone app has three modes:

- **Together** — two or more people hold one finger on the screen at the same time.
- **Tap In** — 2–50 people join a numbered pool one completed tap at a time.
- **Pinball** — 2–12 people tap nearest their seats around a flat iPhone, then the region containing a visible ball's real endpoint wins.

The app does not score games, maintain player profiles, store history, or manage brackets. Its interaction data is temporary and every choice happens on the device.

## Two independent deliverables

The repository now contains two separate products. They share branding and public support URLs, but they do not share runtime code.

| Deliverable | Source of truth | Distribution | Modes |
|---|---|---|---|
| Native iPhone app | **ios/App/App/Native/** and the Xcode project | App Store and TestFlight | Together, Tap In, Pinball |
| Legacy browser app | **web/** | GitHub Pages and Add to Home Screen | Together, Tap In |

The App Store app is a native SwiftUI application. It no longer embeds the browser app and does not use Capacitor, CocoaPods, WebKit, a bridge storyboard, or a generated public directory.

The legacy browser app remains useful and deployable, but changes under **web/** do not appear in the native app. There is no sync step between the products. Pinball and future native features do not need to be duplicated on the web.

The browser version still begins in Together on every fresh launch, cycles only between Together and Tap In, uses Pointer Events and Web Crypto, and falls back to Web Audio where iOS Safari cannot provide haptics. The native saved-default behavior and Pinball mode do not apply to it.

## Native product behavior

### Mode control

A compact animated icon in the upper-left cycles in this order:

1. Together
2. Tap In
3. Pinball

A tap changes only the current session. A long press stores the current mode as the next-launch default. A first install falls back to Together. The saved launch mode is the only app preference persisted.

Switching away from a populated Tap In or Pinball group requires confirmation because the group will be cleared. Mode changes are disabled during a draw, Pinball run, or another critical interaction. Together also cannot be switched while physical fingers are active.

### Together

Together deliberately preserves the original simultaneous-finger behavior:

1. One finger produces guidance to add another.
2. Two or more active fingers begin a 1.5-second settling window.
3. A new finger or a removal during settling restarts that window while at least two remain.
4. The app runs a one-second accelerating countdown.
5. One of the active touch identities is chosen uniformly.

A late finger during the countdown returns the round to settling. Removing one of three or more fingers during the countdown does not restart it; the eventual choice uses only the identities still down. Dropping below two cancels the round.

The winning ring remains visible after fingers lift. The next new touch begins a new round.

True simultaneous input comes from a small UIKit surface with multiple touch enabled. Each UITouch receives a stable native identity for its lifetime. SwiftUI draws the rings and surrounding interface.

### Tap In

Tap In is the sequential alternative for larger groups:

- A touch-down creates a provisional numbered token at the physical location.
- Movement updates that provisional token but never creates another entry.
- Touch-up commits exactly one entry.
- Cancellation discards the provisional token.
- Committed entries settle into a deterministic centered grid.
- Tokens shrink and reflow as the count grows, up to 50.
- Undo removes only the newest entry and allows its number to be reused.
- Clear requires confirmation.
- Pick is enabled only with at least two committed entries and no pending touch.

Pick snapshots the committed array, runs the one-second countdown, and chooses one entry from that frozen array. Pick again starts an independent choice from the unchanged pool, so repeat winners are allowed. New group clears the pool while remaining in Tap In.

The entry array, not the visible view hierarchy, is the source of truth.

### Pinball

Pinball combines a visible physical metaphor with an exact mathematical result:

1. Put the iPhone flat.
2. Add 2–12 numbered seats by tapping near each person's physical seat.
3. The app assigns every seat an equal-area radial region in clockwise seat order.
4. Start samples one secure launch: a uniform starting point, independent uniform direction, and independent travel distance.
5. A five-second fast-to-zero trajectory visibly reflects from the playfield walls.
6. The region containing the trajectory's actual final point wins.

The production travel distance is sampled between 10 and 16 playfield perimeters. The slowdown curve is:

~~~text
progress(u) = 1 - (1 - u)^3.2
~~~

where u is normalized time from zero to one. The derivative decreases smoothly to zero, while the endpoint remains exact.

SpriteKit presents the precomputed path; it does not simulate physics and does not choose the result. Wall feedback is scheduled from the analytic collision distances and the inverse slowdown curve. Very close cues are coalesced at 75 milliseconds so the hardware can express them cleanly.

After the run, the winning region flashes four times with ascending sound and haptic cues, then remains highlighted. Play again keeps the seating and samples a new independent launch. New group clears the seats.

With Reduce Motion enabled, the app skips the traveling animation and presents a steady, accessible result without changing the sampled launch or winner.

## Fairness model

### Together and Tap In

Together chooses from the current active touch identities. Tap In chooses from an immutable snapshot of committed entries. Both use Swift's SystemRandomNumberGenerator through Int.random over the requested range. Range sampling is uniform and does not introduce modulo bias.

Visual position, token size, hue, entry order, animation timing, and feedback do not affect eligibility or probability.

### Pinball

Pinball does not preselect a winner and animate toward it. It has one source of truth: the real endpoint of the sampled reflected path.

The fairness argument has four parts:

1. The start point is sampled uniformly by area over the playfield.
2. Direction is sampled independently and uniformly over the full circle.
3. Travel distance is sampled independently.
4. Ideal reflection in a rectangle preserves the uniform position distribution.

Therefore the endpoint is uniform over the rectangle. The radial partition uses swept rectangle area, not equal angles, so every region has exactly one Nth of the playfield area. A uniform endpoint gives each of N seats probability 1/N.

Equal angles would be biased in a non-square playfield because rays near long corners sweep more area. The implementation instead converts rays to exact cumulative rectangle area and advances boundaries in equal-area phases. For the important two-seat top-and-bottom case, the same general construction yields an exact horizontal 50/50 split.

The reflected trajectory uses the analytic unfolded-rectangle construction. A straight ray travels through mirrored copies of the playfield, then a triangle-wave fold maps it back into the real rectangle. Endpoint and wall events are independent of frame rate, screen refresh rate, and SpriteKit timing.

The following invariants must remain true in future changes:

- No separate random winner call in Pinball.
- No winner-dependent launch, distance, slowdown, path, or animation duration.
- No dwell-time winner and no physics-body contact winner.
- The reported winner must be the region containing the stored final point.
- Regions must remain equal by rectangle area in portrait and landscape.
- Geometry changes during an active run must cancel the run rather than reinterpret its endpoint.

## Native architecture

The native target requires iOS 18, compiles in Swift 6 language mode with strict concurrency, and supports iPhone portrait plus both landscape orientations.

| Layer | Primary files | Responsibility |
|---|---|---|
| App entry and composition | **AppDelegate.swift**, **Native/App/** | SwiftUI App lifecycle, root composition, observable app model, mode coordination |
| Pure chooser cores | **Native/Core/** | Together and Tap In state machines, scheduling abstraction, secure index selection, launch-default storage |
| Multitouch input | **Native/Input/NativeTouchSurface.swift** | UIKit UIViewRepresentable and stable UITouch identity mapping |
| Mode views | **Native/Modes/** | SwiftUI Together, Tap In, and Pinball surfaces, controls, layouts, accessibility focus |
| Pinball math | **Native/Pinball/** | secure launch sampling, equal-area partition, analytic billiards, slowdown, endpoint ownership |
| Feedback | **Native/Feedback/** | Core Haptics, UIKit fallback generators, synthesized AVFoundation audio, analytic SpriteKit path presentation |
| Shared interface | **Native/UI/** | app chrome, neon rings and tokens, offline About, Help, and Privacy flow |
| Configuration | **Info.plist**, **PrivacyInfo.xcprivacy**, **Assets.xcassets** | identity, orientations, launch screen, privacy manifest, app icon |
| Automated tests | **ios/App/AppTests/**, **ios/App/AppUITests/** | deterministic state-machine, geometry, fairness, lifecycle, accessibility-shell, and rotation coverage |

The Xcode source of truth is **ios/App/App.xcodeproj** and its shared **App** scheme. The remaining workspace contains only that project and is not needed for dependency integration.

### State ownership

ChooserAppModel is isolated to the main actor and adapts pure core snapshots into UI state:

- AppModeCore owns current mode and the saved launch default.
- TogetherChooserCore owns active touch identities and the idle, settling, countdown, and revealed phases.
- TapInChooserCore owns committed entries, the draw snapshot, and collecting, countdown, and revealed phases.
- Pinball setup and run state live in ChooserAppModel while all geometry and sampling remain pure value-oriented Swift.

Production timers use cancellable Swift concurrency tasks. Unit tests inject a manual scheduler and deterministic random sources, so timing and selection behavior can be verified without sleeping or relying on global randomness.

## Feedback and accessibility

Core Haptics is the preferred tactile path. UIKit feedback generators are the tactile fallback, and AVFoundation synthesizes short offline tones. The audio session uses the ambient category and mixes with other audio.

The interface includes:

- real controls with at least 44-point targets;
- Dynamic Type-friendly SwiftUI text and adaptive horizontal or vertical docks;
- VoiceOver labels, hints, announcements, result focus, and stable UI-test identifiers;
- accessible activation for the Together, Tap In, and Pinball entry surfaces;
- an accessible 2–12 seat-count menu for Pinball;
- Reduce Motion handling for mode artwork, countdown pulses, and Pinball flight;
- instructions and privacy disclosures available offline inside the app.

Color is never the only identity. Tap In and Pinball use visible numbers and winner text. Together identifies the winning physical ring and announces the result.

## Lifecycle, rotation, and privacy

When the scene becomes inactive:

- Together cancels the round and discards physical touches.
- Tap In discards pending touches; a countdown is canceled but committed entries remain.
- Pinball cancels any running or displayed path while preserving configured seats.
- all scheduled sound and haptic work stops.

Portrait and landscape are both supported. Together and Tap In lay out against the current SwiftUI geometry. Pinball stores seats in normalized coordinates so a collecting layout follows orientation. An active Pinball run is canceled if its playfield geometry changes, which prevents a trajectory created for one rectangle from being judged in another.

The app has no accounts, ads, analytics, tracking, purchases, or third-party runtime services. Finger locations, Tap In entries, seat positions, paths, and results are kept only in memory. The launch-default mode is the sole UserDefaults value, and its required-reason declaration appears in the privacy manifest. App Store Connect should continue to use Data Not Collected.

Public pages remain available at:

- Privacy: https://brianrenshaw.github.io/chooser-web-app/privacy.html
- Support: https://brianrenshaw.github.io/chooser-web-app/support.html
- Contact: contact@foliohtml.com

## Build and test operations

### Open and run

Open **ios/App/App.xcodeproj** in Xcode 26 or newer, select the shared App scheme, choose an iPhone or iPhone simulator, and run.

The target configuration is:

| Setting | Value |
|---|---|
| Bundle identifier | com.brianrenshaw.fingerchooser |
| Marketing version | 1.0 |
| Build | 4 |
| Minimum OS | iOS 18.0 |
| Device family | iPhone |
| Swift language mode | Swift 6 |
| Signing team | 2LZJMJR6V8 |

There is no npm, Capacitor, CocoaPods, or web-copy step in the native build.

### Command-line verification

Run from the repository root. Substitute an installed simulator name when necessary.

~~~bash
xcodebuild \
  -project ios/App/App.xcodeproj \
  -scheme App \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build-for-testing

xcodebuild \
  -project ios/App/App.xcodeproj \
  -scheme App \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO \
  test

xcodebuild \
  -project ios/App/App.xcodeproj \
  -scheme App \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO \
  build
~~~

The current suite contains 37 unit tests and 8 UI tests. Automated coverage includes:

- mode cycling and launch-default persistence;
- Together timing, late joins, removals, identity stability, lifecycle cancellation, and secure selection;
- Tap In gesture limits, numbering, maximum count, snapshot draws, replay, and lifecycle cancellation;
- exact Pinball equal-area partitions in portrait and landscape;
- the two-seat horizontal split;
- analytic reflections, final-point ownership, slowdown, and frame-rate-independent endpoints;
- deterministic statistical fairness checks;
- native launch, mode control, offline information flow, and rotation.

Simulator success does not replace physical-iPhone QA. True multitouch, Taptic Engine behavior, speaker output, interruptions, and sustained animation must be checked on hardware before submission.

### Archive and export build 4

The safest release workflow is Product → Archive in Xcode, followed by Validate App and Distribute App in Organizer.

The equivalent archive and local App Store export commands are:

~~~bash
xcodebuild \
  -project ios/App/App.xcodeproj \
  -scheme App \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ios/App/build/app-store/WhosFirst-1.0-build4.xcarchive \
  archive

xcodebuild \
  -exportArchive \
  -archivePath ios/App/build/app-store/WhosFirst-1.0-build4.xcarchive \
  -exportPath ios/App/build/app-store/export-build4 \
  -exportOptionsPlist ios/App/AppStoreExportOptions.plist
~~~

The build 4 archive is `ios/App/build/app-store/WhosFirst-1.0-build4.xcarchive`, and its distribution-signed IPA is `ios/App/build/app-store/export-build4/App.ipa`. App Store Connect accepted the upload, processed the package as VALID, and attached build 4 to draft version 1.0 in place of build 1. The version remains PREPARE_FOR_SUBMISSION; nothing has been submitted.

On August 30, 2026, build 3 passed App Store processing as VALID, but the final audit superseded it after removing an unused System Boot Time required-reason API call and polishing the compact controls. Before submitting the version for review, install build 4 through TestFlight, complete physical-iPhone QA, and inspect Organizer/App Store Connect for version 1.0, build 4, bundle identifier, signing team, iPhone-only support, and the embedded privacy manifest. Do not replace the attached build 4 with an earlier build.

## Physical-device release checklist

Test on at least one iPhone running iOS 18 or newer in portrait and landscape.

### Together

- 2, 3, 4, and 5 simultaneous fingers
- late finger during settling and countdown
- removal during settling and removal from 3 or more during countdown
- cancellation below two fingers
- ring movement, winner hold, and next-round behavior

### Tap In

- 2, 6, 20, and 50 entries
- one entry per completed gesture, movement, and cancellation
- Undo number reuse and Clear cancel/confirm
- disabled Pick below two and while a touch is pending
- Pick again with possible repeat winner and New group
- rotation, About, and backgrounding during collection and countdown

### Pinball

- 2, 3, 6, and 12 seats in both orientations
- obvious top-and-bottom two-seat layout
- repeated launches from unchanged seating
- path-wall alignment, actual endpoint ownership, and four winner flashes
- Rotate or background during a run and confirm the run cancels safely
- Reduce Motion and VoiceOver seat-count setup

### General

- native haptics and sound with normal, silent, and reduced-volume settings
- VoiceOver, larger Dynamic Type, Reduce Motion, and display zoom
- incoming interruption, lock and unlock, and foreground recovery
- Airplane Mode and an offline cold launch
- About, Help, Privacy, public links, and support email

## Legacy browser operations

### Run locally

~~~bash
python3 -m http.server 8765 --directory web
~~~

Open http://localhost:8765 on the Mac, or the Mac's LAN address on a phone. Together multi-touch still needs a touch device. The browser version uses web audio where iOS Safari cannot expose native haptics.

Static checks remain:

~~~bash
npm install
npm run check
npm audit
~~~

### Deploy GitHub Pages

The workflow at **.github/workflows/pages.yml** deploys only **web/**:

1. Push a change to **web/** or the workflow file on the main branch, or run the workflow manually.
2. GitHub Actions configures Pages, uploads **web/** as the artifact, and deploys it.
3. Verify https://brianrenshaw.github.io/chooser-web-app/ after the run finishes.

Management URLs:

- Actions: https://github.com/brianrenshaw/chooser-web-app/actions
- Pages settings: https://github.com/brianrenshaw/chooser-web-app/settings/pages
- Repository: https://github.com/brianrenshaw/chooser-web-app

Pages must remain in GitHub Actions mode because branch-based Pages cannot select **web/** as its source directory.

The web deploy does not build, sync, sign, or upload the iPhone app.

## Safe change boundaries

- Change native product behavior under **ios/App/App/Native/** and add or update tests with it.
- Change the browser product under **web/**.
- Never restore a Capacitor sync step or manually treat a cached **ios/App/App/public/** folder as production source.
- Keep secure selection and Pinball geometry in pure Swift types that deterministic tests can exercise.
- Keep UIKit limited to capabilities SwiftUI does not supply here, especially true simultaneous touch identity.
- Keep SpriteKit presentation-only. Pinball fairness must never depend on SKPhysicsWorld or frame callbacks.
- Increment the native build number before every App Store Connect upload.
- Update in-app help, the public support/privacy pages, store metadata, screenshots, and both project documents whenever shipped behavior changes.

## Repository history

| Date | Change |
|---|---|
| May 2026 | Created the framework-free Together web app, GitHub Pages deployment, PWA presentation, and an initial Capacitor iOS wrapper. |
| August 2026 | Prepared the App Store record, bundle identity, privacy/support pages, app icon, launch assets, signing, and the Together-only build 1 upload. |
| August 2026 | Added Tap In to the legacy web/Capacitor implementation and prepared build 2 locally. |
| August 30, 2026 | Replaced the production wrapper with an independent native SwiftUI app, added native Together and Tap In plus fair analytic Pinball, raised the minimum to iOS 18, enabled Swift 6 strict concurrency, added native unit/UI tests, and advanced the project to build 3. The legacy two-mode browser app remains separately deployed. |
| August 30, 2026 | Build 3 processed as VALID in App Store Connect, then was superseded by build 4 after the final audit removed an unused System Boot Time required-reason API call and polished the compact controls. Build 4 processed as VALID and replaced build 1 on draft version 1.0; metadata, App Review notes, and six screenshots were applied and verified. The version remains PREPARE_FOR_SUBMISSION. |

For current release blockers and App Store Connect handoff, see [App Store readiness](app-store-readiness.md).
