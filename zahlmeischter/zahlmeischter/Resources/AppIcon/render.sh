#!/usr/bin/env bash
# Render the app-icon concept HTML/SVG files to 1024x1024 PNGs via headless Chrome.
# Usage: ./render.sh [name ...]   (default: all three concepts)
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
OUT="$DIR/drafts"
mkdir -p "$OUT"

names=("$@")
if [ ${#names[@]} -eq 0 ]; then
  names=(origami glass split)
fi

for name in "${names[@]}"; do
  src="$DIR/${name}-z.html"
  png="$OUT/${name}-z-1024.png"
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars \
    --force-device-scale-factor=1 --window-size=1024,1024 \
    --default-background-color=00000000 \
    --screenshot="$png" "$src" >/dev/null 2>&1
  printf '%s -> ' "$name"
  sips -g pixelWidth -g pixelHeight "$png" | awk '/pixel/{printf "%s ", $2} END{print ""}'
done
echo "Rendered to $OUT"
