# Who's First? — App Store Readiness

Last audited: August 30, 2026

## Bottom line

Who's First? is a working native-wrapped iPhone app, not merely an idea or a web-only prototype. The two-mode source is implemented and the local Xcode project is version 1.0 (build 2). Debug, Release, signed archive, App Store IPA export, and Apple server-side validation all passed with Xcode 26.6 for the earlier Together-only build 1. App Store Connect still has that valid TestFlight 1.0 (build 1), the record `Who's First? Decide Together`, English listing copy, a 4+ age declaration, Utilities category, and four processed 6.9-inch screenshots.

The planned v1 now offers two ways to make the same narrow choice: simultaneous fingers in Together, or sequential numbered entries in Tap In. Scoring, scoreboards, named profiles, player history, and game management remain out of scope.

Uploaded build 1 and its screenshots predate Tap In and should no longer be submitted as the planned v1. A five-image 6.9-inch replacement set covering both modes is prepared locally. Local build 2 still needs a fresh archive and TestFlight validation, the revised copy and screenshots uploaded to App Store Connect, and physical-device QA.

## What is ready

| Area | Status |
|---|---|
| Together picker | Complete in build 1: multi-touch rings, 1.5-second settling window, countdown, random winner, replay, audio fallback |
| Tap In picker | Implemented locally: sequential numbered entries up to 50, Undo, confirmed Clear, explicit Pick from N, Pick again, and New group; not present in TestFlight build 1 |
| Mode control | One compact animated icon toggle switches modes; its Together-orbit and numbered Tap In artwork reflects the active mode and accessible text announces the destination |
| Native value | Complete: bundled offline app and Capacitor Taptic Engine feedback |
| Compatibility | iOS 14+ color fallback added; modern WebKit uses OKLCH |
| iOS project | Capacitor 7.6.8, iPhone-only, bundle `com.brianrenshaw.fingerchooser`, version 1.0 (build 2 locally) |
| Validated build | Debug simulator, Release device, signed archive, App Store IPA export, and Apple validation passed for build 1 in Xcode 26.6; build 2 has not yet replaced it in TestFlight |
| Signing | Valid Apple Development and Apple Distribution identities plus development and App Store profiles for team `2LZJMJR6V8` |
| Apple registration | `com.brianrenshaw.fingerchooser` is registered under paid team `2LZJMJR6V8` |
| Branding | Neon-ring native icon, touch icon, and black launch screen replace Capacitor defaults |
| Privacy | No accounts, ads, analytics, tracking, persistent storage, or network calls; Tap In numbers, colors, identifiers, and tap positions are temporary in-memory state; app privacy manifest declares no collection and “Data Not Collected” is published in App Store Connect |
| Public pages | Privacy and support are live on GitHub Pages and list `contact@foliohtml.com` |
| In-app disclosure | Help/About dialog links to privacy and support from the main screen |
| Dependencies | Production and full npm audits report zero known vulnerabilities |
| App Store listing | Repository metadata and five 1320×2868 replacement screenshots cover both modes; App Store Connect still has the build 1 copy and four Together-only screenshots |
| Pricing and availability | Free in all 175 storefronts; Mac and Apple Vision Pro compatibility distribution disabled for an iPhone-only release |
| Review contact | Private App Review and TestFlight contact details are complete in App Store Connect |
| TestFlight | 1.0 (build 1) uploaded and processed as `VALID`, but it is Together-only and is superseded for the planned two-mode v1 |

## What still blocks submission

1. **Ship local build 2 to TestFlight.** Archive, export, validate, upload, and select the processed two-mode build in App Store Connect.
2. **Run current physical-device QA.** Re-test Together with two through five fingers, late joiners, finger removal, replay, background/foreground behavior, audio, and native haptics. Test Tap In with 2, 6, and 50 entries; one entry per gesture; Undo and number reuse; Clear cancel/confirm; disabled Pick below two entries or during a pending tap; Pick again with allowed repeats; New group; Help/About preservation; and backgrounding during collection and countdown.
3. **Refresh the product page.** Apply the two-mode description and review notes from `app-store-assets/metadata.md`, then upload the prepared five-image screenshot set in place of the Together-only images.
4. **Approve submission.** The final Submit for Review action remains a deliberate owner approval.

## Current Apple requirements that matter

- Since April 28, 2026, iOS uploads must be built with Xcode 26 or later and the iOS 26 SDK. This machine has Xcode 26.6 and the project passes Release compilation. See [Apple’s SDK minimum requirement](https://developer.apple.com/news/upcoming-requirements/?id=02032026a).
- Apple requires a privacy-policy URL for every iOS app and an easily accessible policy link inside the app. See [App privacy](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/) and [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/).
- Apple allows one to ten screenshots. The current accepted 6.9-inch iPhone sizes include 1320×2868, 1290×2796, and 1260×2736 portrait pixels. See [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).
- The largest review risk is Guideline 4.2, Minimum Functionality. The review notes should explicitly explain both group interactions, native multi-touch and haptics, the up-to-50-person Tap In flow, offline operation, privacy, and focused utility.

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
`first player,random chooser,group decision,board game,turn order,party,classroom,chores,tap picker`

**Description**

> Settle one question without an argument: who goes first? Choose Together with simultaneous fingers, or use Tap In so each person can join a numbered group one tap at a time. Who's First? builds the suspense with color and haptics, then chooses one finger or number at random.
>
> - Two simple ways to make one group decision
> - Fair on-device random selection
> - Real iPhone haptic feedback
> - Undo, Pick again, and New group controls
> - Works offline
> - No accounts, ads, analytics, or tracking
>
> Perfect for board games, chores, teams, classroom turns, or any moment when the group needs one simple answer.

**Privacy Policy URL**  
`https://brianrenshaw.github.io/chooser-web-app/privacy.html`

**Support URL**  
`https://brianrenshaw.github.io/chooser-web-app/support.html`

All three URLs are live on GitHub Pages and return HTTP 200.

## Suggested App Review notes

> Who's First? is a focused, offline group utility with Together and Tap In modes. A fresh launch opens Together. In Together, hold two or more fingers on the screen; after the settling window and countdown, one active finger is selected. In Tap In, each person taps once to create a sequential numbered entry; after at least two entries, tap Pick from N for a one-second countdown and random number. Pick again reuses the same pool and may repeat. Undo removes the newest entry, Clear asks for confirmation, and New group clears the entries while staying in Tap In. No login, network connection, permissions, purchases, advertising, persistent profiles, or data collection are involved. Tap In state is temporary and in memory only. A physical multi-touch iPhone is required to fully test Together and Taptic feedback.

## Screenshot plan

The prepared five-image set in `app-store-assets/screenshots/iphone-6.9-inch/` is ready to replace the Together-only App Store Connect images:

1. **Two modes** — compact mode icon toggle visible; caption: “Together or one tap at a time.”
2. **Together** — several active rings during the countdown; caption: “Everyone touches. The tension builds.”
3. **Tap In group** — a centered grid of numbered rings; caption: “One tap each. Everyone gets a number.”
4. **Tap In result** — one glowing winner number with replay controls; caption: “One fair choice. That's who's first.”
5. Optional Help/About or privacy view — caption: “No setup. No accounts. Just choose.”

## Shortest path from here

1. Archive, validate, and upload local build 2, then wait for it to process in TestFlight.
2. Upload the prepared Together/Tap In screenshots; update the listing and review notes.
3. Install and test processed build 2 on a physical iPhone.
4. Review the finished product page and approve the final Submit for Review action.

Apple accepted build 1 with no errors and one forward-looking warning: beginning in spring 2027, new uploads must target iOS 15 or later. Version 1.0 currently supports iOS 14 and remains valid for submission in 2026. The Xcode project is now build 2 locally, but App Store Connect and TestFlight still contain only build 1, which does not include Tap In and should not be submitted for the planned two-mode release.
