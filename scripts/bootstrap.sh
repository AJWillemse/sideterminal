#!/bin/bash
# One-time setup for building SideTerminal from a fresh clone.
#
# Prepares everything the committed source doesn't carry (it's downloaded or
# generated, so it stays out of git):
#   1. Ghostty engine source, pinned + patched.
#   2. The Zig 0.15.2 toolchain.
#   3. tools/shim-sdk — the CLT SDK with Zig's libSystem.tbd swapped in.
#
# Re-running is safe: each step is skipped if already done. Pass --force to
# rebuild from scratch.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GHOSTTY_COMMIT="7cb44fea332efa74e3843e531fd1aa4e764a8e4d"
ZIG_VERSION="0.15.2"
ZIG_DIR="$ROOT/tools/zig-aarch64-macos-$ZIG_VERSION"
ZIG_URL="https://ziglang.org/download/$ZIG_VERSION/zig-aarch64-macos-$ZIG_VERSION.tar.xz"

FORCE=0
[ "${1:-}" = "--force" ] && FORCE=1

log() { printf '\033[1;36m==>\033[0m %s\n' "$1"; }

if [ "$(uname -sm)" != "Darwin arm64" ]; then
    echo "error: SideTerminal currently builds only on Apple Silicon macOS." >&2
    exit 1
fi
if ! xcode-select -p >/dev/null 2>&1; then
    echo "error: Xcode Command Line Tools are required. Run: xcode-select --install" >&2
    exit 1
fi

# --- 1. Ghostty engine -------------------------------------------------------
if [ "$FORCE" = 1 ]; then rm -rf "$ROOT/ghostty"; fi
if [ ! -d "$ROOT/ghostty/.git" ]; then
    log "Cloning Ghostty @ ${GHOSTTY_COMMIT:0:10}"
    git clone --filter=blob:none https://github.com/ghostty-org/ghostty "$ROOT/ghostty"
    git -C "$ROOT/ghostty" checkout --quiet "$GHOSTTY_COMMIT"
    log "Applying SideTerminal patches"
    git -C "$ROOT/ghostty" apply "$ROOT"/patches/*.patch
else
    log "Ghostty already present (skipping clone)"
fi

# --- 2. Zig toolchain --------------------------------------------------------
if [ "$FORCE" = 1 ]; then rm -rf "$ZIG_DIR"; fi
if [ ! -x "$ZIG_DIR/zig" ]; then
    log "Downloading Zig $ZIG_VERSION"
    curl -fL "$ZIG_URL" -o "$ROOT/tools/zig.tar.xz"
    tar -xf "$ROOT/tools/zig.tar.xz" -C "$ROOT/tools"
    rm -f "$ROOT/tools/zig.tar.xz"
else
    log "Zig $ZIG_VERSION already present (skipping download)"
fi

# --- 3. shim-sdk -------------------------------------------------------------
# Mirror the real CLT SDK but swap in Zig's bundled libSystem.tbd, which
# Zig 0.15.2 can actually parse. Symlinks keep this tiny and always current
# with the installed CLT.
SDK="$(/usr/bin/xcrun --show-sdk-path)"
SHIM="$ROOT/tools/shim-sdk"
log "Building shim-sdk from $SDK"
rm -rf "$SHIM"
mkdir -p "$SHIM/usr/lib"
for entry in "$SDK"/*; do
    name="$(basename "$entry")"
    [ "$name" = "usr" ] && continue
    ln -s "$entry" "$SHIM/$name"
done
for entry in "$SDK/usr"/*; do
    name="$(basename "$entry")"
    [ "$name" = "lib" ] && continue
    ln -s "$entry" "$SHIM/usr/$name"
done
for entry in "$SDK/usr/lib"/*; do
    name="$(basename "$entry")"
    [ "$name" = "libSystem.tbd" ] && continue
    ln -s "$entry" "$SHIM/usr/lib/$name"
done
cp "$ZIG_DIR/lib/libc/darwin/libSystem.tbd" "$SHIM/usr/lib/libSystem.tbd"

log "Bootstrap complete. Next:"
echo "    scripts/build-libghostty.sh    # build the engine"
echo "    scripts/bundle-app.sh release  # -> build/SideTerminal.app"
