# Who's First? — App Store Readiness

Last audited: August 30, 2026

## Bottom line

Who's First? is a working native-wrapped iPhone app, not merely an idea or a web-only prototype. Debug, Release, signed archive, App Store IPA export, and Apple server-side validation all pass with Xcode 26.6. App Store Connect has the record `Who's First? Decide Together`, complete English listing copy, a 4+ age declaration, Utilities category, four processed 6.9-inch screenshots, and a valid TestFlight 1.0 (build 1) linked to the store version.

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
| Privacy | No accounts, ads, analytics, tracking, storage, or network calls; app privacy manifest declares no collection and “Data Not Collected” is published in App Store Connect |
| Public pages | Privacy and support are live on GitHub Pages and list `contact@foliohtml.com` |
| In-app disclosure | Help/About dialog links to privacy and support from the main screen |
| Dependencies | Production and full npm audits report zero known vulnerabilities |
| App Store listing | Name, subtitle, description, promotional text, keywords, URLs, copyright, content rights, category, and screenshots are populated |
| Pricing and availability | Free in all 175 storefronts; Mac and Apple Vision Pro compatibility distribution disabled for an iPhone-only release |
| Review contact | Private App Review and TestFlight contact details are complete in App Store Connect |
| TestFlight | 1.0 (build 1) uploaded, processed as `VALID`, export compliance recognized as false, and “What to Test” populated |

## What still blocks submission

1. **Run current physical-device QA.** Re-test two through five fingers, late joiners, finger removal, replay, background/foreground reset, audio, and native haptics on at least one current iPhone. Simulator and desktop browsers cannot validate true multi-touch or Taptic behavior.
2. **Approve submission.** The final Submit for Review action remains a deliberate owner approval.

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

All three URLs are live on GitHub Pages and return HTTP 200.

## Suggested App Review notes

> Who's First? is a focused, offline group utility. To test it, place two or more fingers on the iPhone screen simultaneously and keep them down. The app waits briefly for late participants, runs an accelerating visual and native-haptic countdown, then selects one active finger using on-device randomness. Lift and place fingers again for a new round. No login, network connection, permissions, purchases, or user data are involved. A physical multi-touch iPhone is required to experience the core interaction and Taptic feedback.

## Screenshot plan

Use actual app captures, without Safari chrome:

1. **Everyone in** — three or four distinct neon rings; caption: “Everyone touches the iPhone with one finger.”
2. **Feel the countdown** — active pulsing rings; caption: “Hold on. The tension builds.”
3. **We have a winner** — one bright winner ring and the replay guidance; caption: “That finger goes first.”
4. Optional help view — caption: “No setup. No accounts. Just choose.”

## Shortest path from here

1. Install and test the processed TestFlight build on a physical iPhone.
2. Review the finished product page and approve the final Submit for Review action.

Apple accepted build 1 with no errors and one forward-looking warning: beginning in spring 2027, new uploads must target iOS 15 or later. Version 1.0 currently supports iOS 14 and remains valid for submission in 2026.
