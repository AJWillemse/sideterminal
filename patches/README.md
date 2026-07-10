# Ghostty patches

SideTerminal builds on the upstream [Ghostty](https://github.com/ghostty-org/ghostty)
terminal engine, pinned to commit `7cb44fea332efa74e3843e531fd1aa4e764a8e4d`.

Three small patches adapt Ghostty's build to hosts that have only the Xcode
Command Line Tools (no full Xcode, no offline Metal compiler). They change
**how the engine is built**, not how the terminal behaves — rendering, input,
and performance remain pure Ghostty.

| Patch | File | What it does |
|-------|------|--------------|
| `0001-embed-metal-shader-source.patch` | `src/build/SharedDeps.zig` | Embeds `shaders.metal` as source instead of a precompiled `.metallib`. |
| `0002-runtime-metal-shader-compile.patch` | `src/renderer/metal/shaders.zig` | Compiles that shader source at runtime via `newLibraryWithSource:` (the GPU driver caches the result after first launch). |
| `0003-darwin-install-static-lib.patch` | `build.zig` | Installs the static `libghostty.a` + resources directly, without the `xcodebuild`-built xcframework. |

`scripts/bootstrap.sh` clones Ghostty at the pinned commit and applies these
automatically. To apply them by hand:

```bash
cd ghostty
git apply ../patches/*.patch
```
