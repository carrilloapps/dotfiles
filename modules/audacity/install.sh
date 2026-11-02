#!/usr/bin/env bash
# Audacity 4 (AUR audacity4-bin, the official build: the rebuilt Qt 6
# interface with workspaces and dockable toolbars) in the RedRog colors: its
# dark theme with the RedRog palette (near-black panels, warm grays, red
# accent, focus and recording). It is the Audacity of the menu and of the
# "audacity" command. What earlier RedRog versions set up for Audacity 3 (its
# recolored theme, rebuilt at login) is removed.
# describe: Audacity 4 in the RedRog colors | Audacity 4 con los colores de RedRog

# Audacity 3 leftovers (the package itself is no longer installed)
for f in "$CONFIG_HOME/autostart/redrog-audacity-theme.desktop" "$REAL_HOME/.local/lib/redrog/audacity" \
         "$DATA_HOME/audacity/Theme/custom/ImageCache.png"; do
  [ -e "$f" ] && run rm -rf "$f"
done
grep -qs 'NoDisplay=true' "$DATA_HOME/applications/audacity.desktop" && run rm -f "$DATA_HOME/applications/audacity.desktop"

if ! has audacity4; then
  info "$(L "Audacity 4 is not installed (packages/audacity4-bin): skipped" "Audacity 4 no está instalado (packages/audacity4-bin): se omite")"
  return 0
fi

# In the menu as "Audacity", and "audacity" in a terminal opens it too
A4=/usr/share/applications/org.audacityteam.Audacity4portable.desktop
run mkdir -p "$DATA_HOME/applications" "$REAL_HOME/.local/bin"
[ "$DRY_RUN" = 1 ] || sed -e 's/^Name=.*/Name=Audacity/' -e '/^Name\[/d' "$A4" > "$DATA_HOME/applications/$(basename "$A4")"
run ln -sfn /usr/bin/audacity4 "$REAL_HOME/.local/bin/audacity"

# The RedRog palettes in its dark and light themes (it follows the system's
# light/dark mode, so the RedRog light/dark switch carries it along).
# Audacity writes its settings when it quits, so only while it is closed; the
# other keys of the file are kept.
INI="$CONFIG_HOME/Audacity/Audacity4.ini"
if pgrep -f '^/opt/audacity4-bin/' >/dev/null; then
  warn "$(L "close Audacity and run: ./install.sh --only audacity" "cierra Audacity y ejecuta: ./install.sh --only audacity")"
elif [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$(dirname "$INI")"
  read -r l_accent l_alt l_bg l_surface l_hi l_fg l_soft l_track < <(REDROG_VARIANT=light HOME="$REAL_HOME" \
    bash -c 'source "$REDROG_ROOT/lib/palette.sh"; echo "$ACCENT $ACCENT_ALT $BG $SURFACE $SURFACE_HI $FG $TEXT_SOFT $TRACK"')
  python3 -I - "$INI" "$THEME_VARIANT" "$l_accent" "$l_alt" "$l_bg" "$l_surface" "$l_hi" \
      "$l_fg" "$l_soft" "$l_track" <<'PY'
import json, os, re, sys
path, variant = sys.argv[1:3]
accent, accent_alt, bg, surface, surface_hi, fg, soft, track = ("#" + c for c in sys.argv[3:11])
text = open(path, encoding="utf-8").read() if os.path.exists(path) else ""
light = {
    "accentColor": accent, "focusColor": accent, "recordColor": accent,
    "linkColor": accent, "playColor": fg,
    "backgroundPrimaryColor": surface, "backgroundSecondaryColor": "#f3f1ec",
    "backgroundTertiaryColor": bg, "backgroundQuarternaryColor": surface_hi,
    "popupBackgroundColor": surface, "textFieldColor": "#ffffff",
    "buttonColor": "#e2dfd8", "projectTabColor": "#e2dfd8",
    "strokeColor": surface_hi, "strokeSecondaryColor": track,
    "fontPrimaryColor": fg, "fontSecondaryColor": soft,
}
palette = {
    "accentColor": "#ef3340", "focusColor": "#ef3340", "recordColor": "#ef3340",
    "linkColor": "#f8485e", "playColor": "#efeeeb",
    "backgroundPrimaryColor": "#2a2a29", "backgroundSecondaryColor": "#252524",
    "backgroundTertiaryColor": "#1c1c1c", "backgroundQuarternaryColor": "#141414",
    "popupBackgroundColor": "#252524", "textFieldColor": "#1c1c1c",
    "buttonColor": "#4a4a48", "projectTabColor": "#4a4a48",
    "strokeColor": "#313131", "strokeSecondaryColor": "#4a4a48",
    "fontPrimaryColor": "#efeeeb", "fontSecondaryColor": "#c9c7c2",
}
code = "light" if variant == "light" else "dark"


def theme_base(key):
    return {"codeKey": key, "title": "Claro" if key == "light" else "Oscuro", "accentOpacityNormal": 0.5,
            "accentOpacityHover": 0.3, "accentOpacityHit": 0.7, "buttonOpacityNormal": 0.7,
            "buttonOpacityHover": 0.5, "buttonOpacityHit": 1, "itemOpacityDisabled": 0.3, "borderWidth": 0,
            "navigationControlBorderWidth": 2, "blackColor": "#000000", "whiteColor": "#ffffff"}


# both themes in the RedRog colors; the active variant's is the current one
m = re.search(r'(?m)^application\\themes="(.*)"$', text)
themes = json.loads(m.group(1).replace('\\"', '"')) if m else []
for key, colors in (("dark", palette), ("light", light)):
    entry = next((t for t in themes if t.get("codeKey") == key), None)
    if entry is None:
        entry = theme_base(key)
        themes.append(entry)
    entry.update(colors)
line = 'application\\themes="' + json.dumps(themes, separators=(",", ":")).replace('"', '\\"') + '"'
settings = {"application\\currentThemeCode": code, "application\\followSystemTheme": "true"}
if m:
    text = text[:m.start()] + line + text[m.end():]
else:
    settings["application\\themes"] = None
# the theme keys belong to the [ui] group
if not re.search(r"(?m)^\[ui\]$", text):
    text = text.rstrip("\n") + ("\n\n" if text.strip() else "") + "[ui]\n"

for key, value in settings.items():
    new = line if value is None else f"{key}={value}"
    pat = re.compile(r"(?m)^" + re.escape(key) + r"=.*$")
    if pat.search(text):
        text = pat.sub(lambda _: new, text)
    else:
        text = re.sub(r"(?m)^\[ui\]$", lambda _: "[ui]\n" + new, text, count=1)
open(path, "w", encoding="utf-8").write(text if text.endswith("\n") else text + "\n")
PY
  info "$(L "Audacity 4 in the RedRog colors" "Audacity 4 con los colores de RedRog")"
fi
run kbuildsycoca6 >/dev/null 2>&1 || true
