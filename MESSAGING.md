# Who’s First?: messaging reference

Approved with Brian on September 9, 2026. Read this before changing marketing copy, onboarding, About text, or other descriptions of the app. This document is self-contained and is the local reference for this app’s positioning. If the purpose changes, update this document and the shared website overview together.

## Customer and purpose

**Customer:** A group gathered to play a game that needs to choose the first player.

**Problem:** The group needs one quick choice. Subscriptions and extra features can make a small utility feel overcomplicated.

**Primary promise:** Quickly and fairly choose the first player so the group can get on with the game.

## Approved website copy

**Headline:** Choose who goes first. Get on with the game.

**Supporting copy:** Quickly and fairly pick your first player. Use fingers on the screen for up to five people, or choose a mode with room for a larger group.

Canonical app page: https://brianrenshaw.app/whos-first/

## Feature priorities

1. Choose the first player quickly and fairly.
2. Include the whole group: Chooser for two to five fingers, Tap In for up to 50 people, Pinball for two to twelve seats.
3. Free. No subscription. This is a firm owner commitment.
4. A little suspense, visual variety, and tactile feedback make the choice fun without expanding the app’s purpose.

## Commitments and factual boundaries

- Free and no subscription is a firm commitment, not a temporary offer.
- Retain factual mode capacities and equal-odds behavior. Do not generalize a device touch limit into an unverified claim about every Apple device.
- Do not describe complete turn ordering, teams, brackets, or other functions the app does not provide.
- Keep physics, geometry, randomness internals, and visual-material descriptions out of store copy. Preserve accurate operational help where useful.
- iPad support was verified on September 18, 2026 and the website now says "For iPhone and iPad". Evidence: live version 1.2 reports `iosUniversal` with 80 iPad devices, its App Store listing carries six screenshots in iPad 3:4 aspect, and the Xcode project sets `TARGETED_DEVICE_FAMILY = "1,2"`. The store description may now claim iPhone and iPad.
- Keep the retired browser game retired. This messaging concerns the native app in this repository, not chooser-web-app-v2.

## App Store copy: prepared for next release

Status: prepared locally only. Not published or submitted. Locale: en-US.

### Subtitle

Pick your first player

### Promotional text

Choose who goes first and get on with the game. Pick with fingers, taps, or Pinball, with room for larger groups. Free. No subscription.

### Description

Who’s First? quickly and fairly picks your first player so you can get on with the game. It’s free, with no subscription, accounts, or ads.

- Chooser: two to five people hold a finger on the screen. One ring marks who goes first.
- Tap In: each person taps to join, then you pick from the group. There’s room for up to 50 people.
- Pinball: two to twelve people take their seats, then flick the ball to choose a player.
- Works offline, with support for VoiceOver, larger text, and reduced motion.

### Copy lengths

Description: 89 words. Subtitle: 22 characters. Promotional text: 136 characters.

## Native copy locations for the next app LLM

- `ios/App/App/Native/UI/NativeOfflineInfoScreens.swift`: `NativeOfflineInformationCopy.chooser(version:)` owns the About tagline, mode summaries, welcome lines, and help. Lead with the first-player outcome and free commitment. Keep mode instructions short.
- `ios/App/App/Native/UI/NativeWelcomeCarousel.swift`: consumes the shared mode copy. Preserve its compact header, three pages, IDs, and dismissal behavior; do not add a marketing paragraph to the constrained sheet.
- `ios/App/App/Native/UI/NativeModeIntroCard.swift`: check the instructions inherited from the shared copy. Keep a direct action for joining and choosing in each mode.
- `app-store-assets/metadata.md` contains historical submissions. Use this document for next-release copy; do not rewrite the historical record to imply it was previously submitted.

## Suggested in-app language

- About tagline: “Choose who goes first. Get on with the game.”
- About commitment: “Free. No subscription.”
- Chooser: “Hold a finger on the screen. One ring marks who goes first.”
- Tap In: “Each person taps once. When everyone’s in, tap Pick.”
- Pinball: “Add your seats, then flick the ball to pick the first player.”

## Verification after native copy changes

Run existing native onboarding, mode intro, and welcome layout checks after native edits. Review all three modes, replay, skip, large text, and VoiceOver labels. Do not change selection logic, timing, or launch defaults.

## Writing rules

- Use plain language and concrete customer benefits. No em dashes anywhere in authored copy.
- Put the main purpose first. Supporting features must help explain that purpose.
- App Store descriptions target 80 to 120 words, with a hard maximum of 150. Use one short opening and no more than four brief benefit bullets. Shorter is preferable to padding.
- Subtitle: at most 30 characters. Promotional text: at most 170 characters. Full description: at most 4,000 characters, but the tighter word limit above is authoritative for this project.
- Avoid exhaustive feature lists, developer jargon, repeated promises, inflated claims, and criticism of competitors.
- In-app copy should help someone act. Adapt the approved promise to the screen; do not paste the whole store description into onboarding.
- Preserve established control names and accurate help instructions. Do not change features to fit a sentence.

## Handoff boundaries

This pass updates website messaging and prepares documentation only. Native app source has not been updated from this reference. App Store text below is prepared for the next release and has not been saved to App Store Connect or submitted.

When asked to update native copy, inspect the current files and local instructions, preserve unrelated work, and change only the relevant text. Keep navigation, onboarding completion flags, policy versions, data, permissions, and app behavior intact. Do not force existing users through onboarding again.

Before using store copy for a release, verify supported platforms and current capabilities against that release. Apply the copy to the matching editable version through the existing release workflow. Publishing a website does not update the App Store or installed apps. Do not submit or upload a release merely because this document exists.

Apple references: [Product page guidance](https://developer.apple.com/app-store/product-page/) and [field specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information).
