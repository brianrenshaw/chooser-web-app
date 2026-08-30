# Who's First? — App Store Metadata

This file is the source of truth for the English (U.S.) App Store listing. The copy and App Review notes below are applied and verified in App Store Connect.

## Product identity

- App Store name: `Who's First? Decide Together`
- Home Screen / in-app name: `Who's First?`
- Bundle ID: `com.brianrenshaw.fingerchooser`
- SKU: `finger-chooser-ios`
- Version: `1.0`
- Build: `4`
- Build status: `VALID`, attached to version 1.0
- Version status: `PREPARE_FOR_SUBMISSION` — not submitted
- Minimum OS: `iOS 18.0`
- Primary category: Utilities
- Platform: iPhone only
- Price: Free
- Copyright: `2026 Brian Renshaw`

## App Store copy

### Subtitle

Pick who goes first

### Promotional text

Choose with simultaneous fingers, let a big group Tap In, or watch a fair Pinball run decide by where it truly stops. Private, offline, and made for iPhone.

### Description

Settle one question without an argument: who goes first?

Pick the way that fits the moment:

• Together — everyone holds one finger on the screen at the same time
• Tap In — each person taps once to join a numbered group of up to 50
• Pinball — 2–12 people tap near their seats, then a glowing ball races, bounces, and stops in one mathematically equal region

Who’s First? builds the suspense with neon color, native sound, and strong iPhone haptics. In Pinball, the ball’s real final position determines the result—there is no secretly preselected winner.

• Three playful ways to make one group decision
• Secure on-device randomness and mathematically equal Pinball regions
• True simultaneous multitouch in Together
• Numbered participants, so color is never the only identifier
• Portrait and landscape support
• Works completely offline
• No accounts, ads, analytics, or tracking

Great for board games, classrooms, chores, teams, family decisions, and any moment when the group needs one clear answer.

### Keywords

`first player,random chooser,group decision,board game,turn order,party,classroom,pinball`

## URLs and contact

- Support URL: `https://brianrenshaw.github.io/chooser-web-app/support.html`
- Marketing URL: `https://brianrenshaw.github.io/chooser-web-app/`
- Privacy Policy URL: `https://brianrenshaw.github.io/chooser-web-app/privacy.html`
- Support email: `contact@foliohtml.com`

## App Review notes

Who's First? is a focused, offline, native iPhone utility with three modes. It requires iOS 18 or later. A fresh install opens in Together; a long press on the upper-left mode icon saves the current mode as the next launch default. A normal tap on that icon cycles Together → Tap In → Pinball.

Together: place two or more fingers on the iPhone screen simultaneously and keep them down. The app waits briefly for late participants, runs an accelerating visual and native-haptic countdown, then selects one active finger using on-device randomness. Lift every finger and place them again for a new round.

Tap In: tap the small mode icon in the upper-left, then have each participant tap once. The icon changes to a 1–2–3 trail, and the app creates sequential numbered entries. After at least two entries are committed, tap Pick from N for a one-second countdown and an on-device random result. Pick again draws from the same group and may repeat a previous winner. Undo removes the newest entry, Clear requires confirmation, and New group clears all entries while staying in Tap In. The limit is 50 entries.

Pinball: cycle the mode icon again. Place the iPhone flat and have 2–12 people tap nearest where they are seated. Start runs an approximately five-second analytic, frame-rate-independent bouncing path. The ball crosses scoring boundaries freely and only bounces at the playfield edges. The region containing its actual final point wins. Every region has exactly equal area, the starting point is sampled uniformly with secure system randomness, and no winner is preselected. Play again keeps the seats and permits a repeat winner; New group clears them. The accessible seat-count menu provides a nonspatial setup option. Reduce Motion computes the same fair endpoint without replaying the moving flight.

About, Help, and Privacy are bundled native screens and remain available without a connection. The public Support and Privacy links open only when the reviewer explicitly selects them.

No login, required network connection, permissions, purchases, advertising, or data collection are involved. Finger positions, Tap In entries, Pinball seats, paths, and results are temporary in-memory interaction state only; they are not names, persisted profiles, or transmitted data. Only the user's preferred launch mode is stored locally. A physical multi-touch iPhone is required to fully test Together, Core Haptics, and device audio behavior.

## App privacy

- Data collection: No, this app does not collect data
- Temporary processing: Together touch points, Tap In entries, Pinball seats, paths, and results are held only in memory while the app is running
- Persistence: Only the preferred launch mode is stored locally; no names, profiles, participant history, saved groups, or results are saved
- Tracking: No
- Advertising identifier: No
- Third-party content: No
- Encryption export compliance: Uses no non-exempt encryption

## Age rating answers

All content-frequency fields: `NONE`

- Advertising: No
- Gambling: No
- Loot boxes: No
- Messaging or chat: No
- Parental controls: No
- Age assurance: No
- Social media: No
- Unrestricted web access: No
- User-generated content: No
- Developer age-rating information URL: Not applicable
- Rating override: None

Expected rating: 4+

## Screenshot set

Six marketing screenshots in `app-store-assets/screenshots/iphone-6.9-inch/` are applied and verified in App Store Connect. They show the current native visual system without browser or simulator chrome and cover all three modes:

1. `01-together.png` — `Use one finger to touch the iPhone.`
2. `02-tap-in.png` — `Big group? Take turns tapping.`
3. `03-pinball-setup.png` — `Tap the seats. Then let it roll.`
4. `04-pinball-run.png` — `A real path. A real landing.`
5. `05-pinball-winner.png` — `Where it stops decides who starts.`
6. `06-private-offline.png` — `Private. Offline. No accounts.`

Every image has been visually inspected and is a 1320 × 2868 RGB PNG with no alpha. The six-image set replaced the older Together-only screenshots in the 6.9-inch iPhone portrait slot, and its order was verified after processing.

## Private review contact

The required App Review and TestFlight contact details are complete in App Store Connect. The private phone number is intentionally not duplicated in this repository.
