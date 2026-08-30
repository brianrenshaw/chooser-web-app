# Who's First? — App Store Readiness

Last audited: August 30, 2026

## Bottom line

Who's First? is now a native iPhone app built with SwiftUI, Swift 6, and an iOS 18 minimum. Version 1.0 build 4 contains Together, Tap In, and Pinball. Capacitor and the embedded web runtime are no longer part of the production target.

The native implementation and automated simulator coverage are in place. A signed build 4 archive and distribution-signed IPA were created successfully on August 30, 2026. Build 4 processed as VALID and is attached to the draft version 1.0, replacing build 1. The final Pinball-inclusive metadata, App Review notes, and six screenshots are applied and verified in App Store Connect. Version 1.0 remains PREPARE_FOR_SUBMISSION, and nothing has been submitted.

Build 1 remains an older valid TestFlight artifact that supports Together only, but it is no longer attached to the draft version. Build 3 also processed as VALID, but the final audit superseded it after removing an unused System Boot Time required-reason API call and polishing the compact controls. Local build 2 is superseded as well. Build 4 is the attached three-mode release candidate. The remaining release gates are selecting the intended internal tester(s), configuring their TestFlight group, physical-iPhone QA, and the owner's explicit Submit for Review approval.

## Release identity

| Field | Current value |
|---|---|
| App Store record | Who's First? Decide Together |
| On-device name | Who's First? |
| Bundle identifier | com.brianrenshaw.fingerchooser |
| Version | 1.0 |
| Build to upload | 4 |
| Platform | iOS, iPhone only |
| Minimum OS | iOS 18.0 |
| Orientations | Portrait, landscape left, landscape right |
| Primary language | English (U.S.) |
| Primary category | Utilities |
| Price | Free, no in-app purchases |
| Privacy answer | Data Not Collected |
| Support email | contact@foliohtml.com |
| Support URL | https://brianrenshaw.github.io/chooser-web-app/support.html |
| Privacy URL | https://brianrenshaw.github.io/chooser-web-app/privacy.html |

The iOS 18 minimum is intentional. There is no requirement to preserve behavior or appearance for older iOS releases.

## Readiness dashboard

| Area | Status | Evidence or remaining action |
|---|---|---|
| Native production target | Complete | SwiftUI App lifecycle, Swift 6 strict concurrency, Observation, iOS 18 |
| Together | Complete | Stable native multitouch identities, 1.5-second settle, one-second countdown, uniform secure choice |
| Tap In | Complete | 2–50 numbered entries, one per gesture, adaptive grid, Undo, confirmed Clear, snapshot draw, replay |
| Pinball | Complete | 2–12 seats, equal-area regions, secure launch, analytic reflections, endpoint-owned result |
| Mode control | Complete | Compact animated icon cycles three modes; long press saves the launch default |
| Portrait and landscape | Implemented | Layout adapts in both; active Pinball cancels safely if geometry changes |
| Native feedback | Implemented | Core Haptics, UIKit fallbacks, generated AVFoundation sound, analytic wall cues |
| Accessibility | Implemented | VoiceOver copy and announcements, Dynamic Type layouts, Reduce Motion, result focus, accessible Pinball seat count |
| Privacy | Complete in source | No collection or tracking; only launch-default mode persists; privacy manifest declares UserDefaults reason CA92.1 |
| App icon and launch | Complete | Native neon icon and black launch presentation are configured |
| Automated verification | Passed locally | Native build, 37 unit tests, and 8 UI tests for launch, mode cycling, long-press default behavior, offline information, and rotation |
| Physical-device verification | Required | Multitouch, Taptic Engine, sound, interruptions, accessibility, and sustained Pinball remain hardware checks |
| Signed build 4 archive | Complete | `WhosFirst-1.0-build4.xcarchive`; archive and distribution export succeeded |
| TestFlight build 4 | VALID and ready for internal testing | No beta group exists yet; choose the intended tester(s), create or select an internal group, and assign build 4 before installation |
| Version 1.0 build attachment | Complete | Build 4 is attached to the draft, replacing build 1 |
| Store metadata and review notes | Applied and verified | Pinball-inclusive copy from app-store-assets/metadata.md is in App Store Connect |
| Screenshots | Applied and verified | Six processed 1320×2868 RGB images cover Together, Tap In, Pinball setup/run/result, and offline privacy in the intended order |
| Final submission | Not submitted | Version remains PREPARE_FOR_SUBMISSION; the owner must explicitly choose Submit for Review after physical QA |

## What the three modes add

The app remains focused, but the native release now has three materially different group interactions:

- **Together** is a simultaneous shared-screen ritual for two or more active fingers.
- **Tap In** lets groups of up to 50 join sequentially and explicitly start a uniform draw.
- **Pinball** lets 2–12 people claim physical seats and watch a mathematically fair reflected path stop in one equal-area region.

This native functionality is useful in App Review context. Review notes should call out true simultaneous UIKit multitouch, Core Haptics, offline operation, accessibility support, adaptive portrait/landscape layouts, and the Pinball fairness model. The app is not a bookmark or packaged website.

## Verification already completed

The local native checks cover:

- iOS simulator compilation with the production App scheme;
- Swift 6 concurrency checking;
- Together state transitions, late joins, removal rules, replay, cancellation, and secure range selection;
- Tap In numbering, count limits, gesture commitment, Undo, snapshot drawing, replay, and lifecycle cancellation;
- equal-area Pinball partitions in portrait and landscape;
- the exact horizontal 50/50 top-and-bottom two-seat case;
- analytic wall reflections and endpoint ownership;
- a five-second monotonic fast-to-zero curve;
- identical endpoints at simulated 60 Hz and 120 Hz;
- deterministic statistical checks across equal Pinball regions;
- launch, three-mode cycling, the offline information flow, and rotation in UI tests.

Run the complete suite once more from a clean checkout before archiving and retain the result in release notes. Passing simulator tests does not replace the physical checks below.

## Physical-iPhone QA required before submission

Install the processed TestFlight build 4 on at least one supported iPhone running iOS 18 or newer. Exercise portrait and landscape unless a case says otherwise.

### Together

- Use two through five simultaneous fingers.
- Add a late finger during settling and during the visible countdown.
- Remove a finger during settling.
- Remove one of three or more fingers during countdown and confirm the countdown continues with the remaining pool.
- Drop below two and confirm the round cancels.
- Move fingers, lift after reveal, and begin another round.
- Verify distinct rings, touch tracking, haptics, countdown sound, and winner feedback.

### Tap In

- Test 2, 6, 20, and 50 committed entries.
- Confirm movement never adds an entry and one gesture commits at most one.
- Confirm a canceled system touch commits nothing.
- Use Undo and confirm the removed newest number is reused.
- Test both Clear actions and the switch-mode confirmation.
- Confirm Pick is disabled below two entries and while a provisional touch is down.
- Pick again several times and allow a repeat winner.
- Use New group and confirm it stays in Tap In.
- Open About and rotate during collection.
- Background during collection and countdown; committed entries should survive while unfinished input and an unseen countdown are discarded.

### Pinball

- Test 2, 3, 6, and 12 seats.
- For two seats, place one at the top and one at the bottom and confirm the visible division is horizontal and equal.
- Use uneven real-world seat arrangements in portrait and landscape.
- Confirm the five-second ball path meets walls cleanly and the final ball position lies inside the announced seat region.
- Listen and feel for wall cues, followed by four winner flashes with ascending feedback.
- Run Play again repeatedly from the same seating.
- Rotate and background during a run; the active run must cancel and return to safe setup instead of moving its result.
- Enable Reduce Motion and confirm the traveling animation is skipped but the numbered result remains clear.
- Use VoiceOver and the accessible 2–12 seat-count menu.

### Device and system behavior

- Test normal volume, low volume, silent mode, headphones if available, and audio already playing.
- Verify the app remains usable if haptics are unavailable or disabled.
- Test VoiceOver, larger Dynamic Type sizes, Reduce Motion, display zoom, and high-contrast settings.
- Lock and unlock during each mode and simulate an interruption such as an incoming call.
- Cold-launch in Airplane Mode and complete choices with no connection.
- Open About, Help, Privacy, the public support and privacy links, and the support email action.
- Confirm no permission prompt, account, paywall, advertising, or unexpected network dependency appears.

Record the iPhone model, iOS version, orientation, accessibility setting, and pass or failure for each run.

## Build 4 archive and TestFlight path

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

### 2. Create the signed archive

Recommended: open **ios/App/App.xcodeproj**, choose Any iOS Device, then Product → Archive.

Before continuing in Organizer, verify:

- Who's First? version 1.0 build 4;
- com.brianrenshaw.fingerchooser;
- Apple distribution team 2LZJMJR6V8;
- iPhone-only support;
- iOS 18 deployment target;
- the app icon and privacy manifest;
- no Capacitor, Pods, WebKit shell, or embedded public bundle.

The command-line equivalent is:

~~~bash
xcodebuild \
  -project ios/App/App.xcodeproj \
  -scheme App \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath ios/App/build/app-store/WhosFirst-1.0-build4.xcarchive \
  archive
~~~

### 3. Validate and upload

In Organizer:

1. Select the build 4 archive.
2. Choose Validate App and resolve every error.
3. Choose Distribute App → App Store Connect → Upload.
4. Keep automatic signing and symbol upload enabled.
5. Wait for processing in App Store Connect.

A local IPA can instead be exported with:

~~~bash
xcodebuild \
  -exportArchive \
  -archivePath ios/App/build/app-store/WhosFirst-1.0-build4.xcarchive \
  -exportPath ios/App/build/app-store/export-build4 \
  -exportOptionsPlist ios/App/AppStoreExportOptions.plist
~~~

The exported package is `ios/App/build/app-store/export-build4/App.ipa`.

App Store Connect accepted the build 4 upload on August 30, 2026. It processed as VALID and is attached to draft version 1.0, replacing build 1. The version remains PREPARE_FOR_SUBMISSION; nothing has been submitted.

Do not replace the attached build 4 with the old build 1 or superseded build 3.

Build 4 is ready for internal beta testing and has no export-compliance blocker. The app currently has no TestFlight beta groups, so no tester has access and no notification has been sent. Before hardware QA, create or select an internal group, add the intended App Store Connect tester(s), assign build 4, and confirm the exact recipients before allowing notifications. The canonical What to Test copy is in **app-store-assets/metadata.md**.

### 4. Test the processed build

Install build 4 from TestFlight on the physical QA iPhone. Repeat at least:

- one Together round with three fingers;
- a six-person Tap In draw and Pick again;
- a six-seat Pinball run and Play again;
- rotation, backgrounding, Reduce Motion, VoiceOver, sound, and haptics.

Build 4 is already selected for App Store version 1.0. Keep it attached after the physical TestFlight pass.

## App Store Connect version checklist

Use **app-store-assets/metadata.md** as the canonical copy source. Review every field in App Store Connect rather than assuming old build 1 values remain appropriate.

### Product page

- Name: Who's First? Decide Together
- Subtitle: Pick who goes first
- Description: mention Together, Tap In, and Pinball
- Promotional text: mention the three private, offline choice styles
- Keywords: include group choice, turn order, Tap In, and Pinball without keyword stuffing
- Primary category: Utilities
- Support URL: public support page
- Privacy Policy URL: public privacy page
- Copyright: current owner and year
- App icon: verify it comes from build 4

### Screenshots — applied and verified

The old Together-only screenshots have been replaced with the visually inspected Pinball-inclusive set in this verified order:

1. Together — approved wording such as “Use one finger to touch the iPhone.”
2. Tap In — numbered group entries and the explicit Pick action.
3. Pinball setup — numbered seats and equal-odds regions.
4. Pinball run — the analytic reflected trail and ball.
5. Winner — a numbered or seated result with replay controls.
6. Private and offline — About or Privacy presentation.

The completed full-size verification covered:

- the accepted 6.9-inch pixel dimensions;
- no browser, simulator, test-runner, or app-switcher chrome;
- correct safe areas in portrait and landscape-derived layouts;
- no clipped text, stale two-mode control, or Capacitor-era UI;
- clear numbers and sufficient contrast;
- captions that do not promise scoring, tracking prevention beyond the app, or unavailable features.

Apple accepts a range of screenshot counts and device sizes that can change. Confirm the current requirements on [Apple's screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) when uploading.

### App privacy and compliance

- Keep App Privacy set to Data Not Collected.
- Confirm no tracking and no tracking domains.
- Confirm no account creation or account-deletion requirement.
- Confirm no ads, analytics SDK, third-party login, or in-app purchase.
- Review the required-reason API declaration for UserDefaults in the archive.
- Confirm export compliance is consistent with ITSAppUsesNonExemptEncryption set to false.
- Complete content-rights and age-rating questions based on the actual app. The current low-risk utility answers should remain appropriate, but use Apple's current questionnaire.
- Keep iPad, Mac, and Apple Vision Pro distribution disabled for this iPhone-only release.

### Pricing and availability

- Free
- No in-app purchases or subscriptions
- Intended storefront availability unchanged
- Manual release is preferable for version 1.0 so the owner controls the launch after approval

### Review information

- Provide the current private App Review contact.
- Sign-in information: not required.
- Demo account: not required.
- Attach no special hardware instructions beyond using an iPhone with multiple people or fingers.
- Explain that full Together testing requires real simultaneous multitouch and Taptic feedback requires hardware.

## Suggested App Review notes

> Who's First? is a native, offline iPhone utility with three focused ways to choose who goes first. Tap the compact icon in the upper-left to cycle Together, Tap In, and Pinball; a long press makes the current mode the next-launch default.
>
> Together: place two or more fingers on the screen at the same time. After a 1.5-second settling window and one-second countdown, one active native touch identity is selected uniformly.
>
> Tap In: each person completes one tap to create a numbered entry. With at least two entries, choose Pick from N. Undo removes the newest entry, Pick again uses the same pool and may repeat, and New group clears it.
>
> Pinball: place the iPhone flat and add 2–12 seats by tapping nearest each person. The app creates equal-area regions, samples a secure uniform start with independent direction and distance, and presents an analytic five-second reflected path. There is no preselected winner; the region containing the ball's actual final point wins. Play again keeps the seating.
>
> No login, purchases, permissions, advertising, analytics, tracking, or network connection is required. Participant state is temporary and on device. Only the user's chosen launch-default mode is stored. About, Help, and Privacy are available from the question-mark button. A physical iPhone is needed to fully evaluate simultaneous multitouch, Core Haptics, and audio feedback.

## Review-risk notes

### Minimum functionality

The likely review question is whether the app offers enough native utility. The submission should make these points easy to discover:

- three distinct group interactions rather than a single random button;
- true simultaneous native multitouch;
- Core Haptics and synchronized offline audio;
- a 50-person sequential mode;
- fair equal-area Pinball with a visible endpoint-owned outcome;
- portrait and landscape adaptation;
- VoiceOver, Dynamic Type, and Reduce Motion;
- complete offline Help and Privacy screens.

### Fairness wording

Do not describe Pinball as simulated random physics. Its path is analytic and deterministic after one secure random launch is sampled. Do not say the app chooses a winner first. The endpoint chooses the region, and equal rectangle area makes the seats equiprobable.

### Privacy consistency

The public policy, in-app disclosure, privacy manifest, metadata, review notes, and App Privacy answers must all agree:

- interaction state stays in memory;
- nothing is transmitted;
- no participant profile or history is saved;
- only the launch-default mode persists.

## Final go or no-go

Submit only when every item below is true:

- [x] Clean Debug, test, and Release commands pass.
- [ ] Physical-iPhone QA passes in portrait and landscape.
- [ ] VoiceOver and Reduce Motion paths pass.
- [x] Signed build 4 archive and distribution export complete with no unresolved error.
- [x] Build 4 processed as VALID in App Store Connect.
- [ ] An internal TestFlight group contains build 4 and only the intended tester(s).
- [ ] Build 4 passes physical-iPhone/TestFlight smoke testing.
- [x] Version 1.0 selects build 4, replacing build 1.
- [x] Pinball-inclusive copy, App Review notes, and six screenshots are applied and verified in App Store Connect.
- [x] Privacy, age rating, export compliance, category, pricing, and availability are complete.
- [x] Review notes explain all three modes and hardware testing.
- [ ] The owner inspects the complete version page and approves Submit for Review.

The remaining path is: choose the intended internal tester(s) and configure their TestFlight group → install build 4 and complete physical-iPhone QA → owner review → explicit Submit for Review approval.
