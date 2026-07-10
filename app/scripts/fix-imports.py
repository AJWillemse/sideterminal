#!/usr/bin/env python3
"""Add missing module imports to vendored Ghostty Swift files.

Ghostty's Xcode target exposes Foundation/AppKit implicitly through its
bridging header; SwiftPM has no bridging headers, so files need explicit
imports. This parses `swift build` errors and prepends the right imports.
"""
import re
import subprocess
import sys
from collections import defaultdict

# Symbol prefix -> module. Checked in order.
SYMBOL_MODULES = [
    (re.compile(r"^(NS[A-Z]|CATransaction|CALayer|CAMediaTiming)"), "AppKit"),
    (re.compile(r"^CG(Size|Float|Point|Rect|Vector)"), "Foundation"),
    (re.compile(r"^(UndoManager|FileManager|Notification|UserDefaults|Bundle|Data\b|URL\b|UUID|Timer|RunLoop|Process|Pipe|Host|Locale|TimeZone|Date\b|JSONEncoder|JSONDecoder|PropertyList|OperationQueue|DispatchQueue|CustomLocalizedStringResourceConvertible|LocalizedStringResource|AttributedString|NSString|IndexSet)"), "Foundation"),
    (re.compile(r"^(Logger|OSLog)"), "OSLog"),
    (re.compile(r"^(CAAnimation|CASpring|CABasic|CAShape)"), "QuartzCore"),
    (re.compile(r"^(UTType)"), "UniformTypeIdentifiers"),
    (re.compile(r"^(UNUserNotification|UNNotification|UNMutable)"), "UserNotifications"),
    (re.compile(r"^(ObjCExceptionCatcher|VibrantLayer)"), "GhosttyObjC"),
    (re.compile(r"^(MTL|MTK)"), "Metal"),
    (re.compile(r"^(kVK_|TIS|UCKeyboardLayout|CGEvent|CGS)"), "Carbon.HIToolbox"),
]

CANNOT_FIND = re.compile(
    r"^(/[^:]+\.swift):\d+:\d+: error: cannot find (?:type )?'([A-Za-z_][A-Za-z0-9_]*)' in scope"
)


def main():
    out = subprocess.run(
        ["swift", "build"], capture_output=True, text=True
    )
    text = out.stdout + out.stderr
    wanted = defaultdict(set)
    unknown = defaultdict(set)
    for line in text.splitlines():
        m = CANNOT_FIND.match(line)
        if not m:
            continue
        path, symbol = m.groups()
        if "/Vendor/" not in path:
            continue
        for pattern, module in SYMBOL_MODULES:
            if pattern.match(symbol):
                wanted[path].add(module)
                break
        else:
            unknown[path].add(symbol)

    changed = 0
    for path, modules in wanted.items():
        with open(path) as f:
            src = f.read()
        existing = set(re.findall(r"^import ([A-Za-z_.]+)", src, re.M))
        add = [m for m in sorted(modules) if m.split(".")[0] not in
               {e.split(".")[0] for e in existing}]
        # AppKit implies Foundation for most purposes but keep both explicit.
        if not add:
            continue
        lines = "".join(f"import {m}\n" for m in add)
        # Insert after any leading comment block, before first decl/import.
        m = re.search(r"^import ", src, re.M)
        if m:
            src = src[: m.start()] + lines + src[m.start():]
        else:
            m = re.search(r"^(?!//|\s*$)", src, re.M)
            pos = m.start() if m else 0
            src = src[:pos] + lines + "\n" + src[pos:]
        with open(path, "w") as f:
            f.write(src)
        changed += 1
        print(f"+ {','.join(add):40s} {path.split('/Vendor/')[-1]}")

    print(f"\n{changed} files updated")
    if unknown:
        print("\nUnmapped symbols:")
        for path, syms in sorted(unknown.items()):
            print(f"  {path.split('/Vendor/')[-1]}: {', '.join(sorted(syms))}")


if __name__ == "__main__":
    main()
