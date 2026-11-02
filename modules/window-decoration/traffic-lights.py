#!/usr/bin/env python3
"""macOS-style (traffic light) window buttons for the RedRog Aurorae decoration.

Close is red, minimize yellow, maximize green; the glyph appears on hover and
all three turn gray in inactive windows. Writes close.svg, minimize.svg and
maximize.svg into the theme directory and adjusts the *rc layout (button size,
spacing and a taller, roomier title bar).
Usage: traffic-lights.py THEME_DIR
"""
import re
import sys
from pathlib import Path

THEME = Path(sys.argv[1])
SIZE = 14                      # px; centered 12 px circle
COLORS = {                     # fill, border, glyph color
    "close":    ("#ff5f57", "#e0443e", "#4d0000"),
    "minimize": ("#febc2e", "#dea123", "#995700"),
    "maximize": ("#28c840", "#1aab29", "#006500"),
}
# inactive window gray (fill, border): the palette's switch track, darker on
# a dark theme than its window, lighter on a light one
INACTIVE = tuple("#" + c for c in sys.argv[2:4]) if len(sys.argv) > 3 else ("#4a4948", "#3d3c3b")
GLYPHS = {                                  # strokes in a 14×14 box
    "close":    "M4.6 4.6 9.4 9.4M9.4 4.6 4.6 9.4",
    "minimize": "M4.2 7h5.6",
    "maximize": "M7 4.2v5.6M4.2 7h5.6",
}


def circle(state_id, fill, stroke, glyph=None, glyph_color=None, opacity=1.0):
    g = (f'<path d="{glyph}" stroke="{glyph_color}" stroke-width="1.3" '
         f'stroke-linecap="round" fill="none"/>' if glyph else "")
    return (f'<g id="{state_id}" opacity="{opacity}">'
            f'<rect width="{SIZE}" height="{SIZE}" fill="none"/>'
            f'<circle cx="7" cy="7" r="6" fill="{fill}" stroke="{stroke}" stroke-width="0.6"/>'
            f'{g}</g>')


for name, (fill, border, glyph_color) in COLORS.items():
    glyph = GLYPHS[name]
    parts = [
        circle("active-center", fill, border),
        circle("hover-center", fill, border, glyph, glyph_color),
        circle("pressed-center", border, border, glyph, glyph_color),
        circle("inactive-center", *INACTIVE),
        circle("deactivated-center", *INACTIVE, opacity=0.5),
    ]
    svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{SIZE}" height="{SIZE}" '
           f'viewBox="0 0 {SIZE} {SIZE}">' + "".join(parts) + "</svg>\n")
    (THEME / f"{name}.svg").write_text(svg)

# Layout: slightly larger, spaced buttons and a taller title bar
rc = next(THEME.glob("*rc"))
text = rc.read_text()
for key, value in {
    "ButtonWidth": SIZE, "ButtonHeight": SIZE, "ButtonSpacing": 8, "ButtonMarginTop": 0,
    "TitleHeight": 18, "TitleEdgeTop": 9, "TitleEdgeBottom": 9,
    "TitleEdgeLeft": 14, "TitleEdgeRight": 14,
    "TitleEdgeTopMaximized": 6, "TitleEdgeBottomMaximized": 6,
    "TitleEdgeLeftMaximized": 12, "TitleEdgeRightMaximized": 12,
    "ExplicitButtonSpacer": 12,
}.items():
    text = re.sub(rf"^{key}=.*$", f"{key}={value}", text, flags=re.M)
rc.write_text(text)
print(f"traffic light buttons in {THEME}")
