#!/bin/bash
# Builds libghostty (static) + resources for SideTerminal.
#
# Works on hosts with only Command Line Tools:
#  - tools/bin/xcrun points Zig at tools/shim-sdk, which mirrors the real SDK
#    but swaps in Zig's bundled libSystem.tbd (Zig 0.15.2 cannot parse the
#    macOS 26.5 SDK's libSystem.tbd).
#  - The Ghostty tree carries small patches: Metal shaders are embedded as
#    source and compiled at runtime, and build.zig installs the static lib
#    directly instead of requiring xcodebuild/xcframework.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export PATH="$ROOT/tools/bin:$PATH"
cd "$ROOT/ghostty"
exec "$ROOT/tools/zig-aarch64-macos-0.15.2/zig" build \
    -Dapp-runtime=none \
    -Doptimize=ReleaseFast \
    -Demit-xcframework=false \
    -Demit-macos-app=false \
    "$@"
