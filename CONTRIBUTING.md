# Contributing to SideTerminal

Thanks for your interest! SideTerminal is a small, focused macOS app, and
contributions of all sizes are welcome.

## Getting set up

```bash
git clone https://github.com/bunnysayzz/sideterminal
cd sideterminal
scripts/bootstrap.sh          # fetches Ghostty + Zig, builds the SDK shim
scripts/build-libghostty.sh   # builds the engine (slow the first time)
scripts/bundle-app.sh release # -> build/SideTerminal.app
open build/SideTerminal.app
```

Requirements: Apple Silicon Mac, macOS 14+, and the Xcode Command Line Tools
(`xcode-select --install`). A full Xcode install is **not** required.

## Ground rules

- **Don't reinvent the terminal.** Rendering, input, escape handling, and
  performance belong to the underlying engine. SideTerminal only owns the
  windowing and reveal/hide experience around it. Changes to
  `app/Sources/SideTerminal/Vendor/` (the vendored engine Swift layer) should
  be avoided — prefer upstreaming to the engine project instead.
- **Engine changes go through `patches/`.** If you must modify the engine
  build, add or update a patch file and document it in `patches/README.md`;
  never commit the fetched engine tree itself (it's git-ignored).
- **Keep it native.** Match the existing AppKit/SwiftUI style, spacing, and
  animation feel. The bar is "looks like Apple shipped it."
- **Verify before you push.** Build the app and exercise the actual behavior
  you changed (reveal/hide, settings applying live, sessions surviving hide).

## Pull requests

- Branch from `main`, keep PRs focused, and describe what you changed and why.
- Note anything you couldn't verify automatically (most UI behavior needs a
  human to watch it).

## Reporting bugs

Open an issue with your macOS version, whether you're on Apple Silicon, and
clear steps to reproduce. Screenshots or a short screen recording help a lot
for anything visual.
