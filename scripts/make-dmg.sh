#!/bin/bash
# Package build/SideTerminal.app into a branded, drag-to-install DMG:
# custom background, positioned icons, an arrow to the Applications folder, and
# a chromeless window (no sidebar/toolbar). Run after bundle-app.sh release.
#
# Uses dmgbuild, which writes the window layout directly into the image's
# .DS_Store — no Finder automation (unreliable on recent macOS). Falls back to
# a plain DMG if dmgbuild isn't available.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/build/SideTerminal.app"
DMG="$ROOT/build/SideTerminal.dmg"
BG="$ROOT/assets/dmg-background@2x.png"
SETTINGS="$ROOT/scripts/dmg-settings.py"

if [ ! -d "$APP" ]; then
    echo "error: $APP not found — run scripts/bundle-app.sh release first." >&2
    exit 1
fi
rm -f "$DMG"

# Find dmgbuild (may be a pip --user install not on PATH).
DMGBUILD=""
if command -v dmgbuild >/dev/null 2>&1; then
    DMGBUILD="dmgbuild"
elif [ -x "$(python3 -m site --user-base 2>/dev/null)/bin/dmgbuild" ]; then
    DMGBUILD="$(python3 -m site --user-base)/bin/dmgbuild"
fi

if [ -n "$DMGBUILD" ] && [ -f "$BG" ]; then
    APP_PATH="$APP" DMG_BG="$BG" "$DMGBUILD" -s "$SETTINGS" "SideTerminal" "$DMG"
else
    echo "dmgbuild not found — building a plain DMG."
    echo "  install it with: python3 -m pip install --user dmgbuild"
    staging="$(mktemp -d)"
    cp -R "$APP" "$staging/SideTerminal.app"
    ln -s /Applications "$staging/Applications"
    hdiutil create -volname "SideTerminal" -srcfolder "$staging" \
        -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
    rm -rf "$staging"
fi

echo "Built: $DMG ($(du -h "$DMG" | cut -f1))"
