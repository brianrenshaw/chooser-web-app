#!/bin/bash
# Capture the App Store screenshot set as real device captures.
#
# These are not mock-ups: every pixel is the app rendering itself on a
# simulator at native resolution. Run this per device class Apple requires.
#
#   scripts/capture-screenshots.sh "iPad Pro 13-inch (M5)" ipad-13-inch
#   scripts/capture-screenshots.sh "iPhone 17 Pro Max"     iphone-6.9-inch
#
# ScreenshotUITests skips itself unless CAPTURE_SCREENSHOTS=1 is in the test
# runner's environment, so an ordinary AppUITests run never captures anything.
# xcodebuild's TEST_RUNNER_* form is not honoured from the command line, so the
# variable is written into the generated .xctestrun instead — which is, in the
# end, the file that actually configures the runner.
set -euo pipefail

# A simulator NAME or UDID. Prefer a UDID: names are not unique — this machine
# has two simulators called "iPhone 17 Pro Max", and a name lookup here picked a
# different one than xcodebuild did, so the captures were written to one device
# and collected from the other.
DEVICE_NAME="${1:?usage: capture-screenshots.sh <simulator name or UDID> <output slug>}"
OUTPUT_SLUG="${2:?usage: capture-screenshots.sh <simulator name> <output slug>}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$REPO_ROOT/ios/App"
DERIVED="${DERIVED_DATA_PATH:-$PROJECT_DIR/.screenshot-build}"
if [[ "$DEVICE_NAME" =~ ^[0-9A-Fa-f-]{36}$ ]]; then
  DESTINATION="platform=iOS Simulator,id=$DEVICE_NAME"
  UDID="$DEVICE_NAME"
else
  DESTINATION="platform=iOS Simulator,name=$DEVICE_NAME"
  MATCHES="$(xcrun simctl list devices | grep -cF "$DEVICE_NAME (" || true)"
  if [ "$MATCHES" -gt 1 ]; then
    echo "error: $MATCHES simulators are named '$DEVICE_NAME'. Pass a UDID." >&2
    xcrun simctl list devices | grep -F "$DEVICE_NAME (" >&2
    exit 1
  fi
  UDID="$(xcrun simctl list devices | grep -F "$DEVICE_NAME (" \
    | grep -o "[0-9A-F-]\{36\}" | head -1)"
fi
OUTPUT_DIR="$REPO_ROOT/app-store-assets/screenshots/$OUTPUT_SLUG"
RUNNER_BUNDLE_ID="com.brianrenshaw.fingerchooser.uitests.xctrunner"

echo "==> Building test bundle"
xcodebuild build-for-testing \
  -project "$PROJECT_DIR/App.xcodeproj" \
  -scheme App \
  -configuration Debug \
  -destination "$DESTINATION" \
  -derivedDataPath "$DERIVED" \
  >/dev/null

XCTESTRUN="$(ls -t "$DERIVED"/Build/Products/*.xctestrun | head -1)"
echo "==> Arming capture in $(basename "$XCTESTRUN")"
/usr/libexec/PlistBuddy \
  -c "Add :TestConfigurations:0:TestTargets:1:EnvironmentVariables:CAPTURE_SCREENSHOTS string 1" \
  "$XCTESTRUN" 2>/dev/null \
  || /usr/libexec/PlistBuddy \
       -c "Set :TestConfigurations:0:TestTargets:1:EnvironmentVariables:CAPTURE_SCREENSHOTS 1" \
       "$XCTESTRUN"

echo "==> Capturing on $DEVICE_NAME"
xcodebuild test-without-building \
  -xctestrun "$XCTESTRUN" \
  -destination "$DESTINATION" \
  -only-testing:AppUITests/ScreenshotUITests \
  | grep -E "Test Case|error:|Executed" || true

# The simulator shuts down when the run ends, and `get_app_container` needs it
# booted. The captures are already on disk at this point; this only makes the
# container path resolvable.
xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b >/dev/null 2>&1 || true
CONTAINER="$(xcrun simctl get_app_container "$UDID" "$RUNNER_BUNDLE_ID" data)"

mkdir -p "$OUTPUT_DIR"
cp "$CONTAINER"/Documents/screenshots/*.png "$OUTPUT_DIR"/

echo "==> Wrote:"
for file in "$OUTPUT_DIR"/*.png; do
  echo "    $(basename "$file")  $(sips -g pixelWidth -g pixelHeight "$file" \
    | awk '/pixel/ {printf "%s ", $2}')"
done
