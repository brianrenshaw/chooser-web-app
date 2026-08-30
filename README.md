# Who's First?

Who's First? answers one question: **who goes first?** It offers two ways to make the same fair, on-device choice:

- **Together** — two or more people hold one finger on the screen at the same time, wait through a short haptic countdown, and one finger is chosen.
- **Tap In** — people tap once in sequence to join a numbered group, then someone taps **Pick from N** to choose one number.

Every fresh launch starts in Together. A single compact icon in the upper-left toggles between Together and Tap In, changing its artwork to show the active mode. Tap In supports up to 50 temporary entries, with Undo, confirmed Clear, Pick again, and New group controls. It is still a chooser—not a scoreboard, player tracker, or game manager.

The same framework-free source in `web/` runs as a [live browser app](https://brianrenshaw.github.io/chooser-web-app/) and inside the Capacitor iOS shell. The native version adds real Taptic Engine feedback and works offline.

## Current status

The two-mode source is implemented, and the local Xcode project is version 1.0 (build 2). The earlier Together-only build passed iOS Debug, Release, signed archive, App Store export, and Apple package validation with Xcode 26.6. App Store Connect still has that TestFlight 1.0 (build 1), its English listing, age rating, Utilities category, and four 6.9-inch screenshots.

Uploaded build 1 and its screenshots predate Tap In. A five-image 6.9-inch replacement set is now prepared locally for Together and Tap In, but it has not been uploaded. Local build 2 still needs a fresh archive, validation, and TestFlight upload, App Store Connect copy/screenshot updates, and physical-device QA before submission. Build 1 should not be submitted as the planned two-mode v1.

See [App Store readiness](docs/app-store-readiness.md) for the completed work, remaining decisions, draft listing copy, and exact submission path.

## Run locally

Requires Node.js 20 or newer.

```bash
npm install
python3 -m http.server 8765 --directory web
```

Open `http://localhost:8765`. Tap In can be exercised with one pointer at a time, but a real touch device is required to test Together's simultaneous fingers and the native haptic experience.

## Run on iOS

```bash
npm run cap:sync
npm run cap:open
```

Open the `App` workspace target in Xcode, select a physical iPhone, and run. Use the `.xcworkspace`, not the `.xcodeproj`.

## Useful checks

```bash
npm run check
npm audit
```

Regenerate the native icon, touch icon, and splash art from `web/icon.svg` with:

```bash
./scripts/generate-ios-assets.sh
```

That asset script requires the macOS Quick Look tools and `ffmpeg`.
