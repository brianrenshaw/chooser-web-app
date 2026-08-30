# Who's First?

Who's First? is a private, offline iPhone app that answers one question: who goes first?

The native app has three ways to choose:

- **Together** — two or more people hold one finger on the screen at once. After a 1.5-second settling window and a one-second accelerating countdown, one active finger wins.
- **Tap In** — 2–50 people join one numbered tap at a time, then choose from the completed group.
- **Pinball** — 2–12 people tap nearest their seats around a flat iPhone. The app creates mathematically equal-area regions, replays an analytic bouncing path, and the region containing the ball's real endpoint wins.

The upper-left mode icon cycles through all three experiences. A long press makes the current mode the launch default. Only that preference is saved; fingers, players, seats, paths, and results remain in memory and are discarded when the app closes.

## Native iPhone app

The production target is a native iOS 18 application:

- SwiftUI shell using Observation
- UIKit UIViewRepresentable surface for true simultaneous multitouch
- pure Swift state machines, secure randomness, and Pinball geometry
- SpriteKit for deterministic path presentation only—no SpriteKit physics
- Core Haptics with UIKit fallbacks
- AVFoundation-generated offline sound
- VoiceOver, Dynamic Type, Reduce Motion, portrait, and landscape support

The App Store identity remains:

- Bundle ID: com.brianrenshaw.fingerchooser
- Version: 1.0
- Current native build: 4
- Device family: iPhone
- Minimum OS: iOS 18

Capacitor, CocoaPods, the bridge storyboard, and the embedded web bundle have been removed from the production target.

## Legacy browser app

The framework-free two-mode browser chooser remains in [web/](web/) and is deployed separately at [brianrenshaw.github.io/chooser-web-app](https://brianrenshaw.github.io/chooser-web-app/).

It is intentionally a legacy browser version, not the implementation source for the native app. Pinball and future native features do not need to be duplicated there.

Run it locally:

~~~bash
python3 -m http.server 8765 --directory web
~~~

Then open http://localhost:8765.

## Build and test iOS

Open [ios/App/App.xcodeproj](ios/App/App.xcodeproj) in Xcode 26 or newer, select an iPhone or simulator, and run the shared App scheme.

Command-line checks:

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
~~~

The project includes AppTests and AppUITests. The current suite has 37 unit tests and 8 UI tests covering mode persistence, Together timing and touch identity, Tap In limits and replay, unbiased random indexes, equal-area Pinball geometry, analytic reflections, slowdown, frame-rate-independent endpoints, statistical fairness, lifecycle cancellation, Reduce Motion, feedback fallback, long-press default behavior, native information screens, and rotation.

## Web checks

~~~bash
npm install
npm run check
npm audit
~~~

## Release status

The native build 4 implementation, automated simulator coverage, signed archive, exported IPA, and App Store Connect upload are complete. Build 4 processed as VALID and is attached to the draft version 1.0, replacing build 1. The version remains PREPARE_FOR_SUBMISSION, and nothing has been submitted. The Pinball-inclusive metadata, App Review notes, and all six screenshots are applied and verified in App Store Connect. Build 3 also processed as VALID, but it was superseded after the final audit removed an unused System Boot Time required-reason API call and polished the compact controls. The remaining release steps are:

1. physical-iPhone QA for multitouch, haptics, sound, silent mode, VoiceOver, Reduce Motion, interruptions, rotation, and sustained Pinball animation;
2. final owner review and explicit **Submit for Review** approval.

Local release artifacts are under `ios/App/build/app-store/` (ignored by Git), including `WhosFirst-1.0-build4.xcarchive` and the distribution-signed `export-build4/App.ipa`.

See [App Store readiness](docs/app-store-readiness.md) and the [implementation/process document](docs/finger-chooser-web-app-process-doc.md).
