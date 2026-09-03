# Who's First?

Who's First? is a private, offline iPhone app that answers one question: who goes first?

The native app has three ways to choose:

- **Chooser** — two or more people hold one finger on the screen at once. After a tactilely silent 1.0-second settling window, a 2.75-second six-beat anticipation arc leaves deliberate headroom before one active finger wins.
- **Tap In** — 2–50 people join one numbered tap at a time, then choose from the completed group.
- **Pinball** — 2–12 people tap nearest their seats around a flat iPhone, then directly flick the ball. Exact equal-area divider rays make ownership clear; the ball begins at the clamped release point and follows the flick. If its natural reflected path does not reach the fairly selected seat, the first wall visibly flexes once to preserve equal odds. The visible endpoint owns the result.

`Chooser` is the current user-facing name for the simultaneous-finger mode. Some source identifiers and older release history retain `Together` as a legacy implementation term.

The custom board now sits edge to edge beneath a native iOS 26 navigation toolbar. Its leading mode `Menu` and trailing Settings `Button` receive the system Liquid Glass treatment and system placement instead of imitating glass inside the playfield. Both are semantic 44-point controls with labels, hints, and disabled states. The mode menu opens Chooser, Tap In, or Pinball directly; safe changes happen immediately and clear the current group, while switching is disabled during an active resolution. The same menu can make the current mode the launch default. Three App Shortcuts—Open Chooser, Open Tap In, and Open Pinball—and their `whosfirst://mode/...` deep links open a session directly without overwriting that saved default.

Submitted Build 18 retains Build 17's direct-manipulation Pinball, native toolbar, accessibility adaptations, eight box-led visual worlds, tactile Chooser hierarchy, and broad textured participant-hue pieces. A simultaneous three-finger tap anywhere in the native app now changes to a different randomly selected visual world and saves that selection. The shortcut is available only in safe idle, collecting, and result states; it never adds a participant, interrupts a choice, or clears the current group. VoiceOver users receive an equivalent **Shuffle colors** action because iOS reserves three-finger gestures while VoiceOver is running. Reduce Transparency simplifies decorative layering, Increase Contrast strengthens structural edges and dividers, Differentiate Without Color adds patterned winner cues, and Reduce Motion removes nonessential transitions while preserving the selected result. Custom UIKit touch surfaces expose semantic accessibility actions; decorative drawing is hidden from assistive technology; Dynamic Type can reflow the Settings picker to one column. The Settings **Information** section contains About, **Show Welcome Again**, the **How It Works** guide, Privacy, and Contact Support.

Build 19 / version 1.1 adds a first-run introduction. On the first launch a three-page swipe carousel introduces Chooser, Tap In, and Pinball using the same copy deck as **How It Works**, with living board artwork rather than symbols. Finishing or skipping it also retires the introduction card for the mode on screen, so the board is never covered by a second modal; the other two modes each get a one-time card the first time they are actually opened, dismissed by its close button or by the first touch on the board. **Show Welcome Again** in Settings replays the carousel only and never restores the per-mode cards. Anyone updating from 1.0 sees the carousel once. A `whosfirst://` App Shortcut arriving during the carousel is honoured underneath it rather than dropped.

The Home Screen icon is a brand-neutral, flat **Five Seats, One Table** mark: five equal player spots surround a two-plane circular table and a neutral chooser puck. Stable Icon Composer 1.6 exports the layered source as Default, Dark, Clear Light, Clear Dark, and Tinted Dark appearances without realistic texture, bevels, baked shadows, text, third-party logos, or game artwork.

Pinball begins with a wordless flick demonstration once a new group reaches two seats. When the live gesture crosses the flick thresholds, the 30-point ball appears under the finger and follows it without an animation handoff. Release is clamped only enough to keep the complete ball inside its collision bounds; that exact point and the committed flick vector become the analytic path's visible first vertex and first leg. Only after those player-controlled values are committed does secure randomness select one seat with exactly `1/N` probability. The app first computes the ordinary reflected path. If that endpoint already belongs to the selected seat, the whole run remains natural. If it does not, a localized theme-colored section of the first wall visibly flexes and rebounds once while redirecting the outgoing path toward the selected region; a distinct springy haptic accompanies that visible intervention. There is no text overlay, hidden spawn, or later steering. Every later bounce is an ordinary specular reflection, and the final visible endpoint remains the sole owner of the result.

Result taps remain equally spare: a new Chooser touch starts the next round, a Tap In background tap dismisses the result while preserving its player pool, and a Pinball background tap preserves the seats and readies another flick. Chooser keeps its tactilely silent 1.0-second settling window, then runs a 2.75-second physical anticipation arc with six synchronized beats at 0.24, 0.78, 1.28, 1.72, 2.10, and 2.43 seconds. The final anticipation strength is intentionally capped at 0.74, leaving 320 milliseconds of tactile headroom before the distinct result. Core Haptics playback starts before the visual winner clock is anchored, and tactile contact lands at the visual keyframe's exact maximum compression 0.082 seconds later. The winner completes a 0.82-second visual landing with a 0.78-second low-sharpness body. Pinball has its own compression-synchronized settle cue, with analytic wall impacts retained. The Chooser winner has no synthesized audio tone.

## Native iPhone app

The production target is a native iOS 26 application:

- SwiftUI shell using Observation
- UIKit UIViewRepresentable surfaces for true simultaneous multitouch and deliberate Pinball tap/flick input
- pure Swift state machines, secure randomness, and Pinball geometry
- SpriteKit for deterministic path presentation only—no SpriteKit physics
- Core Haptics with UIKit fallbacks
- AVFoundation-generated offline audio fallback, used quietly when Core Haptics is unavailable on supported physical devices; simulator startup is capability-gated and never starts AVAudioEngine
- VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate Without Color, portrait, and landscape support
- App Intents for three App Shortcuts, backed by local `whosfirst://` mode deep links
- a layered Icon Composer app icon with Default, Dark, Clear Light, Clear Dark, and Tinted Dark appearances

The App Store identity remains:

- Bundle ID: com.brianrenshaw.fingerchooser
- Version: 1.1
- Current local native build: 19
- Device family: iPhone
- Minimum OS: iOS 26

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

The project includes AppTests and AppUITests. As historical checkpoints, Build 11 passed 96 AppTests and 15 unique AppUITests (18 executions); Build 12 passed 112 AppTests and the same complete UI run; Build 13 passed 118 AppTests before Build 14 superseded it; Build 14 passed all 121 AppTests and all 15 unique AppUITests (18 executions, zero failed or skipped); and Build 15 passed all 133 AppTests and all 16 unique AppUITests (19 executions, zero failed or skipped), plus its accessibility, static, build, signing, installation, and launch checks. Final Build 16 passed all 146 AppTests plus its static, simulator, device, signing, installation, and launch checks. Its final UI attempt completed 10 executions before simulator infrastructure stalled, and hands-on review then exposed the hidden-spawn Pinball disconnect that Build 17 replaced. Final post-refinement Build 17 passed all 158 AppTests, its conditional integrated set `89/89`, the focused wordless wall-flex checks `4/4`, and all 19 AppUITest executions with zero failures or skips; its Release simulator and signed arm64 device builds, strict signature verification, and BDR 17 installation/launch also passed. Final Build 18 passes all 167 AppTests (`/tmp/whos-first-build18-final-tests/Logs/Test/Test-App-2026.08.31_13-40-17--0400.xcresult`) and all 20 AppUITest executions with zero failures or skips (`17 unique methods`: one launch method across four variants plus 16 regular; `/tmp/whos-first-build18-shuffle-ui/Logs/Test/Test-App-2026.08.31_13-52-01--0400.xcresult`). Stable Icon Composer 1.6 export, the Release simulator build, the development-signed arm64 Release build, and strict/deep signature verification pass. Version 1.0 (18) installed and launched successfully on BDR 17, `devicectl` confirmed its bundle/version/build identity, and the owner physically approved the installed candidate. Build 19 / version 1.1 adds the first-run introduction and passes all 193 AppTests and all 25 AppUITest executions (`22 unique methods`) with zero failures or skips (`/Users/brianrenshaw/Library/Developer/Xcode/DerivedData/App-arucxfworlyzbcdxpfblzlzkvsnd/Logs/Test/Test-App-2026.09.03_08-09-36--0400.xcresult`); its device install, signing, and hands-on review remain to be run.

## Web checks

~~~bash
npm install
npm run check
npm audit
~~~

## Release status

Build 18 / version 1.0 (18) is the submitted iOS 26, iPhone-only release. Its 167 AppTests, all 20 AppUITest executions, stable Icon Composer export, Release simulator and device builds, strict/deep signature verification, BDR 17 installation/launch, identity check, and owner physical review pass. The archive, export, and App Store Connect upload succeeded; delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` processed as `VALID` and Build 18 replaced Build 4 on version 1.0. The approved Build 18 description, promotional text, review notes, contact, and six 1320×2868 screenshots are applied. App Privacy is published as Data Not Collected, Free price `0.0` is confirmed, DSA non-trader status is active for all 27 EU territories, and non-exempt encryption is false. TestFlight was intentionally skipped because it is optional.

Review submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` was submitted on August 31, 2026 at `18:38:05.116Z`. Both version 1.0 and the review submission are `WAITING_FOR_REVIEW`; the release setting remains `AFTER_APPROVAL`. The remaining work is to monitor App Store Connect and respond if App Review requests information or changes.

Local release artifacts are under `ios/App/build/app-store/` (ignored by Git), including the historical Build 4 archive/export and the submitted Build 18 archive/export.

See [App Store readiness](docs/app-store-readiness.md) and the [implementation/process document](docs/finger-chooser-web-app-process-doc.md).
