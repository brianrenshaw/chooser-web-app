# Who's First?

Who's First? is a private, offline iPhone app that answers one question: who goes first?

The native app has three ways to choose:

- **Chooser** — two or more people hold one finger on the screen at once. After a 0.35-second settling window, a 1.65-second six-beat anticipation arc selects one active finger: approximately two seconds after the last join, with the first buildup tap at 0.45 seconds.
- **Tap In** — 2–50 people join one numbered tap at a time, then choose from the completed group.
- **Pinball** — 2–12 people tap nearest their seats around a flat iPhone, then directly flick the ball. Exact equal-area divider rays make ownership clear; the ball begins at the clamped release point and follows the flick. If its natural reflected path does not reach the fairly selected seat, the first wall visibly flexes once to preserve equal odds. The visible endpoint owns the result.

`Chooser` is the current user-facing name for the simultaneous-finger mode. Some source identifiers and older release history retain `Together` as a legacy implementation term.

The custom board now sits edge to edge beneath a native iOS 26 navigation toolbar. Its leading mode `Menu` and trailing Settings `Button` receive the system Liquid Glass treatment and system placement instead of imitating glass inside the playfield. Both are semantic 44-point controls with labels, hints, and disabled states. The mode menu opens Chooser, Tap In, or Pinball directly; safe changes happen immediately and clear the current group, while switching is disabled during an active resolution. The same menu can make the current mode the launch default. Three App Shortcuts—Open Chooser, Open Tap In, and Open Pinball—and their `whosfirst://mode/...` deep links open a session directly without overwriting that saved default.

Submitted Build 18 retains Build 17's direct-manipulation Pinball, native toolbar, accessibility adaptations, eight box-led visual worlds, tactile Chooser hierarchy, and broad textured participant-hue pieces. A simultaneous three-finger tap anywhere in the native app now changes to a different randomly selected visual world and saves that selection. The shortcut is available only in safe idle, collecting, and result states; it never adds a participant, interrupts a choice, or clears the current group. VoiceOver users receive an equivalent **Shuffle colors** action because iOS reserves three-finger gestures while VoiceOver is running. Reduce Transparency simplifies decorative layering, Increase Contrast strengthens structural edges and dividers, Differentiate Without Color adds patterned winner cues, and Reduce Motion removes nonessential transitions while preserving the selected result. Custom UIKit touch surfaces expose semantic accessibility actions; decorative drawing is hidden from assistive technology; Dynamic Type can reflow the Settings picker to one column. The Settings **Information** section contains About, **Show Welcome Again**, the **How It Works** guide, Privacy, and Contact Support.

Build 19 / version 1.1 adds a first-run introduction. On the first launch a three-page swipe carousel introduces Chooser, Tap In, and Pinball using the same copy deck as **How It Works**, with living board artwork rather than symbols. Finishing or skipping it also retires the introduction card for the mode on screen, so the board is never covered by a second modal; the other two modes each get a one-time card the first time they are actually opened, dismissed by its close button or by the first touch on the board. **Show Welcome Again** in Settings replays the carousel only and never restores the per-mode cards. Anyone updating from 1.0 sees the carousel once. A `whosfirst://` App Shortcut arriving during the carousel is honoured underneath it rather than dropped.

The Home Screen icon is a brand-neutral, flat **Five Seats, One Table** mark: five equal player spots surround a two-plane circular table and a neutral chooser puck. Stable Icon Composer 1.6 exports the layered source as Default, Dark, Clear Light, Clear Dark, and Tinted Dark appearances without realistic texture, bevels, baked shadows, text, third-party logos, or game artwork.

Pinball begins with a wordless flick demonstration once a new group reaches two seats. When the live gesture crosses the flick thresholds, the 30-point ball appears under the finger and follows it without an animation handoff. Release is clamped only enough to keep the complete ball inside its collision bounds; that exact point and the committed flick vector become the analytic path's visible first vertex and first leg. Only after those player-controlled values are committed does secure randomness select one seat with exactly `1/N` probability. The app first computes the ordinary reflected path. If that endpoint already belongs to the selected seat, the whole run remains natural. If it does not, a localized theme-colored section of the first wall visibly flexes and rebounds once while redirecting the outgoing path toward the selected region; a distinct springy haptic accompanies that visible intervention. There is no text overlay, hidden spawn, or later steering. Every later bounce is an ordinary specular reflection, and the final visible endpoint remains the sole owner of the result.

Result taps remain equally spare: a new Chooser touch starts the next round, a Tap In background tap dismisses the result while preserving its player pool, and a Pinball background tap preserves the seats and readies another flick. Chooser now uses a 0.35-second settling window and a 1.65-second anticipation arc with six synchronized beats at 0.10, 0.44, 0.74, 1.00, 1.22, and 1.41 seconds. Beat intensity rises from 0.75 to 0.98 and sharpness from 0.60 to 0.90, leaving 240 milliseconds before reveal. Core Haptics playback starts before the visual winner clock is anchored, and tactile contact lands at maximum compression 0.082 seconds later. The winner retains its 0.82-second visual landing with a full-intensity, 1.0-sharpness impact and a sustained 0.65-second body. Participant joins, Tap In's one-second buildup, and energy-sensitive Pinball launch, wall, bumper, and settle feedback are stronger, with corresponding UIKit fallbacks. Routine navigation and audio policy are unchanged; the Chooser winner has no synthesized audio tone. Physical review confirmed the faster pacing and preferred this firm 0.65-second finish over a longer rolling pattern. Device logs confirm Core Haptics delivery for joins, buildup, and winner cues. These changes are submitted as version 1.2 (20).

Version 1.3 (21), submitted for App Review on October 2, 2026: three more box-led worlds bring the total to eleven. **Res Arcana** is a candlelit grimoire (oxblood leather with blind tooling, pressed wax-seal pieces, stitched-seam Pinball dividers and a garnet ball). **Everdell Emerland** is a sunlit jungle valley (dark canopy edges, a turquoise river, painted-wood pieces, rope dividers and a cut-emerald ball). **Sagrada** is a cathedral window at dusk (leaded glass shards around a rose window in a stone frame, lit-glass pieces with lead rims, stone-mullion dividers and a clear glass ball). The original eight are deepened from their boxes and components: Wingspan Original gets wet-edged watercolor washes, speckled egg pieces, pencil dividers and a robin's-egg ball; Wingspan Asia becomes red lacquer with a peacock eye-spot and a cream piece in place of navy; Wingspan Americas becomes a rainforest clearing with iridescent pieces and ruby in place of dark green; Nidavellir becomes slate and forge with stamped coins in the five dwarf class colors and gold-inlay dividers; Concordia is drawn from its map board with province-wash pieces, dotted land-route dividers and a Roman coin; Everdell moves to honey and autumn with resin pieces, twig dividers and a berry ball, leaving green to Emerland; Lizard Wizard becomes plum with an amber glow, mana-coin pieces and an eye-of-newt ball, leaving dark red to Res Arcana; Leaders gains gold-ink inlay, split black-and-white rims and spot gloss. Shared engine hooks support this: a per-world divider style, ball ornaments drawn identically by SpriteKit and SwiftUI, per-finish piece overlays, and an optional per-world destructive fill (Res Arcana's Clear is bone, since every piece there is red). A successful shuffle flashes the new world's name for about a second, and after a person's fifth finished choice a one-time card teaches the three-finger shuffle (VoiceOver users are pointed to the Shuffle colors action). The card is retired by trying the shuffle, touching the board, its close button, or changing mode, and the finished-choice count stops being written once it has been seen.

Version 1.4 (22), submitted for App Review on October 16, 2026: every world now carries its subject as an original abstract drawing on the board, under the pieces, after feedback that color and texture alone were not enough. Wingspan Original gets a field-guide plate (a perched songbird, birds on the wing, feathers, a nest); Wingspan Asia a peacock's fanned tail; Wingspan Americas hummingbirds at trumpet blooms; Nidavellir a rune-carved hall gate with a shield and crossed axes over an anvil and sparks; Concordia laurel, an aqueduct, a trireme and city houses on the map; Everdell the great tree with lanterns and a cottage in its roots; Lizard Wizard a gecko in a wizard's hat under a crescent moon beside a cauldron; Leaders standee figures on a gold-inlaid hex board; Res Arcana alchemical element glyphs at the pentagon's nodes, an orb and a candle; Everdell Emerland a toucan, a capybara, a frog and butterflies; Sagrada the basilica's spires below the window and a dove. Three new worlds join them: **Wyrmspan** (the cover dragon with veined wings and a coiled scaled body over paper and teal washes, speckled egg pieces, a jade egg ball), **Harmonies** (a meadow built from the game's wooden tokens, with trees, mountains, a river, a fox and cranes under a lion-sun; lacquered token pieces and an amber bead) and **Finspan** (the ocean mat's three zones from sunlight to midnight with a flying fish, a shoal, a manta and a shark; bubble bead pieces and a foam bubble ball). The subject layer sits between a world's atmosphere and its grain, steps back under Reduce Transparency, and is drawn by `BoardSubjectArtView` from one recipe file per world under `Native/UI/SubjectArt/`; `BoardSubjectArtRenderTests` writes every world to PNG so the drawings can be looked at. A new toolbar button opens a quick world picker: a full-height sheet of labeled board tiles, where one tap applies that world and closes the sheet. Settings keeps its fuller grid. Apple approved 1.4 on October 17, 2026.

Version 1.4.1 (23), submitted October 17, 2026: the picker's first cut applied a world but stayed open at half height so the board could be watched changing behind it; one tap is what was expected, so a tile tap now applies the world and closes the sheet, which opens at full height.

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
- Version: 1.2
- Current local native build: 20
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

Version **1.2 (20)** was submitted September 7, 2026 and is **WAITING_FOR_REVIEW**. Its release notes are exactly **“Improved timing and haptic feedback”**. Build 20 passed Release archive/export, strict signature verification, Apple validation, upload, and processing (`VALID`). Submission `99729250-1463-40c8-8e83-ba09db8f9b1d` uses automatic release after approval. Version 1.1 remains live during review. See [App Store readiness](docs/app-store-readiness.md) for identifiers and validation evidence.

### Historical 1.0 submission

Build 18 / version 1.0 (18) is the submitted iOS 26, iPhone-only release. Its 167 AppTests, all 20 AppUITest executions, stable Icon Composer export, Release simulator and device builds, strict/deep signature verification, BDR 17 installation/launch, identity check, and owner physical review pass. The archive, export, and App Store Connect upload succeeded; delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` processed as `VALID` and Build 18 replaced Build 4 on version 1.0. The approved Build 18 description, promotional text, review notes, contact, and six 1320×2868 screenshots are applied. App Privacy is published as Data Not Collected, Free price `0.0` is confirmed, DSA non-trader status is active for all 27 EU territories, and non-exempt encryption is false. TestFlight was intentionally skipped because it is optional.

Review submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` was submitted on August 31, 2026 at `18:38:05.116Z`. Both version 1.0 and the review submission are `WAITING_FOR_REVIEW`; the release setting remains `AFTER_APPROVAL`. The remaining work is to monitor App Store Connect and respond if App Review requests information or changes.

Local release artifacts are under `ios/App/build/app-store/` (ignored by Git), including the historical Build 4 archive/export and the submitted Build 18 archive/export.

See [App Store readiness](docs/app-store-readiness.md) and the [implementation/process document](docs/finger-chooser-web-app-process-doc.md).
