# Who's First? — App Store Readiness

Last audited: September 6, 2026

## Bottom line

**Version 1.1 (build 19) is approved and live on the App Store.** It was submitted
on September 4, 2026 and is `READY_FOR_SALE`; its review submission is `COMPLETE`.
See [Version 1.1](#version-11--live) for what shipped and the identifiers.

Who's First? is a native app for **iPhone and iPad**, built with SwiftUI and Swift 6.
The history below describes Build 18 / version 1.0 (18), the previous release. It retains Chooser, Tap In, Pinball, the native Liquid Glass toolbar, semantic accessibility layer, App Shortcuts, eight box-led surface/material worlds, and Build 17's direct-manipulation Pinball and tactile choice hierarchy.

Build 17 replaces Pinball's hidden post-release spawn with direct manipulation. Once a live gesture crosses the flick thresholds, the 30-point ball appears under the finger and follows it through release. The collision-safe clamped release point becomes the exact analytic origin, and the committed flick vector becomes the exact first leg. Only then does secure on-device randomness select one equal-area region with probability exactly `1/N`. The app first evaluates the ordinary reflected path. If it already ends in that region, the path stays completely natural. Otherwise, exactly one contact visibly curves, compresses, and rebounds once while redirecting the outgoing path toward the selected region; a distinct springy haptic matches the flex. As of 1.1 that contact is a wall section wherever a wall can reach the region, and otherwise a seat ring. There is no text overlay, hidden spawn, or later steering. Every later bounce is ordinary specular reflection, and the analytic endpoint remains the sole authority for winner identity.

Build 18 adds a window-level simultaneous three-finger tap that selects and saves a different random visual world without changing the current mode, group, or result. It is accepted only in safe idle, collecting-without-provisional-input, and result states; active countdowns, reveals, Pinball flights, confirmations, transitions, and gestures ignore it. VoiceOver retains its system three-finger gestures and receives an equivalent Shuffle colors action. Build 18 also replaces the previous raster choice-ring icon with the adaptive, layered Five Seats, One Table mark authored in Icon Composer.

Build 18's 167 AppTests pass at `/tmp/whos-first-build18-final-tests/Logs/Test/Test-App-2026.08.31_13-40-17--0400.xcresult`, and its final AppUITest suite passes all 20 executions with zero failures or skips (`17 unique methods`: one launch method across four variants plus 16 regular) at `/tmp/whos-first-build18-shuffle-ui/Logs/Test/Test-App-2026.08.31_13-52-01--0400.xcresult`. Stable Icon Composer 1.6 exports Default, Dark, ClearLight, ClearDark, and TintedDark successfully; its Release simulator and development-signed arm64 Release builds pass, including strict/deep codesign. Version 1.0 (18) installed and launched successfully on BDR 17, `devicectl` confirmed its bundle/version/build identity, and the owner physically approved the installed candidate.

The signed archive, export, and upload succeeded. Delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` processed as `VALID`, requires iOS 26, reports `usesNonExemptEncryption = false`, and replaced Build 4 on version 1.0. The six approved Build 18 screenshots, description, promotional text, review notes, and contact are applied. App Privacy is published as **Data Not Collected**, Free price `0.0` is confirmed, and DSA non-trader status is `Active` for all 27 EU territories. Review submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` was submitted at `2026-08-31T18:38:05.116Z`; version 1.0 is now `READY_FOR_SALE`. TestFlight was skipped because it is optional, not a submission prerequisite.

Build 1 remains an older valid artifact that supports the original simultaneous mode only, and Build 3 and Build 4 remain historical processed releases. Build 4 was the prior version attachment before Build 18 replaced it. Local build 2 is superseded, and signed builds 9–17 are historical local checkpoints that were never uploaded. Internal TestFlight testing remains a useful optional path for a future build, but it was not used for this submission.

### Submitted App Store Connect state

App `6806757289` has Build 18 attached to iOS version 1.0. The uploaded delivery/build ID is `6eab8145-2197-4ef5-ac71-0254d3414f3e`; processing reports `VALID`, minimum iOS 26, and `usesNonExemptEncryption = false`. Build 18 replaced the prior Build 4 attachment.

All six approved Build 18 screenshots are `COMPLETE` 1320×2868 images in this order: Chooser, Tap In, Pinball seats, Pinball flight, Pinball result, Visual worlds. The old Build 4 screenshots were removed. The Build 18 description, promotional text, App Review notes, and contact are applied. App Privacy is published as **Data Not Collected**, Free price `0.0` is confirmed, and the DSA non-trader declaration is `Active` for all 27 selected EU territories; a final read reports zero `TRADER_STATUS_NOT_PROVIDED` territories.

Review submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` contains item `MDc2YTRmYzUtYmNiZC00YTMzLWE3NjUtYmNmOTIzYTcyM2JjfDZ8ODkwNTMxNTUw` and was submitted at `2026-08-31T18:38:05.116Z`. That submission is `COMPLETE` and version 1.0 is `READY_FOR_SALE`; the release setting was `AFTER_APPROVAL`. TestFlight was intentionally skipped as the optional validation path.

## Version 1.1 — live

Submitted September 4, 2026 at `2026-09-04T14:03:47.468Z`; approved and
`READY_FOR_SALE` by September 6, 2026. Release was set to `AFTER_APPROVAL`.

| Field | Value |
|---|---|
| App Store version | 1.1 — `e15cb0c4-ad73-4ffc-8bca-7911f0c7a9c8` |
| Build | 19 — delivery `7ac9d6ff-bd3e-49c5-b477-1eb337a67e71`, `VALID`, min iOS 26.0, `usesNonExemptEncryption = false` |
| Review submission | `739ba897-758b-4f4f-a901-fca9f8074b6e`, state `COMPLETE` |
| Localization (en-US) | `b7fb0f58-f886-4892-bf83-a5e332e5b067` |
| iPhone screenshots | set `0978525b-18b9-4c58-9abb-e4248080c715`, `APP_IPHONE_67`, six `COMPLETE` at 1320×2868 |
| iPad screenshots | set `273971a6-40a5-4ae9-b2db-32a9b8aab2fe`, `APP_IPAD_PRO_3GEN_129`, six `COMPLETE` at 2064×2752 |
| Device family | `TARGETED_DEVICE_FAMILY = "1,2"`; all four iPad orientations |

### What shipped

- **iPad support**, designed rather than stretched. Board pieces, Pinball's seats
  and ball, and the ball's flight all scale with the board. Pinball scales
  linearly because a uniform scale is a similarity transform of its reachability
  problem; Chooser and Tap In damp their growth, having no fairness constraint.
  Onboarding decides its column count from the page's own geometry, replacing a
  `verticalSizeClass == .compact` test that is never true on iPad.
- **Pinball's deflection can occur at a seat ring**, not only at a wall. This
  closed the last unreachable regions on every shipping board — including the
  iPhone 17 Pro Max, which was the worst board in the lineup at 58 unreachable
  region/flick pairs out of 2464 and had been since 1.0. Walls are still searched
  first, so a round that could flex a wall still does.
- **Pinball's playfield is letterboxed** to the reference board shape. Board
  shape, unlike board size, changes which regions a flick can reach; the rule
  leaves every iPhone byte-identical and is continuous, because a playfield that
  changes size cancels a running round.
- **A one-time release note** for upgraders, never shown on a fresh install.
- **Seat rings light when struck**, and the replay view now persists across a
  round's phase changes instead of being rebuilt twice as the ball stops.

### Verification

AppTests `259/259` on both an iPhone 17 Pro Max and an iPad Pro 13-inch.
AppUITests `30/30` on iPad, with the four screenshot-capture tests skipped by
design. Release archive, export, `codesign --deep --strict`, and installation on
both BDR 17 and Brian's iPad passed, and the owner physically approved the
candidate on both devices before submission.

### Store metadata replaced, not inherited

App Store Connect copies the previous version's metadata into a new version, and
three inherited pieces were stale in ways that mattered. Each was replaced:

- The description said visual worlds are "saved only on your iPhone".
- The screenshots were the 1.0 posters, whose lead headline read "Use one finger
  to touch the iPhone" — device-specific, and awkward out of context.
- The App Review notes described an **iPhone-only** Build 18 whose deflection
  happens at "the first wall", which was wrong on both counts. The 1.1 notes are
  3,982 of the permitted 4,000 characters; the Pinball fairness mechanism is
  stated in full and the mode walkthroughs were condensed to fit.

Screenshots for 1.1 are **real device captures** produced by
`scripts/capture-screenshots.sh`, which drives the app with real touches through
`AppUITests/ScreenshotUITests`. They carry no headline text, unlike the 1.0
posters. `scripts/app-store-screenshots/` is retained only as the record of the
1.0 copy, and is marked superseded.

## Release identity

| Field | Current value |
|---|---|
| App Store Connect app ID | 6806757289 |
| App Store record | Who's First? Decide Together |
| On-device name | Who's First? |
| Bundle identifier | com.brianrenshaw.fingerchooser |
| Version | 1.1 (released on the App Store 2026-09-06; 1.0 released 2026-09-03) |
| Build attached in App Store Connect | 19 (`VALID`; delivery `7ac9d6ff-bd3e-49c5-b477-1eb337a67e71`) |
| Version status / release | READY_FOR_SALE / AFTER_APPROVAL |
| Review submission | 1.1: `739ba897-758b-4f4f-a901-fca9f8074b6e`, submitted `2026-09-04T14:03:47.468Z`, COMPLETE |
| Build 19 automated verification | AppTests 259/259 on iPhone 17 Pro Max and iPad Pro 13-inch; AppUITests 30/30 on iPad (four capture tests skipped by design); Release archive/export, strict/deep signing, install on BDR 17 and Brian's iPad, and owner physical approval all passed |
| Submitted build verification | 18 (AppTests 167/167, AppUITests 20/20 executions, stable Icon Composer exports, Release simulator/device builds, strict/deep signing, BDR 17 install/launch, identity confirmation, and owner physical approval passed) |
| Platform | iOS, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`) |
| Minimum OS for Build 19 | iOS 26.0 |
| Orientations | iPhone: portrait, landscape left, landscape right. iPad: all four. |
| Primary language | English (U.S.) |
| Primary category | Utilities |
| Price | Free, no in-app purchases |
| Privacy answer | Data Not Collected |
| Support email | contact@brianrenshaw.app |
| Support URL | https://brianrenshaw.github.io/chooser-web-app/support.html |
| Privacy URL | https://brianrenshaw.github.io/chooser-web-app/privacy.html |

Build 18 intentionally requires iOS 26 so it can use the current SwiftUI design system without compatibility branches. Build 4 remains only a historical iOS 18 artifact.

## Readiness dashboard

| Area | Status | Evidence or remaining action |
|---|---|---|
| Native production target | Complete | SwiftUI App lifecycle, Swift 6 strict concurrency, Observation, iOS 26 |
| Chooser | Build 18 automated/device verification passed | Stable native multitouch identities, text-free themed playfield, broad textured rings with participant-hue material depth, tactilely silent 1.0-second settle, six beats across 2.75 seconds, 320-millisecond result headroom, visual clock anchored after haptic playback starts, contact at 0.082-second maximum compression, 0.78-second low-sharpness winner body, uniform secure choice |
| Tap In | Build 18 automated/device verification passed | 2–50 numbered entries, enlarged adaptive grid, one per gesture, Undo, confirmed Clear, snapshot draw, replay |
| Pinball | Build 18 automated/device verification passed | 2–12 seats, exact equal-area divider rays, ball appears under the finger after flick commitment, exact clamped release origin and first leg, natural-match path unchanged, conditional wordless one-contact flex (wall or seat ring) with a distinct haptic, later bounces specular, no hidden spawn or later steering, endpoint-owned result |
| Native control layer | Build 18 automated/device verification passed | Native navigation toolbar floats over the edge-to-edge custom board; system-owned Liquid Glass wraps a semantic leading mode Menu and trailing Settings Button instead of custom playfield chrome; both preserve 44-point targets, labels, hints, and disabled state |
| Mode control | Complete | The toolbar menu opens direct Chooser, Tap In, and Pinball commands; one-time launch-default migration v2 resets an upgrade to Chooser once, safe changes immediately clear the current group without confirmation, and later explicit launch-default selections persist |
| App Shortcuts and deep links | Build 18 automated/device verification passed | Open Chooser, Open Tap In, and Open Pinball map to local `whosfirst://mode/...` URLs and change only the current session mode, not the saved launch default |
| Native Settings and appearance | Build 18 automated/device verification passed | Settings offers eight complete surface/material previews; its Information section contains About Who's First?, How It Works, Privacy, and Contact Support; launch mode and selected world persist locally |
| Three-finger theme shuffle | Automated/device verification passed | One simultaneous three-finger tap chooses one of the other seven worlds, saves it through the existing preference, preserves the group/result, and is ignored during active or unsafe interactions; VoiceOver receives a Shuffle colors action |
| Portrait and landscape | Build 18 UI suite and physical review passed | Layout and ring footprints adapt in both; Pinball dividers and direct flights retain focused coverage; active Pinball cancels safely if geometry changes; theme shuffle works across both orientations |
| Native feedback | Build 18 automated/hardware review passed | Chooser contact is offset 0.082 seconds to maximum compression after Core Haptics starts. Pinball has distinct launch, conditional wall-flex, ordinary collision, and endpoint-settle cues |
| Accessibility | Build 15 audit and Build 18 UI/device review passed | Semantic toolbar and UIKit interaction controls; meaningful ring/chit/result semantics; decorative layers hidden; VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate Without Color, result focus, accessible Pinball seat count, and non-conflicting Shuffle colors action |
| Privacy | Complete and published | App Privacy is Data Not Collected; no collection or tracking; launch-default mode, selected visual-world raw value, and a nonpersonal migration-version marker persist; privacy manifest declares UserDefaults reason CA92.1 |
| App icon and launch | Stable export/build and owner physical review passed | Brand-neutral layered Five Seats, One Table mark exported by Icon Composer 1.6 as Default, Dark, ClearLight, ClearDark, and TintedDark; no text, realistic texture, baked shadow, logo, or third-party artwork |
| Automated verification | Complete | Build 18 AppTests `167/167`, AppUITests `20/20 executions`, Release simulator build, development-signed arm64 Release build, and strict/deep codesign passed |
| Physical-device verification | Complete | Version 1.0 (18), iOS 26+, iPhone-only installed/launched on BDR 17; `devicectl` confirmed bundle/version/build identity and the owner physically approved it |
| Build 18 archive and upload | Complete | Archive/export/upload succeeded; delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` is `VALID`, iOS 26, and reports no non-exempt encryption |
| TestFlight | Skipped by choice | Optional and not an App Store submission prerequisite; no beta group was required |
| Version 1.0 build attachment | Complete | Build 18 is attached, replacing Build 4 |
| Store metadata and review notes | Complete | Build 18 description, promotional text, review notes, and contact are applied |
| Screenshots | Complete | Six approved Build 18 screenshots are `COMPLETE` at 1320×2868 in the verified order; old Build 4 screenshots were removed |
| DSA territory status | Complete | Non-trader declaration is `Active` for all 27 EU territories; zero territories report `TRADER_STATUS_NOT_PROVIDED` |
| Commerce/privacy confirmation | Complete | App Privacy is published as Data Not Collected and Free price `0.0` is confirmed |
| Final submission (1.0) | Released | Submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` was sent August 31, 2026; version 1.0 is `READY_FOR_SALE` |
| Final submission (1.1) | Released | Submission `739ba897-758b-4f4f-a901-fca9f8074b6e` was sent September 4, 2026 and is `COMPLETE`; version 1.1 is `READY_FOR_SALE` |

## What the three modes add

The app remains focused, but the native release now has three materially different group interactions:

- **Chooser** is a simultaneous shared-screen ritual for two or more active fingers.
- **Tap In** lets groups of up to 50 join sequentially and explicitly start a uniform draw.
- **Pinball** lets 2–12 people claim physical seats, see a wordless ready cue, directly move the ball beneath the finger, and release an exact first leg. Natural matching paths remain untouched; otherwise exactly one contact — a wall or a seat ring — visibly flexes once to preserve equal odds. Later bounces are specular and the visible endpoint owns the result.

This native functionality is useful in App Review context. Review notes should call out true simultaneous UIKit multitouch, Core Haptics, offline operation, accessibility support, adaptive portrait/landscape layouts, and the Pinball fairness model. The app is not a bookmark or packaged website.

## Historical Build 11 verification record

Build 11's final source tree passed all 96 AppTests and all 15 unique AppUITests (18 executions) on iPhone 17 Pro/iOS 26.5. Verified coverage includes:

- Chooser state transitions, late joins, removal rules, replay, cancellation, secure range selection, and the absence of persistent visible coaching on the live board;
- immediate mode changes while safe content is visible, clearing that content without a switch confirmation, plus disabled switching during active resolution;
- the absence of visible winner prose in every mode while complete result wording remains available to assistive technology;
- Tap In numbering, count limits, gesture commitment, Undo, snapshot drawing, replay, result-background dismissal with pool preservation, and lifecycle cancellation;
- enlarged Tap In ring geometry and complete rendered footprints at representative group sizes;
- all eight complete visual-world roles, local preference round trips, unknown-value fallback, contrast, cyclic participant reuse, and parity between Settings previews and live Chooser, Tap In, and Pinball pieces;
- distinct root surfaces, ink, chrome, ring/chit materials, dividers, and Pinball treatments without the prior universal-felt or neon/glow treatment;
- equal-area Pinball partitions in portrait and landscape, one ray per boundary, the two winning boundary rays, and the exact horizontal 50/50 top-and-bottom case;
- weighted 120-millisecond flick commitment before hidden randomness, spike/stopped-drag rejection, unbiased equal-probability region selection, narrow/wide candidate bounds, inverse fallback, and genuine specular endpoint membership;
- 1.6–2.2-second frame-rate-independent motion, a 30-point ball inside its 18-point inset, collision-reset trails, localized wall impacts, and result-background dismissal with seat preservation;
- exact 0.06/0.40/0.69/0.89-second anticipation transients, silent settling, the wooden-token winner curve, distinct shorter Pinball settle, prewarming, cancellation, diagnostics, and UIKit fallback policy;
- launch, direct three-mode selection, gear-based native Settings, the offline information flow, rotation, and portrait/landscape completion.

These final Build 11 counts are separate from Build 10's historical results. They remain a historical checkpoint.

## Historical Build 12 verification record

Build 12 passed all 112 AppTests and all 15 unique AppUITests across 18 executions with zero failed or skipped on iPhone 17 Pro Max/iOS 26.5. Its Release simulator and development-signed device builds passed, and version 1.0 (12) was installed and launched on BDR 17. Build 12 retained the 1.5-second stability window, used a four-beat 1.4-second Chooser ritual, and used a 2.0–2.6-second coast-and-brake Pinball profile. It was not uploaded; App Store Connect remained on build 4.

## Historical Build 13 verification record

Build 13 passed all 118 AppTests and its Release simulator and development-signed device builds. Development-signed version 1.0 (13), iOS 26 and iPhone-only, passed signature verification and was installed and launched on BDR 17. It introduced the one-time Chooser-default migration, the continuous seven-beat 2.30-second ritual and stronger 0.48-second winner body, and Pinball's no-knee quadratic velocity profile over 2.20–2.85 seconds. Its final AppUITest result remained `BUILD13_UI_PENDING` when physical feedback led to Build 14. It was not uploaded; App Store Connect remained on build 4.

## Historical Build 14 verification record

Build 14 passed all 121 AppTests, all 15 unique AppUITests across 18 executions with zero failed or skipped, static checks, and its Release simulator and development-signed device builds. Development-signed version 1.0 (14), iOS 26 and iPhone-only, passed signature verification and was installed and launched on BDR 17. It retained the seven-beat Chooser ritual, added the tactile participant-hue ring materials, slowed Pinball to 2.80–3.50 seconds without changing its curve or fairness, and capability-gated simulator audio startup. It was not uploaded; App Store Connect remained on build 4.

## Historical Build 15 verification record

Build 15 passed all 133 AppTests and all 16 unique AppUITests across 19 executions with zero failed or skipped. Its full three-mode accessibility audit, npm/static checks, Release simulator build, development-signed device build, signature verification, and BDR 17 installation/launch also passed. It introduced the native Liquid Glass toolbar, semantic accessibility surfaces and appearance adaptations, rendered-clock Pinball collision/reveal synchronization, App Shortcuts and deep links, and the default/dark/tinted brand-neutral icon. It was not uploaded; App Store Connect remained on build 4.

## Historical Build 16 verification record

Build 16 passed all 146 AppTests, npm/static checks, its Release simulator and development-signed arm64 device builds, strict signature verification, and BDR 17 installation/launch. Its final UI attempt completed 10 executions before simulator infrastructure stalled. Hardware review then exposed a product flaw: Pinball correctly read a flick but could reveal the ball at a hidden analytic spawn elsewhere on the screen, breaking the direct causal connection. Build 17 supersedes that construction. Build 16 was not uploaded; App Store Connect remained on build 4.

## Completed physical-iPhone QA

Build 18's release verification and physical review are complete. Its 167 AppTests, all 20 AppUITest executions, stable Icon Composer 1.6 exports, Release simulator build, development-signed arm64 Release build, strict/deep codesign, BDR 17 installation/launch, and `devicectl` identity check pass. The owner explicitly approved the installed build. The checklist below records the completed hands-on scope; TestFlight was skipped as optional, and the release was subsequently archived, uploaded, and submitted.

### First-run introduction (Build 19)

- **Delete the app before testing.** The introduction flags survive an
  install-over-install, so a reinstall alone will not show it again.
- On first launch, confirm the three-page carousel appears over the board, that
  Skip is present on pages one and two and absent on page three, and that the
  button reads Continue and then Get Started.
- Swipe between pages by hand as well as using Continue. Rotate to landscape on
  page two and confirm the same page is still shown, fully laid out, rather than
  a half-scrolled position.
- Finish the carousel and confirm the Chooser board is immediately usable, with
  no introduction card stacked on top of it.
- Switch to Tap In and then Pinball and confirm each shows its card once. Dismiss
  one with its close button and the other by simply touching the board. Leave and
  return to each mode and confirm neither card comes back.
- In Pinball, add two seats while the card is still showing and confirm the
  wordless flick demonstration waits until the card is gone, then still plays.
- Open Settings → **Show Welcome Again**, confirm the sheet closes before the
  carousel appears, then skip it and confirm the per-mode cards do **not** return.
- Confirm the Settings button is unavailable while the carousel is up.
- With VoiceOver on: confirm each page change is announced with its position,
  that focus lands on the new page's title, that the page dots work as an
  adjustable control, that Next page and Previous page appear in the rotor, and
  that swiping right from the last element does not reach an off-screen page.
- At the largest accessibility text size, confirm every page scrolls without
  clipping in both orientations and that all controls stay at least 44 points.
- From a cold start, launch via the Open Pinball App Shortcut on a fresh install
  and confirm the carousel still appears and Pinball is the mode underneath it.
- Background the app while the carousel is showing and confirm it is still there
  on return.

### Chooser

- Use two through five simultaneous fingers.
- Add a late finger during settling and during the visible countdown.
- Remove a finger during settling.
- Remove one of three or more fingers during countdown and confirm the countdown continues with the remaining pool.
- Drop below two and confirm the round cancels.
- Move fingers, lift after reveal, and begin another round.
- Verify the live Chooser screen has no persistent coaching sentence once any one-time introduction card is dismissed, every visual world changes the complete board and chrome treatment, the broad rings have participant-hue inner/outer rims, same-hue relief, material-specific grain, tinted occlusion, and deeper contact/cast shadows, with no hard black keyline, white crescent, neon treatment, idle pulse, or clipped footprint.
- Open the mode menu with one finger visible and during settling; switching should work immediately. It should remain unavailable only during the actual countdown.
- Verify distinct broad textured rings, touch tracking, tactile silence throughout the 1.0-second stability window, six synchronized beats at 0.24/0.78/1.28/1.72/2.10/2.43 seconds across the 2.75-second anticipation, final anticipation strength capped at 0.74, and 320 milliseconds of tactile headroom. Confirm Core Haptics playback begins before the visual clock anchors, tactile contact lands at exact maximum compression 0.082 seconds into the 0.82-second landing, the low-sharpness winner body lasts 0.78 seconds, no synthesized winner tone plays, and the visual focus works in both orientations.

### Tap In

- Test 2, 6, 20, and 50 committed entries.
- Confirm movement never adds an entry and one gesture commits at most one.
- Confirm a canceled system touch commits nothing.
- Use Undo and confirm the removed newest number is reused.
- Test explicit Clear and its confirmation.
- From a populated pool or result, choose another mode and confirm it changes immediately and clears the entries without presenting a switch confirmation.
- Confirm Pick is disabled below two entries and while a provisional touch is down.
- Use Try Again several times and allow a repeat winner.
- At a result, tap the background and confirm the winner emphasis clears while every committed entry remains available for another explicit Pick.
- Use New group and confirm it stays in Tap In.
- Open toolbar Settings during collection, change the visual world, navigate through the Information section to About Who's First?, and rotate before returning; the committed group should remain intact.
- Background during collection and countdown; committed entries should survive while unfinished input and an unseen countdown are discarded.

### Pinball

- Test 2, 3, 6, and 12 seats.
- For two seats, place one at the top and one at the bottom and confirm the exact horizontal ownership divider is visible while no outer arena outline or filled territory appears.
- Use uneven real-world seat arrangements in portrait and landscape.
- Confirm every thin divider ray meets the mathematical partition center and edge, and the winning result emphasizes exactly the two boundaries around its endpoint.
- Add the second seat and confirm the two-pass wordless flick coach appears without implying a spawn point. Flick in several directions and speeds. Confirm the weighted velocity fit rejects spikes and stopped drags, then verify the 30-point ball appears beneath the finger only after the gesture qualifies as a flick and remains attached without lag through release.
- Confirm release near the center and each edge. The replay must begin at the exact collision-safe clamped ball center and follow the exact committed release vector to its first wall; the ball must never jump to a hidden start elsewhere on screen.
- Exercise both outcomes: when the natural endpoint already belongs to the selected seat, confirm the path and its impacts remain ordinary. When modulation is needed, confirm exactly one contact flexes: a localized theme-colored wall section, or a lit seat ring the ball kicks off. Every other turn on the path must stay ordinary. No explanatory text should appear. Every later wall turn must be an ordinary specular reflection with no further flex or steering.
- Confirm the ball and shadow remain inside the collision inset, and the final point lies in the securely selected equal-area region and agrees with the emphasized pair of boundary rays. The flick controls launch; when needed, one visible flex at a wall or seat ring preserves equal odds.
- Confirm ordinary wall hits get one short localized theme-ink impact mark. Eligible tactile cues should coincide with the exact rendered collision frame and feel distinct from a required fairness flex; closely spaced ordinary cues may be coalesced or filtered so the Taptic Engine remains legible. Confirm there are no sparks, perimeter flashes, labels, scientific overlays, or winner blooms and that audio remains quiet on haptic-capable hardware.
- Confirm the same running ball performs the final 270-millisecond compression and rebound, its distinct thud lands at exact maximum compression, its body fills the remaining 210 milliseconds of visible settle, and the focused result follows without replacing the ball, while the endpoint, boundary emphasis, and announced seat remain unchanged across refresh rates.
- Run Try Again repeatedly from the same seating.
- At a result, tap the background and confirm the emphasis clears, every seat remains, and the playfield is ready for another flick.
- Rotate and background during a run; the active run must cancel and return to safe setup instead of moving its result.
- Enable Reduce Motion and confirm the traveling animation is skipped but the numbered result remains clear.
- Use VoiceOver and the accessible 2–12 seat-count menu.

### Device and system behavior

- Test normal volume, low volume, silent mode, headphones if available, and audio already playing; confirm routine haptic-capable choices do not layer unnecessary tones over the tactile sequence.
- Verify the app remains usable if haptics are unavailable or disabled.
- Test VoiceOver, larger Dynamic Type sizes, Reduce Motion, Reduce Transparency, Increase Contrast, Differentiate Without Color, display zoom, and every theme's preferred light/dark control appearance. Confirm reduced decorative layering, stronger structural edges, segmented/dashed non-color winner cues, and readable single-column Settings at accessibility sizes.
- Lock and unlock during each mode and simulate an interruption such as an incoming call.
- Cold-launch in Airplane Mode and complete choices with no connection.
- Verify launch-default migration v2 resets an upgrade to Chooser exactly once, then explicitly save Tap In or Pinball and confirm that later launches preserve that selection rather than repeating the migration.
- Exercise the leading mode Menu and trailing Settings Button in portrait and landscape. Confirm the system navigation toolbar keeps its floating Liquid Glass treatment, safe placement, 44-point targets, semantic labels/hints, and accurate disabled state without covering playfield interaction.
- Open the Settings sheet, select and persist all eight named worlds, and verify the root surface, procedural texture, ink, system control appearance, Chooser rings, Tap In chits, Pinball dividers, and ball material all update without clearing the current group.
- In each top-level mode, Settings, and the nested information screens, perform one quick simultaneous three-finger tap. Confirm it selects a different one of the other seven worlds, saves it, crossfades every themed layer, and preserves the current mode, committed group, and visible result without showing a toast.
- Repeat the gesture with one, two, and four fingers, with a held three-finger touch, and with a moving three-finger touch. Confirm ordinary input remains immediate and no gesture accidentally adds a Chooser finger, Tap In entry, Pinball seat, launches Pinball, activates a button, or dismisses a result.
- Try the shuffle during provisional input, confirmation, countdown, reveal, Pinball flight, settling feedback, backgrounding, and a theme transition. Confirm it is ignored rather than queued. Enable VoiceOver and confirm its system three-finger gestures remain available while the **Shuffle colors** accessibility action provides the equivalent app command.
- Open the Information section's About Who's First?, How It Works, Privacy, and Contact Support destinations.
- Invoke Open Chooser, Open Tap In, and Open Pinball from Shortcuts, then test `whosfirst://mode/chooser`, `whosfirst://mode/tap-in`, and `whosfirst://mode/pinball`. Confirm each changes only the current session mode and preserves the saved launch default.
- Inspect the Five Seats, One Table icon on the Home Screen, in a folder, Spotlight, Settings, and App Library against light and dark wallpapers. Confirm its five equal player spots, two-plane circular table, and neutral center puck remain legible in the exported Default, Dark, ClearLight, ClearDark, TintedDark, and monochrome system presentations without resembling a progress wheel or scoring display.
- Confirm no permission prompt, account, paywall, advertising, or unexpected network dependency appears.

Record the iPhone model, iOS version, orientation, accessibility setting, and pass or failure for each run.

## Build 4 historical record and Build 18 submission

### 1. Final local verification

From the repository root:

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

Use an installed simulator name if iPhone 17 Pro is unavailable.

Final Build 18 result: AppTests `167/167 passed` at `/tmp/whos-first-build18-final-tests/Logs/Test/Test-App-2026.08.31_13-40-17--0400.xcresult`; AppUITests `20/20 executions passed` with zero failures or skips (`17 unique methods`: one launch method across four variants plus 16 regular) at `/tmp/whos-first-build18-shuffle-ui/Logs/Test/Test-App-2026.08.31_13-52-01--0400.xcresult`; stable Icon Composer 1.6 exports `Default`, `Dark`, `ClearLight`, `ClearDark`, and `TintedDark`; and the Release simulator and development-signed arm64 Release builds pass strict/deep codesign with version `1.0 (18)`, minimum iOS `26.0`, and iPhone-only support. Installation and launch on BDR 17 pass, `devicectl` confirms the bundle/version/build identity, and the owner physically approved the installed build. The signed archive/export/upload then succeeded, and App Store Connect processed Build 18 as `VALID`.

### 2. Signed archive record

Build 18 was archived and exported successfully. The release checklist was:

Before continuing in Organizer, verify:

- Who's First? version 1.0 build 18;
- com.brianrenshaw.fingerchooser;
- Apple distribution team 2LZJMJR6V8;
- iPhone-only support;
- iOS 26 deployment target;
- the stable Icon Composer 1.6 app-icon exports for Default, Dark, ClearLight, ClearDark, and TintedDark and the privacy manifest;
- no Capacitor, Pods, WebKit shell, or embedded public bundle.

The command-line equivalent is:

~~~bash
xcodebuild \
  -project ios/App/App.xcodeproj \
  -scheme App \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ios/App/build/app-store/WhosFirst-1.0-build18.xcarchive \
  archive
~~~

### 3. Validation and upload record

The completed Organizer flow was:

1. Select the Build 18 archive.
2. Choose Validate App and resolve every error.
3. Choose Distribute App → App Store Connect → Upload.
4. Keep automatic signing and symbol upload enabled.
5. Wait for processing in App Store Connect.

The local IPA export command was:

~~~bash
xcodebuild \
  -exportArchive \
  -archivePath ios/App/build/app-store/WhosFirst-1.0-build18.xcarchive \
  -exportPath ios/App/build/app-store/export-build18 \
  -exportOptionsPlist ios/App/AppStoreExportOptions.plist
~~~

The Build 18 package was exported to `ios/App/build/app-store/export-build18/App.ipa`. The historical build 4 archive and package remain under their original `WhosFirst-1.0-build4.xcarchive` and `export-build4/App.ipa` paths.

App Store Connect accepted the historical build 4 upload on August 30, 2026. It processed as `VALID` and replaced build 1 on the draft. Build 18 later replaced build 4 on version 1.0.

Build 1, build 3, and build 4 remain historical processed artifacts and must not replace the submitted Build 18.

Build 4 predates the Build 18 visual worlds, current control layer, accessibility adaptations, App Shortcuts, haptic hierarchy, direct-manipulation Pinball, three-finger theme shuffle, and adaptive table icon. Build 18 processed as `VALID`, reports no non-exempt encryption, and is the attached release. TestFlight was skipped for version 1.0 because it is optional and is not an App Store submission prerequisite. The canonical optional What to Test copy remains in **app-store-assets/metadata.md** for a future internal build.

### 4. Optional TestFlight path — skipped for version 1.0

If a future release uses the optional TestFlight pass, install that processed build on the physical QA iPhone and repeat at least:

- one Chooser round with three fingers;
- a six-person Tap In draw and Try Again;
- a six-seat Pinball flick, background-result dismissal, and Try Again;
- a safe three-finger theme shuffle in each mode plus the VoiceOver Shuffle colors action;
- rotation, backgrounding, system appearance/accessibility settings, all three App Shortcuts/deep links, sound, haptics, and the adaptive icon's Default, Dark, ClearLight, ClearDark, and TintedDark exports.

For version 1.0, Build 18 was deliberately selected without a TestFlight pass after its complete automated and physical-device verification.

## App Store Connect version checklist

Use **app-store-assets/metadata.md** as the canonical copy source. Review every field in App Store Connect rather than assuming old build 1 values remain appropriate.

### Product page

- Name: Who's First? Decide Together
- Subtitle: Pick who goes first
- Description: mention Chooser, Tap In, and Pinball
- Promotional text: mention the three private, offline choice styles
- Keywords: include group choice, turn order, Tap In, and Pinball without keyword stuffing
- Primary category: Utilities
- Support URL: public support page
- Privacy Policy URL: public privacy page
- Copyright: current owner and year
- App icon: Build 18 supplies the layered Five Seats, One Table mark as stable Icon Composer 1.6 Default, Dark, ClearLight, ClearDark, and TintedDark exports

### Screenshots — Build 18 applied

The approved Build 18 set is `COMPLETE` at 1320×2868 in this verified order:

1. Chooser.
2. Tap In — numbered group entries and the explicit Pick action.
3. Pinball seats — numbered seats on the Build 18 playfield.
4. Pinball flight — the dimensional ball, short fading trail, and localized wall impact.
5. Pinball result — a seated result with replay controls.
6. Visual worlds.

The set shows the native system toolbar, complete visual worlds, text-free Chooser playfield, numbered chits, and current Pinball states. The old Build 4 screenshots were removed. Final verification covered:

- the accepted 6.9-inch pixel dimensions;
- no browser, simulator, test-runner, or app-switcher chrome;
- correct safe areas in portrait and landscape-derived layouts;
- no clipped text, stale two-mode control, or Capacitor-era UI;
- clear numbers and sufficient contrast;
- captions that do not promise scoring, tracking prevention beyond the app, or unavailable features.

Apple accepts a range of screenshot counts and device sizes that can change. Confirm the current requirements on [Apple's screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) when uploading.

### App privacy and compliance

- App Privacy is published as Data Not Collected.
- Confirm no tracking and no tracking domains.
- Confirm no account creation or account-deletion requirement.
- Confirm no ads, analytics SDK, third-party login, or in-app purchase.
- Review the required-reason API declaration for UserDefaults in the archive.
- Export compliance is consistent with `ITSAppUsesNonExemptEncryption` set to false; the processed build reports `usesNonExemptEncryption = false`.
- Complete content-rights and age-rating questions based on the actual app. The current low-risk utility answers should remain appropriate, but use Apple's current questionnaire.
- iPad distribution is enabled as of 1.1 (`TARGETED_DEVICE_FAMILY = "1,2"`, all four iPad orientations). It ships a designed layout, not a stretched phone: board pieces scale, Pinball scales linearly to preserve its fairness proof, and onboarding decides its columns from page geometry rather than a size class. iPad is visual-only — there is no Taptic Engine, and no audio or haptic behaviour was added for it. **A new iPad screenshot set is required before submission.**
- Keep Mac and Apple Vision Pro distribution disabled.

### Pricing and availability

- Free (`0.0` confirmed)
- No in-app purchases or subscriptions
- Intended storefront availability unchanged
- Release setting: After Approval

### Review information

- Provide the current private App Review contact.
- Sign-in information: not required.
- Demo account: not required.
- Attach no special hardware instructions beyond using an iPhone with multiple people or fingers.
- Explain that full Chooser testing requires real simultaneous multitouch and Taptic feedback requires hardware.

## Suggested App Review notes

> Who's First? is a native, offline, iPhone-only utility requiring iOS 26, with three focused ways to choose who goes first. Its custom board extends edge to edge under a native navigation toolbar. The leading semantic mode Menu and trailing Settings Button receive the system Liquid Glass treatment, placement, 44-point targets, labels, hints, and disabled behavior. The menu opens direct Chooser, Tap In, and Pinball commands and has an explicit command to make the current mode the next-launch default. Safe changes clear the current group without confirmation; explicit Clear actions still ask. Settings offers eight complete visual worlds and an Information section containing About Who's First?, How It Works, Privacy, and Contact Support. A simultaneous three-finger tap in any safe screen selects and saves a different visual world without changing the group or result; VoiceOver users receive an equivalent Shuffle colors action.
>
> Chooser: place two or more fingers on the screen at the same time. The live themed playfield intentionally has no coaching sentence; broad rings use participant-hue inner and outer rims, same-hue relief, material-specific grain, tinted occlusion, and deeper contact and cast shadows instead of a hard black keyline, white crescent, neon treatment, or idle pulse. After a tactilely silent 1.0-second stability window, a 2.75-second anticipation arc synchronizes six haptic beats and ring reactions at 0.24, 0.78, 1.28, 1.72, 2.10, and 2.43 seconds. The final anticipation strength is capped at 0.74, leaving 320 milliseconds of tactile headroom. Core Haptics playback begins before the visual clock is anchored, so tactile contact lands at exact maximum compression 0.082 seconds into the 0.82-second winner landing; the low-sharpness body lasts 0.78 seconds. Selection remains uniform over the active native touch identities. Across every mode, the winning ring, number, or seat supplies the visible result without an additional winner sentence; VoiceOver receives the full result.
>
> Tap In: each person completes one tap to create a numbered board-game chit. With at least two entries, choose Pick N. Undo removes the newest entry, Try Again uses the same pool and may repeat, a result-background tap preserves the pool while dismissing the result emphasis, and New group clears it.
>
> Pinball: place the iPhone flat and add 2–12 seats by tapping nearest each person. Thin center-to-edge rays show exact equal-area ownership boundaries. Once a live gesture crosses the flick thresholds, the 30-point ball appears beneath the finger and follows it through release. The exact collision-safe clamped release point and committed vector become the analytic origin and first leg. Only after those values are fixed does a secure unbiased draw select one equal-probability region. The app first evaluates the ordinary reflected path. If it already lands in the selected region, that path stays unchanged. Otherwise, exactly one contact visibly flexes and rebounds with a distinct springy haptic while creating a genuine reflected suffix that ends in the selected region. That contact is a localized theme-colored section of a wall, or — when no wall on the path can reach the selected region, which is common for a weak flick — a seat ring the ball kicks off, lit exactly as any struck ring is. There is no text overlay, hidden spawn, or later steering. Every later bounce is ordinary reflection. The endpoint, emphasized boundaries, and announced seat all identify the same result, and render timing cannot change it. In short: Your flick controls the launch. Sometimes one wall or seat ring visibly flexes once so every seat keeps equal odds.
>
> Open Chooser, Open Tap In, and Open Pinball are available as App Shortcuts and map to local `whosfirst://mode/...` deep links. They select only the current session mode and do not overwrite the saved launch default. Custom playfield surfaces expose semantic accessibility actions; decorative drawing is hidden from assistive technology. The interface adapts to VoiceOver, Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, and Differentiate Without Color. The app icon is a brand-neutral, text-free Five Seats, One Table composition exported by stable Icon Composer 1.6 as Default, Dark, ClearLight, ClearDark, and TintedDark layered artwork. Theme shuffling reuses the existing locally saved visual-world preference and adds no networking, data collection, or storage category. No login, purchases, permissions, advertising, analytics, tracking, or network connection is required; participant state is temporary and on device.

## Review-risk notes

### Minimum functionality

The likely review question is whether the app offers enough native utility. The submission should make these points easy to discover:

- three distinct group interactions rather than a single random button;
- true simultaneous native multitouch in Chooser;
- semantic Core Haptics with quiet offline audio fallback;
- a 50-person sequential mode;
- fair equal-area Pinball with exact visible ownership dividers, direct under-finger launch, unchanged natural matches, one conditional visible flex at a wall or seat ring, later specular bounces, and an endpoint-consistent outcome;
- portrait and landscape adaptation with a system-native Liquid Glass toolbar;
- semantic VoiceOver controls plus Dynamic Type, Reduce Motion, Reduce Transparency, Increase Contrast, and Differentiate Without Color;
- App Shortcuts and local deep links for all three session modes;
- complete offline Settings Information, How It Works, and Privacy screens;
- a brand-neutral layered Five Seats, One Table icon with Default, Dark, ClearLight, ClearDark, TintedDark, and monochrome system presentations.

### Fairness wording

Do not describe Pinball as simulated random physics or claim that the user's launch direction alone makes every endpoint equally likely. The current construction commits the exact clamped release origin, direction, and strength first, then uses an unbiased secure index to give every equal-area seat region probability `1/N`. The first visible leg follows the flick exactly. If the natural endpoint matches the selected region, the path remains unchanged. Otherwise, one visibly flexing contact — a wall section or a seat ring — creates a suffix ending in the selected region; every later bounce is ordinary reflection, and the accepted endpoint owns the result. The preferred plain-language disclosure is: “Your flick controls the launch. Sometimes one wall or seat ring visibly flexes once so every seat keeps equal odds.”

### Privacy consistency

The public policy, in-app disclosure, privacy manifest, metadata, review notes, and App Privacy answers must all agree:

- interaction state stays in memory;
- no participant or result data is transmitted;
- App Shortcut/deep-link requests contain only a local session mode and do not overwrite the saved launch default;
- no participant profile or history is saved;
- only the launch-default mode, selected visual-world raw value, and nonpersonal launch-default migration version persist.

## Final go or no-go

The submission gate closed with every release requirement below complete:

- [x] Final post-refinement Build 17 AppTests pass (`158/158`).
- [x] The full Build 17 AppUITest suite passes (`19/19 executions`, zero failures or skips; 16 unique methods).
- [x] Conditional integration (`89/89`) and focused wall rendering (`4/4`) confirm both outcomes: natural matches stay ordinary; mismatches use one wordless localized flex with its distinct cue.
- [x] The final post-refinement Build 17 Release/device builds, strict/deep signature verification, installation, and launch on BDR 17 pass.
- [x] Build 18 AppTests pass (`167/167`) on the final stable-Xcode source.
- [x] Stable Icon Composer 1.6 exports Default, Dark, ClearLight, ClearDark, and TintedDark successfully.
- [x] Build 18 Release simulator and development-signed arm64 Release builds plus strict/deep signature verification pass; the signed app reports version 1.0 (18), iOS 26+, and iPhone-only support.
- [x] The final full Build 18 AppUITest suite passes (`20/20 executions`, zero failures or skips; 17 unique methods).
- [x] Build 18 installs and launches on BDR 17; `devicectl` confirms the expected bundle identifier, version, and build.
- [x] Owner hands-on Build 18 physical-iPhone QA passes in portrait and landscape, including the system toolbar, Chooser anticipation/result hierarchy, direct Pinball manipulation, exact first leg, conditional wordless fairness flex, three-finger theme shuffle, VoiceOver fallback, App Shortcuts/deep links, and every adaptive icon appearance.
- [x] Signed build 4 archive and distribution export complete with no unresolved error.
- [x] Build 4 processed as VALID in App Store Connect.
- [x] Version 1.0 selects Build 18, replacing Build 4; delivery `6eab8145-2197-4ef5-ac71-0254d3414f3e` processed as `VALID`.
- [x] Build 18 description, promotional text, App Review notes, contact, and six approved `COMPLETE` screenshots are applied and verified in App Store Connect.
- [x] TestFlight was deliberately skipped as optional and not required for submission.
- [x] Privacy, age rating, export compliance, category, pricing, and availability values are complete in the existing record.
- [x] DSA non-trader status is saved and `Active` for all 27 selected EU territories; the final read reports zero `TRADER_STATUS_NOT_PROVIDED` territories.
- [x] App Privacy is published as Data Not Collected and Free price `0.0` is confirmed.
- [x] Review notes explain all three modes and hardware testing.
- [x] The owner inspected and approved the complete release; review submission `076a4fc5-bcbd-4a33-a765-bcf923a723bc` was submitted at `2026-08-31T18:38:05.116Z`.

Version 1.0 shipped, and version 1.1 (build 19) followed it: submitted `2026-09-04T14:03:47.468Z` under review submission `739ba897-758b-4f4f-a901-fca9f8074b6e`, approved, and `READY_FOR_SALE` as of September 6, 2026. Remaining work is operational: watch for crash reports and reviews from the first iPad users, since 1.1 is the app's first release on that device family.
