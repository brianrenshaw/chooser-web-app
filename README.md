# Who's First?

Who's First? answers one question: **who goes first?** Two or more people place one finger on the screen, wait through a short haptic countdown, and one finger is chosen at random.

The same framework-free source in `web/` runs as a [live browser app](https://brianrenshaw.github.io/chooser-web-app/) and inside the Capacitor iOS shell. The native version adds real Taptic Engine feedback and works offline.

## Current status

The picker is functional, the web version is deployed, and the iOS Debug, Release, signed archive, App Store export, and Apple package validation pass with Xcode 26.6. App Store Connect has the English listing, age rating, Utilities category, four 6.9-inch screenshots, and a valid TestFlight 1.0 (build 1). Final owner-only App Store Connect confirmations and physical-device QA remain before submission.

See [App Store readiness](docs/app-store-readiness.md) for the completed work, remaining decisions, draft listing copy, and exact submission path.

## Run locally

Requires Node.js 20 or newer.

```bash
npm install
python3 -m http.server 8765 --directory web
```

Open `http://localhost:8765`. A real touch device is required to test simultaneous fingers.

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
