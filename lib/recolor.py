#!/usr/bin/env python3
"""Recolors Arc Dark theme files to the RedRog palette (config/redrog.conf and
config/user.conf).

Two rules, the same for every component (Kvantum, Plasma, Aurorae, GTK):
  - Accent blues (saturated): the hue is rotated to $ACCENT's while keeping
    lightness and saturation, so gradients and shadows keep working.
  - Arc's bluish grays become warm grays (tinted like $FG) through a lightness
    curve that maps $ARC_BASE exactly to $BG and $ARC_FG to $FG.

Formats: "#rrggbb", "rgb(a)(r, g, b...)", "r,g,b" triples (.colors) and PNG.
Usage: recolor.py SOURCE DEST   (a file or a whole directory)

Other base themes: set RECOLOR_BASE and RECOLOR_FG to their window gray and
text color (hex without "#") to use them as the anchors instead of Arc's, and
RECOLOR_HUE_MAX to widen the accent hue range (default 0.75, blue only) and
RECOLOR_WARMTH (0-1, default 1) to tone down the warm tint of the grays.
"""
import os
import colorsys
import re
import shutil
import subprocess
import sys
from pathlib import Path

CONFIG = Path(__file__).resolve().parent.parent / "config"


def pal(name):
    # the same palette as the installer: defaults, user overrides, variant
    script = f'REDROG_ROOT="{CONFIG.parent}"; source "$REDROG_ROOT/lib/palette.sh"; echo "${name}"'
    return subprocess.run(["bash", "-c", script],
                          capture_output=True, text=True, check=True).stdout.strip()


def hls(hexstr):
    return colorsys.rgb_to_hls(*(int(hexstr[i:i + 2], 16) / 255 for i in (0, 2, 4)))


ACCENT_HUE = hls(pal("ACCENT"))[0]
# Gray lightness: piecewise curve mapping Arc's base gray to $BG and its text
# color to $FG (0 and 1 stay fixed).
SRC_BASE = os.environ.get("RECOLOR_BASE") or pal("ARC_BASE")
SRC_FG = os.environ.get("RECOLOR_FG") or pal("ARC_FG")
HUE_MAX = float(os.environ.get("RECOLOR_HUE_MAX", "0.75"))
# (sorted: in a light theme the base gray is lighter than the text)
_L = sorted([(0.0, 0.0), (hls(SRC_BASE)[1], hls(pal("BG"))[1]),
             (hls(SRC_FG)[1], hls(pal("FG"))[1]), (1.0, 1.0)])
# Warm tint for the grays, taken from the text color ($FG)
WARM_HUE, _, WARM_SAT = hls(pal("FG"))
WARM_SAT *= float(os.environ.get("RECOLOR_WARMTH", "1"))


def map_l(l):
    for (x0, y0), (x1, y1) in zip(_L, _L[1:]):
        if l <= x1:
            return y0 + (y1 - y0) * (l - x0) / (x1 - x0)
    return l


def smoothstep(a, b, x):
    t = min(max((x - a) / (b - a), 0.0), 1.0)
    return t * t * (3 - 2 * t)


ARC_ACCENT = (0x52, 0x94, 0xE2)                            # Arc's main blue
ACCENT_RGB = tuple(int(pal("ACCENT")[i:i + 2], 16) for i in (0, 2, 4))


def map_rgb(r, g, b):
    """(0-255) -> (0-255), or None if the color is left unchanged."""
    if (r, g, b) == ARC_ACCENT:                            # exactly the configured accent
        return ACCENT_RGB
    h, l, s = colorsys.rgb_to_hls(r / 255, g / 255, b / 255)
    if s >= 0.35 and 0.5 < h < HUE_MAX:                   # accent blue
        h = ACCENT_HUE
    elif s < 0.35:                                         # Arc's (bluish) gray
        l = map_l(l)
        h, s = WARM_HUE, WARM_SAT * smoothstep(0.05, 0.9, l)
    else:
        return None
    return tuple(round(c * 255) for c in colorsys.hls_to_rgb(h, l, s))


def sub_hex(m):
    v = m.group(0)
    new = map_rgb(*(int(v[i:i + 2], 16) for i in (1, 3, 5)))
    return v if new is None else "#%02x%02x%02x" % new


def sub_func(m):
    r, g, b = (int(float(x)) for x in m.group(2, 3, 4))
    new = map_rgb(r, g, b)
    if new is None:
        return m.group(0)
    return f"{m.group(1)}({new[0]}, {new[1]}, {new[2]}{m.group(5)})"


def sub_triple(m):
    r, g, b = map(int, m.groups())
    if max(r, g, b) > 255:
        return m.group(0)
    new = map_rgb(r, g, b)
    return m.group(0) if new is None else "%d,%d,%d" % new


HEX = re.compile(r"#[0-9a-fA-F]{6}\b")
# "#rrggbbaa" too, when asked (RECOLOR_HEX8=1): the color changes, its alpha stays
HEX8 = re.compile(r"#[0-9a-fA-F]{8}\b")


def sub_hex8(m):
    v = m.group(0)
    new = map_rgb(*(int(v[i:i + 2], 16) for i in (1, 3, 5)))
    return v if new is None else "#%02x%02x%02x%s" % (*new, v[7:9])
FUNC = re.compile(r"\b(rgba?)\(\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)\s*,\s*(\d+(?:\.\d+)?)(\s*(?:,[^)]*)?)\)")
TRIPLE = re.compile(r"(?<![\d.])(\d{1,3}),(\d{1,3}),(\d{1,3})(?![\d.])")
TEXT_SUFFIXES = {".svg", ".css", ".kvconfig", ".colors", ".colorscheme", ".rc", ""}


def recolor_text(src, dst):
    text = src.read_text(errors="surrogateescape")
    if os.environ.get("RECOLOR_HEX8") == "1":
        text = HEX8.sub(sub_hex8, text)
    text = HEX.sub(sub_hex, text)
    text = FUNC.sub(sub_func, text)
    if src.suffix == ".colors" or src.name in ("colors",) or src.name.endswith("rc"):
        text = TRIPLE.sub(sub_triple, text)
    dst.write_text(text, errors="surrogateescape")


def recolor_png(src, dst):
    from PIL import Image
    im = Image.open(src).convert("RGBA")
    cache = {}
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a == 0:
                continue
            key = (r, g, b)
            if key not in cache:
                cache[key] = map_rgb(r, g, b) or key
            px[x, y] = (*cache[key], a)
    im.save(dst)


def recolor_file(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    if src.suffix == ".png":
        recolor_png(src, dst)
    elif src.suffix == ".svgz":
        import gzip
        tmp = dst.with_suffix(".svg.tmp")
        tmp.write_bytes(gzip.decompress(src.read_bytes()))
        recolor_text(tmp, tmp)
        dst.write_bytes(gzip.compress(tmp.read_bytes()))
        tmp.unlink()
    elif src.suffix in TEXT_SUFFIXES or src.name == "colors":
        recolor_text(src, dst)
    else:
        shutil.copy2(src, dst)


src, dst = map(Path, sys.argv[1:3])
if src.is_dir():
    for f in src.rglob("*"):
        if f.is_file():
            recolor_file(f, dst / f.relative_to(src))
        elif f.is_symlink():
            (dst / f.relative_to(src)).parent.mkdir(parents=True, exist_ok=True)
else:
    recolor_file(src, dst)
