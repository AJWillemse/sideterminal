# Third-Party Licenses

SideTerminal is built on open-source software. This file records the licenses
of components that are redistributed with, or that this project derives from.

---

## Ghostty

SideTerminal uses the [Ghostty](https://github.com/ghostty-org/ghostty)
terminal engine (`libghostty`) and vendors part of Ghostty's macOS Swift layer
(under `app/Sources/SideTerminal/Vendor/`). Ghostty is developed by Mitchell
Hashimoto and the Ghostty contributors and is licensed under the MIT License.

The engine source itself is not committed to this repository; it is fetched at
a pinned commit by `scripts/bootstrap.sh` (see `patches/README.md`). The
vendored Swift files that *are* committed remain under Ghostty's MIT License,
reproduced below.

```
MIT License

Copyright (c) 2024 Mitchell Hashimoto, Ghostty contributors

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## GitHub mark

`assets/GitHubMark.png` is the GitHub logo, used only to link to the project's
repository. It is a trademark of GitHub, Inc. and is used per GitHub's
[logo guidelines](https://github.com/logos). It is not covered by this
project's MIT License.
