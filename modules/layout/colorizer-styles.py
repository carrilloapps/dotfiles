#!/usr/bin/env python3
"""Builds the Panel Colorizer styles for the macOS-like layout.

Reads the installed "Transparent" and "Translucent" presets, adjusts them and
prints three JSON strings (one per line) ready to embed in JavaScript:
  1. dock
  2. top bar, clear   (no maximized window)
  3. top bar, frosted (a window is maximized)

It also saves the two top bar styles as user presets, "RedRog Clear" and
"RedRog Frosted", in OUT_DIR so Panel Colorizer can switch between them.

Usage: colorizer-styles.py PRESETS_DIR WALLPAPER_LUMINANCE OUT_DIR
WALLPAPER_LUMINANCE (0-1) is the brightness of the top strip of the
wallpaper: over a light wallpaper the clear bar keeps a faint dark tint so the
white icons stay readable.
"""
import copy
import json
import os
import sys

base = sys.argv[1]
luminance = float(sys.argv[2])
out = sys.argv[3]

dock = json.load(open(f"{base}/Transparent/settings.json"))["globalSettings"]
# Dock: no native background or shadow, only the icons remain
dock["nativePanel"]["background"].update({"enabled": False, "opacity": 0, "shadow": False})
# 8 px bottom padding lifts the icons off the screen edge
dock["panel"]["normal"]["padding"] = {"enabled": True, "side": {"top": 0, "bottom": 8, "left": 6, "right": 6}}

frosted = json.load(open(f"{base}/Translucent/settings.json"))["globalSettings"]
# Frosted: window color at 35 % with blur behind, like the macOS menu bar
frosted["panel"]["normal"]["blurBehind"] = True
frosted["panel"]["normal"]["backgroundColor"]["alpha"] = 0.35
frosted["nativePanel"]["background"]["shadow"] = False
# The Arc style already reserves extra margin at the top of panels, so all the
# padding goes at the bottom to center the icons vertically (measured: 8 px each side)
frosted["panel"]["normal"]["padding"] = {"enabled": True, "side": {"top": 0, "bottom": 10, "left": 8, "right": 8}}

# Clear: same geometry, no blur, fully transparent over dark wallpapers and a
# faint dark tint over light ones. A soft shadow keeps text and icons readable.
clear = copy.deepcopy(frosted)
normal = clear["panel"]["normal"]
normal["blurBehind"] = False
# The native panel background keeps asking KWin for blur even at 0 % opacity,
# so it is turned off entirely for a sharp, see-through bar
clear["nativePanel"]["background"]["enabled"] = False
# (fully clear: redrog-panel-veil adds each screen's veil on top, from the
# wallpaper behind it)
normal["backgroundColor"]["alpha"] = 0.0
for part in (normal, clear["widgets"]["normal"]):
    part["shadow"]["foreground"]["enabled"] = True
    part["shadow"]["foreground"]["size"] = 4

for name, style in (("RedRog Clear", clear), ("RedRog Frosted", frosted)):
    os.makedirs(f"{out}/{name}", exist_ok=True)
    with open(f"{out}/{name}/settings.json", "w") as f:
        json.dump({"globalSettings": style}, f, indent=2)

for style in (dock, clear, frosted):
    print(json.dumps(json.dumps(style, separators=(",", ":"))))
