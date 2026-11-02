#!/usr/bin/env python3
"""Kvantum tweaks for RedRog's visual language, applied on top of the WhiteSur
based theme: opaque windows with translucent, blurred menus, macOS spacing,
rounded controls and subtle gray list selection instead of the accent color.
Usage: tweaks.py THEME.kvconfig   (the .svg with the same name is adjusted too)
"""
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def pal(name):
    """A palette color, the dark or light variant (lib/palette.sh)."""
    script = f'REDROG_ROOT="{ROOT}"; source "$REDROG_ROOT/lib/palette.sh"; echo "${name}"'
    return subprocess.run(["bash", "-c", script], capture_output=True, text=True, check=True).stdout.strip()


LIGHT = pal("THEME_VARIANT") == "light"
OVERLAY = pal("OVERLAY")    # veils and hairlines over the glass: white on dark, black on light

TWEAKS = {
    "%General": {
        # Tabs centered over their pane, inactive ones one continuous capsule
        "center_normal_tabs": "true",
        "joined_inactive_tabs": "true",
        # More breathing room: layout margins and spacing (Arc uses 4 and 2)
        "layout_margin": "8",
        "layout_spacing": "6",
        # One translucent, blurred pane per window (toolbars and side panels
        # have no fill of their own); menus and tooltips too. On fractional
        # scaling Kvantum takes the opacity from the SVG window element.
        "translucent_windows": "true",
        "noninteger_translucency": "true",
        # KWin blurs whatever shows through the translucent windows and menus
        "blurring": "true",
        "popup_blurring": "true",
        "reduce_window_opacity": "12",
        "reduce_menu_opacity": "18",
        "menu_blur_radius": "8",
        "tooltip_blur_radius": "8",
        "menu_shadow_depth": "10",
        # Items inset from the menu edges (rounded highlight, arrows off the edge)
        "spread_menuitems": "false",
        "menu_separator_height": "11",
        # Toolbars: room between and inside the buttons
        "toolbar_item_spacing": "4",
        "toolbar_interior_spacing": "6",
        "spin_button_width": "20",
        # Progress bars use the widget's full height with the text inside;
        # with a thin bar Kvantum puts the text above it, which gets cut off
        # in short places such as Dolphin's free space indicator
        "progressbar_thickness": "0",
        # No tree branch lines, as in Finder
        "tree_branch_line": "false",
        # Overlay scroll bars that appear while scrolling, as on macOS
        "transient_scrollbar": "true",
        "transient_groove": "true",
        # Inactive tabs joined into one strip instead of loose boxes
        "joined_inactive_tabs": "true",
    },
    "Hacks": {
        # Dolphin's file view uses the same background as the window
        "transparent_dolphin_view": "true",
        "noninteger_translucency": "true",
        "respect_darkness": "true",
    },
    # Rounded text fields, combo boxes, buttons and menus
    # Text fields and combo boxes: 10 px before the text, ~30 px tall
    "LineEdit": {
        "frame.expansion": "18",
        "frame.top": "6", "frame.bottom": "6", "frame.left": "6", "frame.right": "6",
        "text.margin.top": "1",
        "text.margin.bottom": "1",
        "text.margin.left": "4",
        "text.margin.right": "4",
    },
    "ComboBox": {
        "frame.expansion": "18",
        "frame.top": "6", "frame.bottom": "6", "frame.left": "6", "frame.right": "6",
        "text.margin.top": "1",
        "text.margin.bottom": "1",
        "text.margin.left": "4",
        "text.margin.right": "8",
        "text.iconspacing": "8",
    },
    "DropDownButton": {"frame.expansion": "18"},
    # Push buttons: ~30 px tall with 16 px side padding, like macOS
    # (frame pieces of 6 px give the corner radius; the text margins add up)
    "PanelButtonCommand": {
        "frame.expansion": "14",
        "frame.top": "6", "frame.bottom": "6", "frame.left": "6", "frame.right": "6",
        "text.margin.top": "1",
        "text.margin.bottom": "1",
        "text.margin.left": "10",
        "text.margin.right": "10",
        "text.iconspacing": "6",
    },
    "ToolbarButton": {
        "frame.expansion": "12",
        "text.margin.top": "4",
        "text.margin.bottom": "4",
        "text.margin.left": "8",
        "text.margin.right": "8",
        "text.iconspacing": "6",
    },
    # Toolbars: no fill or border of their own, only padding (one tone)
    "Toolbar": {"interior": "false", "frame.element": "redrog-none",
                "frame.top": "4", "frame.bottom": "4", "frame.left": "8", "frame.right": "8"},
    # Tabs as a macOS segmented control: compact, one rounded capsule
    "Tab": {
        "text.margin.top": "3",
        "text.margin.bottom": "3",
        "text.margin.left": "16",
        "text.margin.right": "16",
        "text.iconspacing": "6",
        "frame.expansion": "14",
        "text.normal.color": "@TEXT_SOFT@",
        "text.toggle.color": "@TEXT_STRONG@",
    },
    # The pane under tabs: a soft surface with no outline (macOS group box)
    "TabFrame": {"frame": "false", "interior": "true"},
    # Frames around lists and boxes: none, as macOS draws them on glass
    "GenericFrame": {"frame": "false"},
    "HeaderSection": {
        "text.margin.top": "4",
        "text.margin.bottom": "4",
        "text.margin.left": "10",
        "text.margin.right": "10",
    },
    "StatusBar": {"text.margin.left": "8", "text.margin.right": "8"},
    "ToolTip": {
        "frame.top": "6", "frame.bottom": "6", "frame.left": "8", "frame.right": "8",
        "frame.expansion": "12",
    },
    # Menus measured on macOS: 6 px inner padding around the items, roomy
    # rows, a rounded highlight inset from the edges and clear icon spacing.
    # Arc leaves the item text margins at Kvantum's near-zero defaults, which
    # clipped the text.
    "Menu": {
        "frame.expansion": "20",
        "frame.top": "6",
        "frame.bottom": "6",
        "frame.left": "6",
        "frame.right": "6",
    },
    "MenuItem": {
        "frame.expansion": "12",
        "text.margin.top": "3",
        "text.margin.bottom": "3",
        "text.margin.left": "10",
        "text.margin.right": "14",
        "text.iconspacing": "10",
        # keeps submenu arrows away from the right edge
        "frame.right": "8",
        "frame.left": "4",
    },
    # Menu bar items (global menu in apps without it, Dolphin's menu bar)
    "MenuBarItem": {
        "frame.expansion": "12",
        "text.margin.top": "4",
        "text.margin.bottom": "4",
        "text.margin.left": "10",
        "text.margin.right": "10",
    },
    "ItemView": {
        # Rounded selection (a pill, as in the macOS sidebar)
        "frame.expansion": "10",
        "frame.left": "6",
        "frame.right": "6",
        "text.toggle.color": "@FG@",
        "text.focus.color": "@FG@",
        "text.margin.left": "10",
        "text.margin.right": "8",
        "text.margin.top": "6",
        "text.margin.bottom": "6",
        "text.iconspacing": "8",
    },
    # Splitters and panel separators: no visible line or grip, as in Finder
    "Splitter": {"interior": "false", "frame": "false", "indicator.size": "0"},
    # Side panels (Dolphin's Places): 12 px of room on the left and no border
    # line (the frame element does not exist, only its widths count)
    "Dock": {
        "frame.element": "redrog-none", "interior": "false",
        "frame.top": "4", "frame.bottom": "4", "frame.left": "12", "frame.right": "4",
    },
    # Check boxes and radio buttons: 6 px between the indicator and the label
    "CheckBox": {"text.margin.top": "2", "text.margin.bottom": "2", "text.margin.left": "6", "text.margin.right": "2"},
    "RadioButton": {"text.margin.top": "2", "text.margin.bottom": "2", "text.margin.left": "6", "text.margin.right": "2"},
}

# The padding above is for real push buttons only. Many sections inherit
# PanelButtonCommand; those without margins of their own keep the 2 px of the
# reference KvArcDark theme instead of inheriting the button padding.
SMALL_MARGINS = {f"text.margin.{side}": "2" for side in ("top", "bottom", "left", "right")}


def set_key(text, section, key, value):
    pattern = re.compile(rf"(^\[{re.escape(section)}\]\n)(.*?)(?=^\[|\Z)", re.M | re.S)
    m = pattern.search(text)
    if not m:
        return text.rstrip("\n") + f"\n\n[{section}]\n{key}={value}\n"
    body = m.group(2)
    line = re.compile(rf"^{re.escape(key)}=.*$", re.M)
    body = line.sub(f"{key}={value}", body) if line.search(body) else body.rstrip("\n") + f"\n{key}={value}\n\n"
    return text[:m.start(2)] + body + text[m.end(2):]


path = Path(sys.argv[1])
text = path.read_text()
for section, keys in TWEAKS.items():
    for k, v in keys.items():
        if v.startswith("@") and v.endswith("@"):   # a palette color
            v = "#" + pal(v.strip("@"))
        text = set_key(text, section, k, v)
# Apps whose classic Qt panes sit inside a window the RedRog glass effect
# already makes translucent (System Settings modules such as Wi-Fi and
# networks, Info Center): Kvantum paints them opaque, or the two
# translucencies add up and those panes look lighter, washed out
GLASS_APPS = ["systemsettings", "kinfocenter", "kcmshell6"]
opaque = re.search(r"^opaque=(.*)$", text, re.M)
apps = [a for a in (opaque.group(1).split(",") if opaque else []) if a]
text = set_key(text, "%General", "opaque", ",".join(apps + [a for a in GLASS_APPS if a not in apps]))
for m in list(re.finditer(r"^\[([^\]]+)\]\n(.*?)(?=^\[|\Z)", text, re.M | re.S)):
    name, body = m.group(1), m.group(2)
    if (name != "PanelButtonCommand" and "inherits=PanelButtonCommand" in body
            and "text.margin" not in body):
        for k, v in SMALL_MARGINS.items():
            text = set_key(text, name, k, v)
path.write_text(text)


# List selection: subtle gray ($SELECTION) instead of the accent. The SVG's
# itemview-* elements carry their color in the style attribute.


# As macOS draws lists and sidebars: nothing on hover, the selected row a
# rounded pill in the accent color (translucent, over the glass)
COLORS = {"toggled": pal("ACCENT"), "focused": "ffffff", "pressed": pal("SURFACE_HI")}
OPACITY = {"focused": "0", "toggled": "0.55"}
svg = path.with_suffix(".svg")
doc = svg.read_text()
ITEM = re.compile(r'<(rect|path|g)\b[^>]*id="itemview-(focused|toggled|pressed)(?:-[a-z]+)?"[^>]*?(/?)>')
FILL = re.compile(r"(fill|stroke):#[0-9a-fA-F]{6}")
# Gradient fills (bevels, highlights) inside a control's pieces
GRADIENT = re.compile(r"fill:url\(#[^)]+\)")


def element_end(doc, m):
    """End of the element: the tag itself, or its closing </g> for a group."""
    if m.group(1) != "g" or m.group(3) == "/":
        return m.end()
    depth, pos = 1, m.end()
    for t in re.finditer(r"<(/?)g\b[^>]*?(/?)>", doc[pos:]):
        if t.group(2) == "/":
            continue
        depth += -1 if t.group(1) else 1
        if depth == 0:
            return pos + t.end()
    return m.end()


n, out, last = 0, [], 0
for m in ITEM.finditer(doc):
    if m.start() < last:          # already inside a previous group
        continue
    end = element_end(doc, m)
    color = COLORS[m.group(2)]
    out.append(doc[last:m.start()])
    part = FILL.sub(lambda f: f"{f.group(1)}:#{color}", doc[m.start():end])
    if m.group(2) in OPACITY:
        part = re.sub(r"(?<![-a-z])opacity:[0-9.]+", f"opacity:{OPACITY[m.group(2)]}", part)
    # Transparent sides and corners for hover and press; the selection keeps
    # its rounded corners
    if m.group(2) != "toggled" and re.search(r'id="itemview-[a-z]+-(left|right|topleft|topright|bottomleft|bottomright)"', part[:200]):
        part = re.sub(r"(fill|stroke):#[0-9a-fA-F]{6}", r"\1:none", part)
    out.append(part)
    last, n = end, n + 1
doc = "".join(out) + doc[last:]


# Controls in the palette's flat surfaces, like the rest of RedRog (WhiteSur's
# mid gray turns brownish when warmed, and its fields have a dark inner
# shadow). WhiteSur's frame pieces are part of the fill, so they take the same
# color: flat controls, as macOS draws them in dark mode.
SURFACE, SURFACE_HI = pal("SURFACE"), pal("SURFACE_HI")
CONTROLS = {
    # element prefix: (interior, frame)
    "button-normal": (SURFACE_HI, SURFACE_HI),
    "button-focused": (pal("CONTROL_HI"), pal("CONTROL_HI")),
    "button-disabled": (SURFACE, SURFACE),
    "combo-normal": (SURFACE_HI, SURFACE_HI),
    "combo-focused": (pal("CONTROL_HI"), pal("CONTROL_HI")),
    "lineedit-normal": (SURFACE, SURFACE),
    "lineedit-disabled": (SURFACE, SURFACE),
}
# Focused text field: same fill, with the accent focus ring (strokes) kept
FOCUS = re.compile(r'<(rect|path|g|use)\b[^>]*id="lineedit-focused(-[a-z]+)?"[^>]*?(/?)>')
pos = 0
while (m := FOCUS.search(doc, pos)):
    end = element_end(doc, m)
    part = re.sub(r"fill:#[0-9a-fA-F]{6}", f"fill:#{SURFACE}", doc[m.start():end])
    part = GRADIENT.sub(f"fill:#{SURFACE}", part)
    part = re.sub(r"stroke:#(?!{0})[0-9a-fA-F]{{6}}".format(pal("ACCENT")), f"stroke:#{pal('ACCENT')}", part)
    doc = doc[:m.start()] + part + doc[end:]
    pos = m.start() + len(part)

for prefix, (interior, frame) in CONTROLS.items():
    pos = 0
    pattern = re.compile(rf'<(rect|path|g)\b[^>]*id="{prefix}(-[a-z0-9-]+)?"[^>]*?(/?)>')
    while (m := pattern.search(doc, pos)):
        end = element_end(doc, m)
        color = interior if m.group(2) is None else frame
        part = FILL.sub(lambda f: f"{f.group(1)}:#{color}", doc[m.start():end])
        part = GRADIENT.sub(f"fill:#{color}", part)   # flat: no bevel
        doc = doc[:m.start()] + part + doc[end:]
        pos = m.start() + len(part)

# Tabs on the translucent pane: no box of their own; the selected tab is a
# faint white veil, as on macOS (fill, opacity)
# Tabs as a macOS segmented control: a faint capsule for every tab, the
# selected one clearly lighter
# (on the light variant a faint dark capsule, the selected tab plain white)
TABS = ({"tab-normal": ("000000", 0.05), "tab-focused": ("000000", 0.08), "tab-toggled": ("ffffff", 0.95)}
        if LIGHT else
        {"tab-normal": ("ffffff", 0.06), "tab-focused": ("ffffff", 0.09), "tab-toggled": ("ffffff", 0.22)})
for prefix, (color, alpha) in TABS.items():
    pos = 0
    pattern = re.compile(rf'<(rect|path|g)\b[^>]*id="{prefix}(-[a-z0-9-]+)?"[^>]*?(/?)>')
    while (m := pattern.search(doc, pos)):
        end = element_end(doc, m)
        part = GRADIENT.sub(f"fill:#{color}", doc[m.start():end])
        part = re.sub(r"fill-opacity:[0-9.]+;?", "", part)
        part = re.sub(r"(fill|stroke):#[0-9a-fA-F]{6}", rf"\1:#{color};\1-opacity:{alpha}", part)
        doc = doc[:m.start()] + part + doc[end:]
        pos = m.start() + len(part)

# The pane under tabs: a faint white surface, no dark fill or edge lines
pos = 0
TFRAME = re.compile(r'<(rect|path|g)\b[^>]*id="tframe-normal(-[a-z]+)?"[^>]*?(/?)>')
while (m := TFRAME.search(doc, pos)):
    end = element_end(doc, m)
    part = doc[m.start():end]
    if m.group(2) is None:
        part = re.sub(r"opacity:[0-9.]+;fill:#[0-9a-fA-F]{6}", f"opacity:0.035;fill:#{OVERLAY}", part)
    doc = doc[:m.start()] + part + doc[end:]
    pos = m.start() + len(part)

# Frames around lists and boxes (the network list in System Settings, for
# one): a faint white hairline instead of WhiteSur's black outline, so they
# blend into the glass
pos = 0
FRAME = re.compile(r'<(rect|path|g)\b[^>]*id="common-normal-(top|bottom|left|right|topleft|topright|bottomleft|bottomright)"[^>]*?(/?)>')
while (m := FRAME.search(doc, pos)):
    end = element_end(doc, m)
    part = re.sub(r"fill:#000000", f"fill:#{OVERLAY}", doc[m.start():end])
    part = re.sub(r"opacity:0\.8;fill:#{0}".format(OVERLAY), f"opacity:0.1;fill:#{OVERLAY}", part)
    doc = doc[:m.start()] + part + doc[end:]
    pos = m.start() + len(part)

# Translucent window background (88 %): the one pane the whole window shares.
# Inactive windows get the very same pane (Arc's is a darker, opaque gray),
# so a window in the background keeps the glass of its title bar.
normal_fill = None
for wid in ("window-normal", "window-normal-inactive"):
    i = doc.find(f'id="{wid}"')
    if i < 0:
        continue
    a, b = doc.rfind("<", 0, i), doc.index(">", i)
    tag = re.sub(r"fill-opacity:[0-9.]+", "fill-opacity:0.88", doc[a:b])
    if wid == "window-normal":
        normal_fill = re.search(r"fill:#[0-9a-fA-F]{6}", tag).group(0)
    elif normal_fill:
        tag = re.sub(r"fill:#[0-9a-fA-F]{6}", normal_fill, tag)
    doc = doc[:a] + tag + doc[b:]

svg.write_text(doc)
print(f"gray selection in {n} itemview elements")
