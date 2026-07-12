#!/bin/bash
# Builds SideTerminal and assembles SideTerminal.app.
# Usage: bundle-app.sh [debug|release]  (default: release)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG="${1:-release}"
APP="$ROOT/build/SideTerminal.app"

cd "$ROOT/app"
swift build -c "$CONFIG"

BIN="$ROOT/app/.build/$CONFIG/SideTerminal"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BIN" "$APP/Contents/MacOS/SideTerminal"

# Sparkle.framework (auto-updates). SwiftPM vends it as a prebuilt
# xcframework artifact; Xcode's "Embed & Sign" build phase normally copies
# this in, but our build has no Xcode project, so we do it by hand. The
# framework ships pre-signed (ad-hoc + hardened runtime) by Sparkle itself,
# so it's copied as-is and never re-signed here — the final `codesign` below
# deliberately omits --deep so it doesn't touch (or break) this signature.
SPARKLE_FRAMEWORK="$(find "$ROOT/app/.build/artifacts" -iname 'Sparkle.framework' -path '*macos*' 2>/dev/null | head -1)"
if [ -z "$SPARKLE_FRAMEWORK" ]; then
    echo "error: Sparkle.framework not found — run 'swift package resolve' in app/ first." >&2
    exit 1
fi
mkdir -p "$APP/Contents/Frameworks"
cp -R "$SPARKLE_FRAMEWORK" "$APP/Contents/Frameworks/Sparkle.framework"

# Ghostty runtime resources (terminfo, shell integration, themes).
cp -R "$ROOT/ghostty/zig-out/share/ghostty" "$APP/Contents/Resources/ghostty"
cp -R "$ROOT/ghostty/zig-out/share/terminfo" "$APP/Contents/Resources/terminfo"

# App icon: the curated artwork in assets/ wins; fall back to the
# generated one (scripts/make-icon.swift) only if it's absent.
if [ -f "$ROOT/assets/AppIcon.icns" ]; then
    cp "$ROOT/assets/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
else
    if [ ! -f "$ROOT/build/AppIcon.icns" ]; then
        (cd "$ROOT/build" && swift "$ROOT/scripts/make-icon.swift" . \
            && iconutil -c icns AppIcon.iconset -o AppIcon.icns)
    fi
    cp "$ROOT/build/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
fi

# Monochrome template icon for the menu bar (scripts/make-menubar-icon.swift).
if [ -f "$ROOT/assets/MenuBarIcon.png" ]; then
    cp "$ROOT/assets/MenuBarIcon.png" "$ROOT/assets/MenuBarIcon@2x.png" \
        "$APP/Contents/Resources/"
fi

# GitHub mark for the About pane.
if [ -f "$ROOT/assets/GitHubMark.png" ]; then
    cp "$ROOT/assets/GitHubMark.png" "$APP/Contents/Resources/"
fi

# Version is stamped from the environment during a release; defaults keep
# local dev builds working (scripts/release.sh sets these from the tag).
APP_VERSION="${SIDETERMINAL_VERSION:-1.0.0}"
APP_BUILD="${SIDETERMINAL_BUILD:-1}"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleExecutable</key><string>SideTerminal</string>
    <key>CFBundleIdentifier</key><string>com.sideterminal.app</string>
    <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
    <key>CFBundleName</key><string>SideTerminal</string>
    <key>CFBundleDisplayName</key><string>SideTerminal</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${APP_VERSION}</string>
    <key>CFBundleVersion</key><string>${APP_BUILD}</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSPrincipalClass</key><string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key><true/>
    <key>SUFeedURL</key><string>https://raw.githubusercontent.com/bunnysayzz/sideterminal/main/appcast.xml</string>
    <key>SUPublicEDKey</key><string>sbR1ti8xhb35X33S7ABqU1SUlX/pGSr9DQlOL1Scdys=</string>
    <key>SUEnableAutomaticChecks</key><true/>
    <key>SUScheduledCheckInterval</key><integer>86400</integer>
    <key>SUAutomaticallyUpdate</key><false/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP"

echo "Built: $APP"
