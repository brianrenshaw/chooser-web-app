# Who's First? Native App and Legacy Web Process

Last updated: August 31, 2026

## Product scope

Who's First? answers one narrow question: who goes first?

The production iPhone app has three modes:

- **Chooser** — two or more people hold one finger on the screen at the same time.
- **Tap In** — 2–50 people join a numbered pool one completed tap at a time.
- **Pinball** — 2–12 people tap nearest their seats around a flat iPhone, then one person directly flicks a ball. The exact clamped release point and first leg remain player-controlled. If the natural path misses the fairly selected seat, a localized first-wall flex visibly preserves equal odds; the endpoint owns the result.

The app does not score games, maintain player profiles, store history, or manage brackets. Its interaction data is temporary and every choice happens on the device.

## Two independent deliverables

The repository now contains two separate products. They share branding and public support URLs, but they do not share runtime code.

| Deliverable | Source of truth | Distribution | Modes |
|---|---|---|---|
| Native iPhone app | **ios/App/App/Native/** and the Xcode project | App Store and TestFlight | Chooser, Tap In, Pinball |
| Legacy browser app | **web/** | GitHub Pages and Add to Home Screen | Together, Tap In |

The App Store app is a native SwiftUI application. It no longer embeds the browser app and does not use Capacitor, CocoaPods, WebKit, a bridge storyboard, or a generated public directory.

The legacy browser app remains useful and deployable, but changes under **web/** do not appear in the native app. There is no sync step between the products. Pinball and future native features do not need to be duplicated on the web.

The browser version still begins in Together on every fresh launch, cycles only between Together and Tap In, uses Pointer Events and Web Crypto, and falls back to Web Audio where iOS Safari cannot provide haptics. The native saved-default behavior and Pinball mode do not apply to it.

## Native product behavior

### Mode control

Build 18 retains the custom edge-to-edge board inside a native `NavigationStack`. A standard SwiftUI `Menu` in the leading toolbar position and a standard `Button` in the trailing position receive system Liquid Glass, placement, interaction, and appearance behavior automatically; the custom playfield does not draw or imitate navigation glass. Both controls keep 44-point targets, semantic labels and hints, and accurate disabled states; the mode menu also reports the current mode as its accessibility value. The menu opens Chooser, Tap In, and Pinball directly. Choosing a mode changes only the current session; a separate menu command stores the current mode as the next-launch default. A first install falls back to Chooser. The one-time launch-default migration v2 also resets an upgrade to Chooser once. After migration version 2 is recorded, any later explicit default selection persists normally.

Selecting another mode in any safe setup, collecting, or result state changes immediately and clears the current mode's transient group without confirmation. Chooser can switch while one finger is visible, while several fingers are settling, or after a result; Tap In can switch while a provisional touch is down or after a result; Pinball can switch after its result. Mode changes are disabled only during an actual Chooser/Tap In countdown or while Pinball is running or actively revealing. Confirmation remains reserved for explicit Clear actions.

### App Shortcuts and deep links

`WhosFirstAppShortcuts` publishes three App Intents: Open Chooser, Open Tap In, and Open Pinball. Each opens one stable local URL:

| Shortcut | Deep link |
|---|---|
| Open Chooser | `whosfirst://mode/chooser` |
| Open Tap In | `whosfirst://mode/tap-in` |
| Open Pinball | `whosfirst://mode/pinball` |

The `whosfirst` scheme is registered in `Info.plist`; `ChooserRootView.onOpenURL` validates the scheme, host, and mode path before requesting a normal session-mode change. A shortcut or external deep link never writes the saved launch default. Invalid or unrelated URLs are ignored, and no participant or result state is encoded in a mode URL.

### Settings and visual worlds

The trailing toolbar Settings button uses a gear symbol and opens a native sheet. Its visual picker offers eight complete local worlds—Wingspan Original, Wingspan Americas, Wingspan Asia, Nidavellir, Concordia, Everdell, Lizard Wizard, and Leaders. Each preview combines the actual layered surface, ink, chrome tint, broad ring, numbered chits, accent control, and Pinball material used throughout the selected world. The picker adapts between portrait and landscape, uses a single column at accessibility Dynamic Type sizes, and permits two-line style names rather than shrinking them into unreadability.

The visual-theme model controls a multi-layer surface recipe and deterministic 2–4% procedural texture, preferred light or dark control appearance, separate surface and chrome inks, chrome tint, action and detail accents, participant swatches, material-specific piece finish, divider treatment, and Pinball face, edge, tail, and impact roles. Theme changes crossfade without clearing the current group; Reduce Motion applies them immediately. Legacy raw value `wingspan-hummingbirds` now displays Wingspan Americas, `wingspan-nectar` displays Wingspan Asia, and unknown values fall back to Wingspan Original.

Build 18 adds an app-wide simultaneous three-finger tap for shuffling colors. A single window-level direct-touch recognizer chooses uniformly from the seven visual worlds other than the current one, routes the change through the existing selection/persistence path, and preserves the current mode, committed group, and displayed result. It accepts only a quick stationary three-finger tap in a safe idle, collecting-without-provisional-input, or result state. Confirmation presentation, theme transitions, active touches, countdowns, reveals, Pinball flight, settling feedback, and inactive scenes ignore the command without queuing it. A held or moving three-finger gesture fails recognition and continues as ordinary input; recognition cancels provisional gameplay touches before they can commit an entry or seat. VoiceOver keeps its reserved system gestures and exposes the same behavior through a **Shuffle colors** accessibility action. No toast or playfield instruction is added; How It Works says, “Three-finger tap anywhere to shuffle the colors.”

Settings also provides an **Information** section with native disclosure rows for About Who's First?, How It Works, and Privacy, plus Contact Support. Opening Settings preserves committed Tap In entries and configured Pinball seats whenever presentation is safe. The toolbar Settings button is visibly and semantically disabled while an active choice cannot be interrupted.

The saved launch mode and selected visual-world raw value are the only user-selected app preferences persisted. Both use local UserDefaults. Theme shuffling updates that existing selected-world value and introduces no additional stored field. A nonpersonal migration-version marker records that the one-time Chooser-default reset at migration version 2 has run. Build 19 adds one further nonpersonal record, `chooser.onboarding`, listing which one-time introduction screens have been retired, gated by `chooser.onboarding.version` so a later release can reintroduce them; unlike the launch-default store, its load is a pure read that never writes. None of these values includes participant identity, group state, history, or results.

### Chooser

Chooser deliberately preserves the original simultaneous-finger behavior:

1. One finger produces a colored ring but no visible coaching sentence; the fuller explanation remains available to assistive technology and in How It Works.
2. Two or more active fingers begin a 1.0-second settling window.
3. A new finger or a removal during settling restarts that window while at least two remain.
4. The app runs one 2.75-second choice ritual in which six escalating Core Haptics beats and six physical ring reactions share one exact timeline at 0.24, 0.78, 1.28, 1.72, 2.10, and 2.43 seconds.
5. One of the active touch identities is chosen uniformly.

A late finger during the countdown returns the round to settling. Removing one of three or more fingers during the countdown does not restart it; the eventual choice uses only the identities still down. Dropping below two cancels the round.

The winning ring remains visible after fingers lift. The next new touch dismisses the result and begins a new round.

True simultaneous input comes from a small UIKit surface with multiple touch enabled. Each UITouch receives a stable native identity for its lifetime. SwiftUI draws the rings and surrounding interface.

Build 17 retains the larger 158–176-point portrait and 144–158-point landscape rings with no visible status dock or coaching prose. Each hollow marker is authored from the selected visual world: its band is `clamp(diameter × 0.125, 18, 22)` points with participant-hue tinted inner and outer rims, same-hue relief, material-specific procedural grain, tinted occlusion, and deeper contact and cast shadows. During choosing, the rings react across six synchronized beats over 2.75 seconds. Anticipation intensity rises only to 0.74 and ends 320 milliseconds before the winner cue, preserving tactile headroom instead of exhausting the available dynamic range. Core Haptics playback begins before the visual clock anchor is captured; the winner transient is offset 0.082 seconds so tactile contact coincides with the visual keyframe's exact maximum compression. The full result combines a 0.82-second physical visual landing with a distinct 0.78-second low-sharpness winner body. The hole exposes the selected board surface. There is no hard black keyline, shared white crescent, diagonal gloss, neon glow, bloom, or idle pulse. The winning ring supplies the visible result without an additional winner sentence; complete result wording remains available to VoiceOver.

### Tap In

Tap In is the sequential alternative for larger groups:

- A touch-down creates a provisional numbered board-game chit at the physical location.
- Movement updates that provisional token but never creates another entry.
- Touch-up commits exactly one entry.
- Cancellation discards the provisional token.
- Committed entries settle into a deterministic centered grid.
- Tokens begin at a preferred 156 points through five entries, then shrink by `156 × sqrt(5 / count)` to a preferred 48-point floor and reflow as the count grows, up to 50.
- Undo removes only the newest entry and allows its number to be reused.
- Clear requires confirmation.
- Pick is enabled only with at least two committed entries and no pending touch.

Pick snapshots the committed array, runs the one-second countdown, and chooses one entry from that frozen array. Try Again starts an independent choice from the unchanged pool, so repeat winners are allowed. A background tap on the result dismisses the winner emphasis and returns to collecting without changing the pool; another draw still requires an explicit Pick. New group clears the pool while remaining in Tap In.

The entry array, not the visible view hierarchy, is the source of truth.

### Pinball

Pinball combines direct physical manipulation with an exact equal-probability result:

1. Put the iPhone flat and add 2–12 numbered seats near the participants' physical seats.
2. The app assigns every seat an equal-area radial region in clockwise seat order. Thin center-to-edge rays expose those exact boundaries without an outer arena outline or filled territories.
3. When a new group first reaches two seats, a two-pass wordless fingertip-and-streak cue demonstrates that the playfield is ready for a flick without consuming randomness.
4. A weighted linear regression over the final 120 milliseconds of coalesced touch samples resolves the live gesture. Duplicate release samples up to 45 milliseconds are ignored, and a drag stopped more than 80 milliseconds before release does not launch.
5. As soon as the gesture crosses the committed flick thresholds, the 30-point physical ball appears under the finger and follows its current position without an animation handoff. The center is clamped only to the collision-safe playfield.
6. On release, that exact clamped center becomes the analytic launch origin and the committed velocity vector becomes the exact first-leg direction. These player-controlled values are fixed before randomness is consumed.
7. An unbiased secure index then selects one of the N equal-area regions, giving every seat probability exactly `1/N`. A varied target is sampled inside the already-selected region.
8. The app first evaluates the ordinary specular path from that committed launch. If its endpoint already belongs to the selected region, the result uses that path unchanged and consumes no fairness intervention.
9. Otherwise, at the first contact one inverse-specular construction chooses an outgoing suffix whose genuine endpoint lies inside the selected region. A localized theme-colored section of that wall visibly curves, compresses, and rebounds with a distinct springy haptic. It uses no text label.
10. Every later wall event is an ordinary specular reflection. There is no hidden spawn and no later steering.
11. The existing strength-dependent distance, launch energy, high-inertia motion profile, rolling material fleck, collision-reset tail, and same-ball endpoint settle present the analytic path. The final point lies inside the selected region, and its two boundary rays receive the result emphasis.

The direct first leg makes the ball a literal continuation of the player's finger. The ordinary path remains untouched whenever it already matches the unbiased region draw. Only a mismatch uses the one visible first-wall flex, rather than silently relocating the ball. The analytic endpoint remains the displayed owner of the result.

SpriteKit presents the precomputed path only. The scene derives immutable impact vertices from the analytic polyline, and when its rendered progress crosses one of those vertices it draws the localized edge mark, squashes/rebounds the ball, and reports the vertex index, analytic progress, current speed fraction, wall-normal impulse fraction, corner state, and whether a fairness deflector is active in that same rendered frame. `ChooserAppModel` accepts only the expected event for the active run, removes it before delivery so duplicate or rebuilt frames are inert, and plays the eligible cue then. When required, the first-wall intervention uses a localized theme-colored curve/flex/rebound and a distinct springy feedback signature, never a label or explanatory overlay. Natural matching rounds use an ordinary first-wall impact. Later direct high-speed impacts remain more tactile than grazing or slower contacts. Analytically coalesced ordinary events remain filtered so closely spaced impacts do not overload the Taptic Engine. The visual replay uses the same theme-specific 30-point physical ball that was under the finger, a distance/radius-driven rolling material fleck, and an energy- and velocity-scaled tail that resets at each collision; it never draws the completed route.

The moving-flight result reveal is also owned by the rendered clock. At progress 1, the same running SpriteKit ball performs a 270-millisecond endpoint compression and rebound. The scene reports maximum compression exactly once so the distinct settle thud coincides with visible contact; its continuous body is authored to fill the remaining 210 milliseconds of visual settle. The scene calls `onFinished` only after the settle completes. The model yields out of the SpriteKit update stack before beginning the focused result without replacing the moving ball with a separate settle view. The analytic endpoint and selected region remain the sole authority for the winner, so render cadence can delay presentation but cannot select or move the result. After the run, the endpoint and winning seat receive one focused reveal while the two enclosing divider rays remain emphasized. Try Again keeps the seating and readies a new independent flick. A background tap dismisses the result and also returns to the same seating, ready for another flick. New group clears the seats.

With Reduce Motion enabled, the app skips the traveling animation and presents the same selected endpoint and accessible result without changing the winner.

## Fairness model

### Chooser and Tap In

Chooser chooses from the current active touch identities. Tap In chooses from an immutable snapshot of committed entries. Both use Swift's SystemRandomNumberGenerator through Int.random over the requested range. Range sampling is uniform and does not introduce modulo bias.

Visual position, token size, hue, entry order, animation timing, and feedback do not affect eligibility or probability.

### Pinball

Pinball's fairness and its visible landing are winner-first, disclosed, and endpoint-consistent:

1. The radial partition uses swept rectangle area, not equal angles, so every region has exactly one Nth of the playfield area.
2. The exact clamped release origin, flick direction, and strength are committed before randomness and cannot influence the later secure draw.
3. Rejection-sampled secure integer selection chooses one of N regions without modulo bias, giving each seat probability exactly 1/N.
4. The visible first leg follows the committed flick exactly to the first wall.
5. If the natural endpoint already lies in the selected region, that ordinary path remains unchanged.
6. Otherwise, one visible first-wall flex selects an inverse-specular suffix ending inside the already-selected region; every later bounce is an ordinary specular reflection.
7. The endpoint, highlighted dividers, and announced seat are derived from the same analytic path.

The visual endpoint demonstrates which selected region won; endpoint uniformity under the user's chosen direction is not the source of fairness. Help and review copy should say plainly: “Your flick controls the launch. Sometimes the first wall visibly flexes once so every seat keeps equal odds.” They must not imply that the user-selected ray alone yields equal odds, and the live playfield must not add a scientific label or explanation.

Equal angles would be biased in a non-square playfield because rays near long corners sweep more area. The implementation instead converts rays to exact cumulative rectangle area and advances boundaries in equal-area phases. For the important two-seat top-and-bottom case, the same general construction yields an exact horizontal 50/50 split.

The path remains analytic and precomputed. Its specular reflections produce exact wall events and an exact endpoint independent of frame rate, screen refresh rate, and SpriteKit timing.

The following invariants must remain true in future changes:

- Exactly one unbiased region-index draw determines Pinball eligibility; animation code must never redraw or reinterpret it.
- The clamped release origin and user flick must be committed before winner-region or target randomness.
- The first visible leg must exactly follow that origin and direction to the first wall.
- A natural path whose endpoint already matches the selected region must remain unchanged.
- Otherwise, exactly one visibly flexing first-wall fairness deflector may alter direction; every later path segment must be specular and the endpoint must lie inside the selected region.
- No dwell-time winner and no physics-body contact winner.
- The reported winner, emphasized boundaries, and stored final point must all identify the securely selected region.
- Regions must remain equal by rectangle area in portrait and landscape.
- Geometry changes during an active run must cancel the run rather than reinterpret its endpoint.

## Native architecture

The current native target requires iOS 26, compiles in Swift 6 language mode with strict concurrency, and supports iPhone portrait plus both landscape orientations. Following current Apple design guidance, system navigation containers own the Liquid Glass control layer while the chooser playfield remains custom-drawn content. The system can therefore supply appropriate toolbar placement, interaction, appearance adaptation, and accessibility semantics without a custom glass replica.

| Layer | Primary files | Responsibility |
|---|---|---|
| App entry and composition | **AppDelegate.swift**, **Native/App/** | SwiftUI App lifecycle, root composition and native toolbar, observable app model, App Shortcut declarations, URL handling, mode coordination |
| Pure chooser cores | **Native/Core/** | Chooser/Together-internal and Tap In state machines, scheduling abstraction, secure index selection, launch-default and color-style storage |
| Touch input | **Native/Input/NativeTouchSurface.swift**, **Native/Input/NativePinballGestureSurface.swift**, window gesture coordinator | UIKit representables, stable simultaneous-touch identity, weighted Pinball gesture samples, app-wide three-finger theme shuffle, semantic accessibility activation |
| Mode views | **Native/Modes/** | SwiftUI Chooser, Tap In, and Pinball surfaces, controls, layouts, accessibility focus |
| Pinball math | **Native/Pinball/** | secure unbiased region selection, equal-area partition, weighted flick commitment, exact first-wall contact, natural-match short circuit, conditional inverse-specular wall-flex suffix, endpoint consistency |
| Feedback | **Native/Feedback/** | Core Haptics, UIKit fallback generators, synthesized AVFoundation audio, analytic SpriteKit path presentation and rendered-frame impact/completion callbacks |
| Shared interface | **Native/UI/** | semantic app controls, full visual-world surfaces, accessibility appearance policy, broad authored rings, solid numbered chits, native Settings, and offline Information/How It Works/Privacy flow |
| Configuration | **Info.plist**, **PrivacyInfo.xcprivacy**, **Assets.xcassets**, **AppIcon.icon** | identity, `whosfirst` URL scheme, orientations, launch screen, privacy manifest, layered adaptive app icon |
| Automated tests | **ios/App/AppTests/**, **ios/App/AppUITests/** | deterministic state-machine, geometry, fairness, lifecycle, accessibility-shell, and rotation coverage |

The Xcode source of truth is **ios/App/App.xcodeproj** and its shared **App** scheme. The remaining workspace contains only that project and is not needed for dependency integration.

### State ownership

ChooserAppModel is isolated to the main actor and adapts pure core snapshots into UI state:

- AppModeCore owns current mode, the saved launch default, and one-time launch-default migration version 2, which resets an upgrade to Chooser once before preserving later explicit defaults.
- ChooserColorTheme preserves the persisted raw value while ChooserVisualTheme supplies every surface, ink, chrome, participant, divider, piece-finish, and Pinball-material role independently from interaction state. `randomizeColorTheme()` filters out the current value, selects one of the remaining worlds through the injected secure random-index generator, and reuses the normal selection path.
- TogetherChooserCore owns the user-facing Chooser mode's active touch identities and idle, settling, countdown, and revealed phases.
- TapInChooserCore owns committed entries, the draw snapshot, and collecting, countdown, and revealed phases.
- Pinball setup and run state live in ChooserAppModel while all geometry and sampling remain pure value-oriented Swift.

Production timers use cancellable Swift concurrency tasks. Unit tests inject a manual scheduler and deterministic random sources, so timing and selection behavior can be verified without sleeping or relying on global randomness.

## Feedback and accessibility

Core Haptics is the preferred tactile path. Build 17 retains the tactilely silent 1.0-second Chooser settling window, then six rising anticipation transients at 0.24, 0.78, 1.28, 1.72, 2.10, and 2.43 seconds across a 2.75-second ring ritual. A single `ChoiceAnticipationTimeline` drives matching compression, rebound, translation, rotation, cancellation, and reveal timing. The last anticipation intensity is capped at 0.74 and leaves 320 milliseconds of tactile headroom before the result. Core Haptics playback is started first; only then is the visual clock anchored. The winner's 1.0-intensity low-sharpness contact is offset 0.082 seconds to the visual keyframe's exact maximum compression, followed by a 0.78-second continuous body within the 0.82-second landing. Tap In retains its one-second draw cadence while sharing the revised result hierarchy. There are no trailing decorative taps and no synthesized Chooser winner tone. UIKit fallback preserves the escalation and a deliberately weightier winner sequence.

Pinball uses a shorter, distinct settle rather than sharing the choice-winner cue. The initial launch haptic scales with committed launch energy. Analytic geometry identifies the eligible collision events, and the active SpriteKit scene reports an impact when the matching analytic vertex is visibly rendered. A required first-wall flex receives a dedicated springy cue that is unmistakable beside ordinary velocity- and angle-scaled wall impacts; a natural matching round receives no special cue. Only the expected de-duplicated event triggers feedback, and close ordinary cues can still be suppressed so the Taptic Engine remains distinct. The endpoint thud is delivered at the same running scene's exact maximum-compression callback. UIKit feedback generators remain the tactile fallback.

AVFoundation can synthesize short offline tones for non-choice cues, but production uses the `whenCoreHapticsUnavailable` policy. On Core Haptics-capable hardware the experience remains deliberately quiet instead of layering routine sound over every tactile event. Simulator audio startup is capability-gated so AVAudioEngine never starts in Simulator, preventing unsupported remote-I/O startup failures while preserving offline fallback on supported physical devices when Core Haptics is unavailable. The Chooser/Tap In settling, countdown, and winner cues explicitly prohibit audio fallback. Core Haptics is prewarmed on foreground and first Chooser contact, and debug builds record delivery, engine stop/reset, and error paths.

The interface includes:

- system-native toolbar controls with at least 44-point targets and accurate disabled traits;
- Dynamic Type-friendly SwiftUI text, adaptive action layouts, and a single-column Settings theme grid at accessibility sizes;
- VoiceOver labels, values, hints, announcements, result focus, and stable UI-test identifiers;
- a **Shuffle colors** VoiceOver action equivalent to the app-wide gesture, leaving VoiceOver's own three-finger commands available;
- UIKit-backed Chooser and Pinball surfaces exposed as semantic buttons with accessible activation rather than opaque drawing canvases;
- an accessible 2–12 seat-count menu for Pinball;
- Reduce Motion handling for theme transitions, mode artwork, countdown pulses, and Pinball flight;
- Reduce Transparency simplification of decorative atmosphere and material layers;
- increased structural edge, texture, shadow, and divider contrast when Increase Contrast is enabled;
- segmented ring contours and dashed winning divider rays when Differentiate Without Color is enabled;
- instructions and privacy disclosures available offline inside the app.

Color is never the only identity. Tap In and Pinball use visible numbers; Chooser identifies the winning physical ring and can add a segmented contour. Visible winner prose is omitted from all three playfields to keep the result calm, while VoiceOver receives the complete “Player,” “Seat,” or winning-finger result. Decorative board and ball layers are accessibility-hidden so they do not create duplicate or meaningless elements. Build 15 remains the latest dedicated full-system accessibility audit; Build 18's final AppUITest suite and owner device review also pass with the new theme-shuffle accessibility path.

## Lifecycle, rotation, and privacy

When the scene becomes inactive:

- Chooser cancels the round and discards physical touches.
- Tap In discards pending touches; a countdown is canceled but committed entries remain.
- Pinball cancels any running or displayed path while preserving configured seats.
- all scheduled sound and haptic work stops.

Portrait and landscape are both supported. Chooser and Tap In lay out against the current SwiftUI geometry. Pinball stores seats in normalized coordinates so a collecting layout follows orientation. An active Pinball run is canceled if its playfield geometry changes, which prevents a trajectory created for one rectangle from being judged in another.

The app has no accounts, ads, analytics, tracking, purchases, or third-party runtime services. Finger locations, Tap In entries, seat positions, paths, and results are kept only in memory. UserDefaults stores the launch-default mode, selected visual-world raw value, and a nonpersonal launch-default migration version; their required-reason declaration appears in the privacy manifest. The three-finger shuffle changes only the existing selected-world value and adds no identifier, storage category, networking, analytics, or privacy declaration. App Shortcut and deep-link requests carry only a requested mode, are handled locally, and neither transmit participant state nor overwrite the saved launch default. App Store Connect should continue to use Data Not Collected.

### App icon

Build 18 replaces the Build 15–17 raster choice ring with a brand-neutral, text-free **Five Seats, One Table** mark authored as full-canvas vector layers in Icon Composer. Five equal coral, saffron, sky, leaf, and plum player spots sit around a deep-petrol two-plane circular table on warm ivory; a neutral center puck represents choosing without identifying a winner in advance. Depth comes only from overlap, layer order, the two table planes, and restrained system treatment of the center puck. There is no realistic texture, grain, continuous segmented ring, hard seam, bevel, bloom, translucent material, gradient, or baked cast shadow.

The same `.icon` document defines adaptive default, dark, clear, tinted, and monochrome presentations. Stable Icon Composer 1.6 successfully exports `Default`, `Dark`, `ClearLight`, `ClearDark`, and `TintedDark`. Dark mode uses a deep field with brightened spots; monochrome annotations keep the table, inner plane, seats, and puck distinct without depending on hue. The project removes the competing raster app-icon set while preserving `AppIcon` as the target icon name. The mark uses no text, hands, dice, cards, third-party logos, names, recognizable game artwork, or copied Apple/Google geometry.

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
| Build | 18 / version 1.0 (18) (verified, uploaded `VALID`, attached to version 1.0, and submitted; version and review submission are `WAITING_FOR_REVIEW`) |
| Minimum OS | iOS 26.0 |
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

As a historical checkpoint, Build 11's final simulator run passed all 96 AppTests and all 15 unique AppUITests (18 executions) on an iPhone 17 Pro simulator running iOS 26.5. Its verified coverage included:

- direct mode selection, launch-default persistence, switching with visible Chooser fingers, and confirmation-free clearing from safe populated states;
- all eight complete visual worlds, exact role values, persistence round trips, fallback behavior, contrast, cyclic participant reuse, and parity between miniature previews and live rendering;
- Chooser timing, late joins, removals, identity stability, lifecycle cancellation, and secure selection;
- Tap In gesture limits, numbering, maximum count, enlarged ring geometry, snapshot draws, replay, and lifecycle cancellation;
- exact Pinball equal-area partitions in portrait and landscape;
- exact internal divider rays and the two winner-boundary rays;
- the two-seat horizontal split;
- weighted 120-millisecond flick commitment, unbiased winner-region selection, narrow/wide candidate searches and inverse fallback, genuine specular endpoint consistency, the 1.6–2.2-second production motion profile, bounded collision-reset tail, localized impacts, and frame-rate-independent endpoints;
- exact 0.06/0.40/0.69/0.89-second choice anticipation, wooden-token winner curve, silent settling, distinct Pinball settle, cancellation, prewarming, diagnostics, and UIKit fallback policy;
- deterministic statistical fairness checks;
- native launch, text-free Chooser and winner states, result-background dismissal, mode control, gear-based Settings, offline information flow, and focused portrait/landscape screenshots and completion.

As a historical Build 12 checkpoint, all 112 AppTests and all 15 unique AppUITests passed; the UI suite completed 18 executions with zero failed or skipped on the iPhone 17 Pro Max simulator running iOS 26.5. The Release simulator and development-signed device builds passed, and version 1.0 (12) was installed and launched on BDR 17. Owner physical approval was still pending when Build 13 superseded it.

As a historical Build 13 checkpoint, all 118 AppTests plus the Release simulator and development-signed device builds passed. Development-signed version 1.0 (13), iOS 26 and iPhone-only, passed signature verification and was installed and launched on BDR 17. Its final UI result remained `BUILD13_UI_PENDING` when Build 14 superseded it after physical review. Build 13 was not uploaded; App Store Connect remained on build 4.

As a historical Build 14 checkpoint, all 121 AppTests, all 15 unique AppUITests across 18 executions with zero failed or skipped, and static checks passed. Its Release simulator and development-signed device builds passed. Signed version 1.0 (14), iOS 26 and iPhone-only, passed signature verification and was installed and launched on BDR 17. Build 14 was not uploaded; App Store Connect remained on build 4.

As a historical Build 15 checkpoint, all 133 AppTests and all 16 unique AppUITests passed; the UI suite completed 19 executions with zero failed or skipped. The full system accessibility audit across all three modes, npm/static checks, Release simulator build, development-signed device build, signature verification, and BDR 17 installation/launch also passed. Build 15 was not uploaded; App Store Connect remained on build 4.

As a historical Build 16 checkpoint, all 146 AppTests, npm/static checks, the Release simulator build, development-signed arm64 device build, strict signature verification, and BDR 17 installation/launch passed. The final UI attempt completed 10 executions before simulator infrastructure stalled. Hands-on review then found that the hidden analytic spawn could make a correctly read flick feel disconnected because the ball appeared elsewhere on screen. Build 17 supersedes that construction; Build 16 was not uploaded and App Store Connect remained on build 4.

Build 17 is the latest fully verified baseline. All 158 AppTests passed with zero failures or skips; the result bundle is `/tmp/whos-first-build17-final-apptests/Logs/Test/Test-App-2026.08.31_12-49-34--0400.xcresult`. The conditional direct-manipulation/fairness integration set passed `89/89` at `/tmp/whos-first-build17-conditional-integrated.xcresult`, and the focused wordless wall-flex rendering checks passed `4/4` at `/tmp/whos-first-build17-wall-wink-tests/Logs/Test/Test-App-2026.08.31_12-51-42--0400.xcresult`. The full AppUITest suite passed all `19/19 executions` with zero failures or skips (`16 unique methods`: one launch method across four variants plus 15 regular methods); its result bundle is `/tmp/whos-first-build17-ui-full-fresh.xcresult`. Its Release simulator build, development-signed arm64 device build, strict/deep signature verification, and BDR 17 installation/launch passed.

Build 18 adds the simultaneous three-finger theme shuffle and adaptive layered table icon on top of that baseline. All `167/167` AppTests pass; the result bundle is `/tmp/whos-first-build18-final-tests/Logs/Test/Test-App-2026.08.31_13-40-17--0400.xcresult`. The final AppUITest suite passes `20/20 executions` with zero failures or skips (`17 unique methods`: one launch method across four variants plus 16 regular); its result bundle is `/tmp/whos-first-build18-shuffle-ui/Logs/Test/Test-App-2026.08.31_13-52-01--0400.xcresult`. Stable Icon Composer 1.6 exports `Default`, `Dark`, `ClearLight`, `ClearDark`, and `TintedDark`. The Release simulator build passes, and the development-signed arm64 Release build passes strict/deep codesign with version 1.0 (18), minimum iOS 26, and iPhone-only support. Installation and launch on BDR 17 pass, `devicectl` confirms the expected bundle/version/build identity, and the owner physically approved the installed build. Archive/export/upload succeeded; delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` processed as `VALID`, and Build 18 replaced Build 4 on version 1.0.

Simulator success did not replace physical-iPhone QA. True multitouch, Taptic Engine behavior, speaker output, interruptions, and sustained animation were checked on BDR 17 before submission.

### Historical build 4 archive and export

Build 4 was archived with Product → Archive in Xcode, followed by Validate App and Distribute App in Organizer.

The equivalent archive and local App Store export commands used for that historical artifact were:

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

The build 4 archive is `ios/App/build/app-store/WhosFirst-1.0-build4.xcarchive`, and its distribution-signed IPA is `ios/App/build/app-store/export-build4/App.ipa`. App Store Connect accepted the upload, processed the package as VALID, and attached build 4 to draft version 1.0 in place of build 1. That was the historical pre-Build-18 state.

The Build 18 archive/export/upload used separate Build-18-named paths; its release record is maintained in [App Store readiness](app-store-readiness.md).

On August 30, 2026, build 3 passed App Store processing as `VALID`, then Build 4 superseded it. Signed versions 1.0 (9) through 1.0 (17) are historical local checkpoints and were never uploaded. Build 18 / version 1.0 (18) passed AppTests, final AppUITests, stable Icon Composer export, Release simulator/device builds, strict/deep signature verification, BDR 17 install/launch, identity confirmation, and owner physical approval. Its archive, export, upload, and processing succeeded; delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` is `VALID`, iOS 26, iPhone-only, and reports `usesNonExemptEncryption = false`. Build 18 replaced Build 4. Six approved screenshots, Build 18 metadata/review information, published Data Not Collected privacy, Free price `0.0`, and an `Active` DSA non-trader declaration for all 27 EU territories were confirmed. TestFlight was skipped as optional. Review submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` was submitted at `2026-08-31T18:38:05.116Z`; it and version 1.0 are `WAITING_FOR_REVIEW` under `AFTER_APPROVAL` release.

## Physical-device release checklist

Build 18's development-signed arm64 Release package passes strict/deep signature verification and reports version 1.0 (18), iOS 26+, and iPhone-only support. BDR 17 installation/launch and the `devicectl` identity check pass, and the owner explicitly approved the installed build after hands-on review. The completed scope below remains the physical release record; the build was subsequently archived, uploaded, and submitted.

### Chooser

- 2, 3, 4, and 5 simultaneous fingers
- late finger during settling and countdown
- removal during settling and removal from 3 or more during countdown
- cancellation below two fingers
- theme-authored broad-ring movement over each selected board surface with participant-hue rims, same-hue relief, material-specific grain, tinted occlusion, and deep contact/cast shadows; no hard black keyline, white crescent, neon treatment, idle pulse, or clipping; winner hold without visible winner prose; and next-round behavior
- mode switching with one ring visible and during settling; no switching during the actual countdown

### Tap In

- 2, 6, 20, and 50 entries
- one entry per completed gesture, movement, and cancellation
- Undo number reuse and explicit Clear cancel/confirm
- immediate populated-mode switching that clears the group without a switch confirmation
- disabled Pick below two and while a touch is pending
- Try Again with a possible repeat winner, result-background dismissal that preserves the pool, and New group
- rotation, toolbar Settings, a color-style change, Information/About navigation, and backgrounding during collection and countdown

### Pinball

- 2, 3, 6, and 12 seats in both orientations
- obvious top-and-bottom two-seat layout
- repeated directional flicks from unchanged seating
- exact ownership dividers without filled regions or an outer outline
- the two-pass wordless flick coach; the 30-point ball appearing beneath the finger only after flick commitment; lag-free direct manipulation; exact collision-safe release-origin agreement; and an exact first leg along the committed release vector
- natural endpoint matches producing no special wall effect or cue; mismatches producing one localized theme-colored first-wall curve/flex/rebound with a distinct springy haptic and no text; no hidden spawn or later steering; every later bounce remaining specular; exact dividers, collision-reset tail alignment, rolling material fleck, localized impact marks, same-ball endpoint settle, and endpoint consistency with the securely selected region
- result-background dismissal that preserves the seats and readies another flick
- Rotate or background during a run and confirm the run cancels safely
- Reduce Motion and VoiceOver seat-count setup

### General

- the tactilely silent 1.0-second Chooser stability window, six synchronized ring-and-haptic beats across 2.75 seconds, final anticipation intensity capped at 0.74, 320 milliseconds of tactile headroom, visual clock anchoring after Core Haptics starts, exact 0.082-second maximum-compression contact, the 0.82-second visual winner landing, 0.78-second low-sharpness winner body, distinct compression-synchronized Pinball settle, analytic wall cues, cancellation, engine recovery, and UIKit fallback behavior
- quiet audio policy with normal, silent, and reduced-volume settings; routine feedback should not add tones on Core Haptics-capable hardware; simulator capability gating must prevent AVAudioEngine startup while supported physical-device fallback remains available
- the system-native leading mode Menu and trailing Settings Button over the edge-to-edge board in both orientations, including Liquid Glass placement, 44-point targets, labels/hints, and disabled state
- VoiceOver, larger Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate Without Color, and display zoom
- incoming interruption, lock and unlock, and foreground recovery
- Airplane Mode and an offline cold launch
- Settings in portrait and landscape; all eight surface/material worlds across root surfaces, system-control appearance, ink, pieces, dividers, and Pinball; and persistence after relaunch
- one quick simultaneous three-finger tap in each mode, Settings, and nested information screens, confirming a different saved world, no group/result clearing, and no toast; one-, two-, and four-finger controls plus held/moving three-finger gestures must remain ordinary input
- ignored shuffle attempts during provisional input, confirmation, transition, countdown, reveal, Pinball flight, settling feedback, and backgrounding; no delayed command after the state becomes safe; VoiceOver system three-finger gestures plus the equivalent **Shuffle colors** accessibility action
- the Information section's About Who's First?, How It Works, Privacy, and Contact Support destinations
- Open Chooser, Open Tap In, and Open Pinball in Shortcuts plus all three `whosfirst://mode/...` URLs, confirming session-only mode selection and preserved launch default
- the Five Seats, One Table icon's Default, Dark, ClearLight, ClearDark, TintedDark, and monochrome system presentations at Home Screen, folder, Spotlight, Settings, and App Library sizes, confirming its player spots, table planes, and center puck remain legible without resembling a progress wheel or containing text or third-party imagery

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
- Keep rendered Pinball impact/reveal callbacks presentation-only: they may time tactile and reveal delivery but must never select, move, or reinterpret the analytic result.
- Keep App Shortcut and deep-link mode changes on the same validated session-mode path; they must not silently write the saved launch default.
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
| August 30, 2026 | Began local build 6 as a visual and interaction overhaul: raised the minimum to iOS 26, replaced the fragile cycling pill with a direct glass mode menu, restored large hollow chooser rings, and reduced the live interface to one contextual line plus essential actions. Build 6 has not been uploaded to App Store Connect. |
| August 30, 2026 | Advanced the local redesign to build 7 and rebuilt Pinball's presentation: the equal-area geometry remains internal, while the live experience uses a dimensional ball, a short fading trail, localized wall impacts, and a single focused winner reveal. Build 7 has not been uploaded to App Store Connect. |
| August 30, 2026 | Advanced the local candidate to build 8: removed visible Together coaching, enlarged the fully saturated same-hue rings and removed their white crescent, added exact Pinball ownership dividers, slowed the flight to a readable Pong/pinball cadence, fixed populated-mode switching and menu confirmation, and expanded portrait/landscape regression coverage. Build 8 has not been uploaded to App Store Connect. |
| August 30, 2026 | Advanced the local candidate to build 9: replaced the question-mark entry with gear-based native Settings, added eight locally persisted color styles, removed visible winner prose, and rebuilt feedback as a semantic settling/anticipation/controlled-reveal Core Haptics arc with quiet audio fallback. Exact Pinball dividers, the slower flight, and the iOS 26 minimum remain. The 69 AppTests and 16 UI executions across 13 cases pass locally. The signed 1.0 (9) app is installed and launches on BDR 17; owner hands-on haptic and sound confirmation remains. Build 9 has not been archived for distribution or uploaded, and App Store Connect still has build 4. |
| August 30, 2026 | Advanced the local candidate to build 10: renamed the native simultaneous experience Chooser, replaced neon styling with a matte-felt board-game system and the eight exact named palettes, made safe mode changes immediate without confirmation, added result-background dismissal semantics, rebuilt Pinball around a committed directional flick plus unbiased equal-probability target region and endpoint-consistent 3.4-second guided ricochet, and separated the revised choice-winner and Pinball-settle haptics. All 84 AppTests and 13 AppUITests pass; development-signed version 1.0 (10) is installed on BDR 17, with final launch and hands-on QA pending because the phone was locked during remote auto-launch. Build 10 remains local pending owner physical approval; it has not been archived or uploaded, and App Store Connect still has build 4. |
| August 30, 2026 | Completed local build 11: expanded the eight palettes into complete surface/material worlds, reauthored Chooser rings and numbered pieces, replaced Pinball's guided target construction with winner-first genuine specular candidate solving, enlarged the ball to 30 points, shortened flights to 1.6–2.2 seconds, adopted weighted 120-millisecond flick velocity, and strengthened choice feedback with a silent settle, rising anticipation arc, and wooden-token winner body. All 96 AppTests and 15 unique AppUITests (18 executions) pass on iPhone 17 Pro/iOS 26.5; development-signed version 1.0 (11) is installed on BDR 17. Remote launch was denied because the phone was locked, so owner hands-on approval remains pending. Build 11 remains local; App Store Connect is untouched on build 4. |
| August 31, 2026 | Completed the local build 12 implementation: retained the eight complete worlds under their Wingspan Original, Wingspan Asia, Wingspan Americas, Nidavellir, Concordia, Everdell, Lizard Wizard, and Leaders names; expanded Chooser to a 1.5-second stability window plus a 1.4-second synchronized ring-and-haptic ritual; and revised Pinball with a wordless flick coach and 2.0–2.6-second coast-and-brake replay. All 112 AppTests and all 15 unique AppUITests pass; the UI suite completed 18 executions with zero failed or skipped on iPhone 17 Pro Max/iOS 26.5. The Release simulator and development-signed device builds pass, and version 1.0 (12) is installed and launched on BDR 17. Owner physical approval, screenshots, archive, and upload remain pending. App Store Connect is untouched on build 4. |
| August 31, 2026 | Advanced the local candidate to build 13: added a one-time upgrade migration that makes Chooser effective once before preserving later explicit defaults; retained the 1.5-second stability window and replaced the Build 12 ritual with a continuous seven-beat 2.30-second shake, decisive final beat, and stronger 0.48-second winner body; and changed Pinball to continuous quadratic rolling resistance `v(u) = 1 - 0.68u²` with 0.32 relative terminal speed and 2.20–2.85-second flights without changing its endpoint or fairness. All 118 AppTests and the Release/device builds pass. Development-signed version 1.0 (13), iOS 26 and iPhone-only, passed signature verification and is installed and launched on BDR 17. The final UI result is `BUILD13_UI_PENDING`; physical approval, screenshots, archive, and upload remain pending. App Store Connect is untouched on build 4. |
| August 31, 2026 | Advanced the local candidate to build 14 after physical review: slowed Pinball approximately 20% to 2.80–3.50 seconds while retaining the same no-knee `v(u) = 1 - 0.68u²` curve, 0.32 terminal fraction, analytic endpoint, and equal odds; rebuilt Chooser rings with participant-hue rims, same-hue relief, material-specific procedural grain, tinted occlusion, and deeper contact/cast shadows instead of hard black keylines, white crescents, neon, or idle pulses; and capability-gated simulator audio startup so AVAudioEngine never starts there while supported physical-device fallback remains. All 121 AppTests, all 15 unique AppUITests across 18 executions, and static checks pass. Release/device builds and signature verification pass; signed version 1.0 (14) is installed and launched on BDR 17. Physical approval, screenshots, archive, and upload remain pending. App Store Connect is untouched on build 4. |
| August 31, 2026 | Advanced the local candidate to build 15: moved the mode menu and Settings action into a native iOS 26 toolbar with system Liquid Glass; added semantic UIKit interaction surfaces and appearance adaptations for Reduce Transparency, Increase Contrast, Differentiate Without Color, Reduce Motion, Dynamic Type, and theme-compatible light/dark controls; synchronized eligible Pinball collision haptics and the result reveal to the rendered SpriteKit clock while keeping the analytic endpoint authoritative; published three App Shortcuts and `whosfirst://mode/...` deep links; and replaced the old icon with a brand-neutral five-segment choice ring in default, dark, and tinted appearances. The final 133 AppTests, 16 unique AppUITests / 19 executions with zero failed or skipped, full three-mode system accessibility audit, npm/static checks, final Release simulator build, final development-signed device build, signature verification, and BDR 17 installation/launch pass. Physical approval, screenshots, archive, and upload remain pending. App Store Connect is untouched on build 4. |
| August 31, 2026 | Completed local build 16 with an Apple HIG- and WWDC-grounded feedback pass, then refined it after physical feedback. Chooser uses a 1.0-second stability window, 2.75-second six-beat anticipation capped at 0.74, 320 milliseconds of tactile headroom, visual clock anchoring after haptic playback begins, and winner contact at exact 0.082-second maximum compression. Pinball narrowed normal variation to ±1.5°, added a 160-millisecond post-release direction handoff, mapped weak→strong to 1.45→2.10 perimeters over 4.20→3.80 seconds and 0.62→1.0 launch energy, preserved the normalized high-inertia `v(u) = (1 - u⁵)²` endpoint, and aligned its settle body with the last 210 milliseconds. Launch-default migration version 2 resets an upgrade to Chooser once, then honors later explicit defaults. The post-tune source passed 146/146 AppTests, npm/static checks, Release/device builds, strict signature verification, installation, and launch on BDR 17. The final UI attempt completed 10 executions before simulator infrastructure stalled. Physical review then exposed that Pinball's hidden spawn could disconnect the ball from the user's flick, so Build 17 superseded it. App Store Connect remained untouched on build 4. |
| August 31, 2026 | Advanced the local candidate to build 17 after the hidden-spawn flaw was confirmed on hardware. Pinball now becomes a direct-manipulation object once the live gesture crosses the flick thresholds and launches from the exact clamped release point along the exact committed first leg. The app keeps a natural path unchanged whenever its endpoint already matches the uniformly selected seat; otherwise one localized theme-colored section of the first wall visibly flexes and rebounds with a distinct haptic to preserve exactly `1/N` odds. There is no text overlay, hidden spawn, or later steering, and the endpoint owns the result. Final post-refinement verification passes all 158 AppTests, the 89/89 conditional integration set, 4/4 focused wall-flex rendering checks, all 19 AppUITest executions, Release/device builds, strict/deep signature verification, and installation/launch on BDR 17. Owner physical approval remains pending. No screenshots, archive, upload, or App Store Connect metadata were changed; build 4 remains attached. |
| August 31, 2026 | Completed and submitted Build 18 on the verified Build 17 baseline. Added the safe simultaneous three-finger theme shuffle and VoiceOver Shuffle colors action, plus the flat layered Five Seats, One Table icon; stable Icon Composer 1.6 exports Default, Dark, ClearLight, ClearDark, and TintedDark. All 167 AppTests and all 20 AppUITest executions pass with zero failures or skips. The Release simulator build, development-signed arm64 Release build, strict/deep codesign, BDR 17 installation/launch, `devicectl` identity check, and owner physical approval pass. Archive/export/upload succeeded; delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` processed as `VALID`, iOS 26, iPhone-only, with no non-exempt encryption, and replaced Build 4 on version 1.0. Six approved 1320×2868 screenshots are `COMPLETE` in Chooser, Tap In, Pinball seats, Pinball flight, Pinball result, and Visual worlds order; the old set was removed. Build 18 copy, review notes, contact, Free price `0.0`, published Data Not Collected privacy, and `Active` DSA non-trader status across all 27 EU territories were confirmed. TestFlight was skipped as optional. Review submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` was submitted at `2026-08-31T18:38:05.116Z`; it and version 1.0 are `WAITING_FOR_REVIEW`, with release `AFTER_APPROVAL`. |

For the current App Store review status and release record, see [App Store readiness](app-store-readiness.md).
