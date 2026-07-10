#!/bin/bash
# Build assets/AppIcon.icns from the source artwork assets/sideterminal.png.
# Run whenever the app icon art changes.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$ROOT/assets/sideterminal.png"
OUT="$ROOT/assets/AppIcon.icns"
SET="$(mktemp -d)/AppIcon.iconset"

if [ ! -f "$SRC" ]; then
    echo "error: $SRC not found." >&2
    exit 1
fi

mkdir -p "$SET"
for s in 16 32 128 256 512; do
    sips -z "$s" "$s" "$SRC" --out "$SET/icon_${s}x${s}.png" >/dev/null
    d=$((s * 2))
    sips -z "$d" "$d" "$SRC" --out "$SET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$SET" -o "$OUT"
rm -rf "$(dirname "$SET")"
echo "Built: $OUT ($(du -h "$OUT" | cut -f1))"
