#!/usr/bin/env bash

set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_svg="$project_root/web/icon.svg"
app_icon="$project_root/ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png"
splash_dir="$project_root/ios/App/App/Assets.xcassets/Splash.imageset"
touch_icon="$project_root/web/apple-touch-icon.png"
asset_temp_dir="$(mktemp -d)"

cleanup() {
  rm -r "$asset_temp_dir"
}
trap cleanup EXIT

# Quick Look preserves the SVG glow while rendering a full-resolution source.
qlmanage -t -s 1024 -o "$asset_temp_dir" "$source_svg" >/dev/null
rendered_icon="$asset_temp_dir/icon.svg.png"

# App Store icons cannot contain alpha. Composite the rendered art over black.
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i color=c=black:s=1024x1024:d=1 \
  -i "$rendered_icon" \
  -filter_complex "[1:v]scale=1024:1024[icon];[0:v][icon]overlay=0:0:format=auto,format=rgb24" \
  -frames:v 1 "$app_icon"

ffmpeg -hide_banner -loglevel error -y \
  -i "$app_icon" \
  -vf "scale=180:180:flags=lanczos,format=rgb24" \
  -frames:v 1 "$touch_icon"

# The square splash image is aspect-filled by the launch storyboard. Keeping the
# mark compact here produces a centered neon ring on both portrait and landscape.
ffmpeg -hide_banner -loglevel error -y \
  -f lavfi -i color=c=black:s=2732x2732:d=1 \
  -i "$app_icon" \
  -filter_complex "[1:v]scale=720:720:flags=lanczos[mark];[0:v][mark]overlay=(W-w)/2:(H-h)/2:format=auto,format=rgb24" \
  -frames:v 1 "$splash_dir/splash-2732x2732.png"

cp "$splash_dir/splash-2732x2732.png" "$splash_dir/splash-2732x2732-1.png"
cp "$splash_dir/splash-2732x2732.png" "$splash_dir/splash-2732x2732-2.png"

echo "Generated opaque iOS icon, touch icon, and splash assets."
