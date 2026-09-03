#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
icon_document="$project_root/ios/App/App/AppIcon.icon"
splash_dir="$project_root/ios/App/App/Assets.xcassets/Splash.imageset"
touch_icon="$project_root/web/apple-touch-icon.png"
asset_temp_dir="$(mktemp -d)"
developer_dir="${DEVELOPER_DIR:-$(xcode-select -p)}"
ictool="$(dirname "$developer_dir")/Applications/Icon Composer.app/Contents/Executables/ictool"

cleanup() {
  rm -r "$asset_temp_dir"
}
trap cleanup EXIT

# The adaptive app icon is authored in Icon Composer and compiled directly by
# Xcode. Export its default rendition only as the source for the web touch icon
# and launch artwork; never recreate a competing raster AppIcon asset catalog.
if [[ ! -x "$ictool" ]]; then
  echo "Icon Composer's ictool was not found under $developer_dir" >&2
  exit 1
fi

rendered_icon="$asset_temp_dir/AppIcon-Default.png"
"$ictool" "$icon_document" \
  --export-image \
  --output-file "$rendered_icon" \
  --platform iOS \
  --rendition Default \
  --width 1024 \
  --height 1024 \
  --scale 1 >/dev/null

ffmpeg -hide_banner -loglevel error -y \
  -i "$rendered_icon" \
  -vf "scale=180:180:flags=lanczos,format=rgb24" \
  -frames:v 1 "$touch_icon"

# The square splash image is aspect-filled by the launch storyboard. Keeping the
# mark compact here produces a centered neon ring on both portrait and landscape.
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i color=c=black:s=2732x2732:d=1 \
  -i "$rendered_icon" \
  -filter_complex "[1:v]scale=720:720:flags=lanczos[mark];[0:v][mark]overlay=(W-w)/2:(H-h)/2:format=auto,format=rgb24" \
  -frames:v 1 "$splash_dir/splash-2732x2732.png"

cp "$splash_dir/splash-2732x2732.png" "$splash_dir/splash-2732x2732-1.png"
cp "$splash_dir/splash-2732x2732.png" "$splash_dir/splash-2732x2732-2.png"

echo "Generated the web touch icon and splash assets from AppIcon.icon."
