#!/usr/bin/env python3
"""Writes RedRog's dialog backgrounds (notifications, menus, popups) from the
WhiteSur dialog background: rounded, with a hairline inner highlight, a light
hairline edge instead of WhiteSur's black outline, and blur masks, like macOS.

The base fill (#1a1a1a at 65 % in WhiteSur) becomes the palette color at the
given opacity. Writes DEST/translucent/dialogs/background.svgz (used when KWin can
blur behind) and DEST/dialogs/background.svgz (opaque fallback).
Usage: translucent.py SOURCE.svgz DEST_THEME_DIR HEXCOLOR OPACITY
"""
import gzip
import sys
from pathlib import Path

src, dest, color, opacity = sys.argv[1], Path(sys.argv[2]), sys.argv[3], sys.argv[4]
svg = gzip.decompress(Path(src).read_bytes()).decode()
base = "opacity:0.65;fill:#1a1a1a"
assert base in svg, "unexpected WhiteSur dialog background"

# The 0.75 px black outline in WhiteSur's shadow pieces reads as a dirty dark
# rim over a blurred, colorful background: a light hairline instead, as on
# the cards and windows (the soft shadow itself stays)
svg = svg.replace("opacity:0.75;fill:#000000", "opacity:0.12;fill:#ffffff")
svg = svg.replace('style="opacity:0.75"', 'style="opacity:0.12;fill:#ffffff"')

for subdir, alpha in (("translucent/dialogs", opacity), ("dialogs", "1")):
    out = dest / subdir / "background.svgz"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(gzip.compress(svg.replace(base, f"opacity:{alpha};fill:#{color}").encode()))
