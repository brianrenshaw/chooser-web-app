# Who's First? — App Store Readiness

Last audited: August 30, 2026

## Bottom line

Who's First? is a working native-wrapped iPhone app, not merely an idea or a web-only prototype. Debug, Release, signed archive, and App Store IPA export all pass with Xcode 26.6. The paid Apple team and bundle identifier are verified through the live App Store Connect API, and Xcode created valid development and App Store provisioning profiles. The App Store Connect record exists as `Who's First? Decide Together`; metadata, screenshots, and the first TestFlight upload are in progress.

The intended product remains deliberately narrow: choose one person to go first. Scoring, scoreboards, player history, and game management are out of scope.

## What is ready

| Area | Status |
|---|---|
| Core picker | Complete: multi-touch rings, settling window, countdown, random winner, replay, audio fallback |
| Native value | Complete: bundled offline app and Capacitor Taptic Engine feedback |
| Compatibility | iOS 14+ color fallback added; modern WebKit uses OKLCH |
| iOS project | Capacitor 7.6.8, iPhone-only, bundle `com.brianrenshaw.fingerchooser`, version 1.0 (build 1) |
| Local builds | Debug simulator, Release device, signed archive, and App Store IPA export pass in Xcode 26.6 |
| Signing | Valid Apple Development and Apple Distribution identities plus development and App Store profiles for team `2LZJMJR6V8` |
| Apple registration | `com.brianrenshaw.fingerchooser` is registered under paid team `2LZJMJR6V8` |
| Branding | Neon-ring native icon, touch icon, and black launch screen replace Capacitor defaults |
| Privacy | No accounts, ads, analytics, tracking, storage, or network calls; app privacy manifest declares no collection |
| Public pages | Privacy and support are ready to deploy and list `contact@foliohtml.com` |
| In-app disclosure | Help/About dialog links to privacy and support from the main screen |
| Dependencies | Production and full npm audits report zero known vulnerabilities |

## What still blocks submission

1. **Run current physical-device QA.** Re-test two through five fingers, late joiners, finger removal, replay, background/foreground reset, audio, and native haptics on at least one current iPhone. Simulator and desktop browsers cannot validate true multi-touch or Taptic behavior.
2. **Finish the review contact.** Apple requires a phone number for the private App Review contact. The email is `contact@foliohtml.com`; a phone number still needs to be supplied immediately before submission.
3. **Approve submission.** Everything else can be prepared and verified without submitting the app. The final Submit for Review action remains a deliberate owner approval.

## Current Apple requirements that matter

- Since April 28, 2026, iOS uploads must be built with Xcode 26 or later and the iOS 26 SDK. This machine has Xcode 26.6 and the project passes Release compilation. See [Apple’s SDK minimum requirement](https://developer.apple.com/news/upcoming-requirements/?id=02032026a).
- Apple requires a privacy-policy URL for every iOS app and an easily accessible policy link inside the app. See [App privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/) and [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
- Apple allows one to ten screenshots. The current accepted 6.9-inch iPhone sizes include 1320×2868, 1290×2796, and 1260×2736 portrait pixels. See [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).
- The largest review risk is Guideline 4.2, Minimum Functionality. The review notes should explicitly explain the app’s native multi-touch interaction, native haptics, offline operation, privacy, and focused utility.

## Recommended v1 listing

**Name**  
Who's First? Decide Together

**Subtitle**  
Pick who goes first

**Primary category**  
Utilities

**Price**  
Free, with no in-app purchases

**Privacy answer**  
No, this app does not collect data

**Likely age rating**  
4+, subject to the answers in Apple’s current age-rating questionnaire

**Keywords**  
`first player,random picker,decision,party game,group chooser,turn order,finger`

**Description**

> Settle one question without an argument: who goes first? Everyone places one finger on the screen. Who's First? waits for the group, builds the suspense with color and haptics, then chooses one person at random.
>
> • Fair on-device random selection  
> • Real iPhone haptic feedback  
> • Fast replay for the next group  
> • Works offline  
> • No accounts, ads, analytics, or tracking
>
> Perfect for board games, chores, teams, classroom turns, or any moment when the group needs one simple answer.

**Privacy Policy URL**  
`https://brianrenshaw.github.io/chooser-web-app/privacy.html`

**Support URL**  
`https://brianrenshaw.github.io/chooser-web-app/support.html`

Those URLs will become live after these web changes are committed and pushed to `main` and the Pages workflow succeeds.

## Suggested App Review notes

> Who's First? is a focused, offline group utility. To test it, place two or more fingers on the iPhone screen simultaneously and keep them down. The app waits briefly for late participants, runs an accelerating visual and native-haptic countdown, then selects one active finger using on-device randomness. Lift and place fingers again for a new round. No login, network connection, permissions, purchases, or user data are involved. A physical multi-touch iPhone is required to experience the core interaction and Taptic feedback.

## Screenshot plan

Use actual app captures, without Safari chrome:

1. **Everyone in** — three or four distinct neon rings; caption: “Everyone puts a finger in.”
2. **Feel the countdown** — active pulsing rings; caption: “Hold on. The tension builds.”
3. **We have a winner** — one bright winner ring and the replay guidance; caption: “That finger goes first.”
4. Optional help view — caption: “No setup. No accounts. Just choose.”

## Shortest path from here

1. Sign in to App Store Connect and create the prepared iOS app record.
2. Deploy the Pages update so the privacy and support URLs are live.
3. Run physical-device QA and capture the real screenshots.
4. Rebuild from the final committed tree and upload build 1 to TestFlight.
5. Test the processed TestFlight build, complete metadata/privacy/age rating, and submit.
