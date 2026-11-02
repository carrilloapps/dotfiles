#!/usr/bin/env bash
# Windows: "RedRog" and "RedRog-Light" Aurorae decorations (Arc-Dark and Arc
# recolored) with macOS traffic light buttons on the left, plus squircle rounded corners with a hairline border
# (KWin effect kwin4_effect_shapecorners).
# describe: window decoration with traffic lights and rounded corners | decoración de ventanas con botones semáforo y esquinas redondeadas

# Both decorations, "RedRog" (dark) and "RedRog-Light", for the light/dark
# switch (the body is not indented: it holds a Python script)
build_decoration() {
local AU="$DATA_HOME/aurorae/themes/$REDROG_NAME"
run rm -rf "$AU"
recolor "$VENDOR_ARC/aurorae/themes/$ARC_AURORAE" "$AU"
run mv "$AU/${ARC_AURORAE}rc" "$AU/${REDROG_NAME}rc"
run rm -f "$AU/metadata.desktop"
if [ "$DRY_RUN" != 1 ]; then
  cat > "$AU/metadata.json" <<EOF
{
    "KPackageStructure": "aurorae",
    "KPlugin": {
        "Id": "$REDROG_NAME",
        "Name": "$THEME_LABEL",
        "Description": "RedRog window decoration with traffic light buttons, based on Arc",
        "Description[es]": "Decoración de RedRog con botones semáforo, basada en Arc",
        "License": "GPL-3.0-or-later",
        "Version": "1.0",
        "EnabledByDefault": true,
        "ServiceTypes": ["aurorae"],
        "Authors": [{ "Name": "RedRog" }, { "Name": "Alexey Varfolomeev (Arc KDE)" }]
    }
}
EOF
fi
run python3 -I "$REDROG_ROOT/modules/window-decoration/traffic-lights.py" "$AU" "$TRACK" "$TRACK_EDGE" >/dev/null
# Title bar in the window tone at the opacity the Kvantum window pane really
# ends up with (its 88 % SVG fill times reduce_window_opacity, measured at about
# 77 %), so the title bar and the window are one translucent, blurred surface
# with no seam (with mask-* pieces, Aurorae asks KWin to blur behind it)
if [ "$DRY_RUN" != 1 ]; then
  python3 -I - "$AU/decoration.svg" "$BG" <<'PY'
import re, sys
path, bg = sys.argv[1:]
svg = open(path, encoding="utf-8").read()

def element_end(doc, start):
    """End of the element starting at start (a whole <g>...</g> group)."""
    m = re.match(r"<(\w+)\b[^>]*?(/?)>", doc[start:])
    if m.group(1) != "g" or m.group(2) == "/":
        return start + m.end()
    depth, pos = 1, start + m.end()
    for t in re.finditer(r"<(/?)g\b[^>]*?(/?)>", doc[pos:]):
        if t.group(2) == "/":
            continue
        depth += -1 if t.group(1) else 1
        if depth == 0:
            return pos + t.end()
    return start + m.end()

def flatten(part):
    # every solid layer (body and border) in the window tone at 77 %
    part = re.sub(r"fill-opacity:[0-9.]+;?", "", part)
    return re.sub(r"fill:#[0-9a-fA-F]{6}", f"fill-opacity:0.77;fill:#{bg}", part)

pos = 0
while (m := re.search(r'<(rect|path|g)\b[^>]*id="decoration-([a-z-]+)"', svg[pos:])):
    start = pos + m.start()
    end = element_end(svg, start)
    part = flatten(svg[start:end])
    # Aurorae only asks KWin to blur behind the title bar when the theme has
    # "mask-*" pieces: add one with the same shape next to each piece
    mask = re.sub(r'id="([^"]+)"', lambda i: f'id="redrog-mask-{i.group(1)}"', part)
    mask = mask.replace(f'id="redrog-mask-decoration-{m.group(2)}"', f'id="mask-{m.group(2)}"', 1)
    svg = svg[:start] + part + mask + svg[end:]
    pos = start + len(part) + len(mask)
open(path, "w", encoding="utf-8").write(svg)
PY
fi
}
for_each_variant build_decoration

D=(--file kwinrc --group org.kde.kdecoration2)
kw "${D[@]}" --key library org.kde.kwin.aurorae
kw "${D[@]}" --key theme "__aurorae__svg__$THEME_ID"
kw "${D[@]}" --key ButtonsOnLeft XIA
kw "${D[@]}" --key ButtonsOnRight ""
kw "${D[@]}" --key BorderSize None
kw "${D[@]}" --key BorderSizeAuto false

# Rounded corners: needs kwin-effect-rounded-corners built against the installed
# KWin version (see docs/TROUBLESHOOTING.md)
RC=(--file kwinrc --group Round-Corners)
kw "${RC[@]}" --key Size 12
kw "${RC[@]}" --key InactiveCornerRadius 12
# plain rounded corners: the squircle shape (rounded-corners 0.11) left a small
# pointed tip at the corners, outside the blur and the titlebar curve
kw "${RC[@]}" --key UseSquircleShape false
kw "${RC[@]}" --key Squircleness 5
kw "${RC[@]}" --key UseNativeDecorationShadows true
kw "${RC[@]}" --key OutlineThickness 1
kw "${RC[@]}" --key OutlineColor "$(rgb "$SURFACE_HI")"
kw "${RC[@]}" --key ActiveOutlineUseCustom true
kw "${RC[@]}" --key ActiveOutlineUsePalette false
kw "${RC[@]}" --key InactiveOutlineThickness 1
kw "${RC[@]}" --key InactiveOutlineColor "$(rgb "$SURFACE")"
kw "${RC[@]}" --key InactiveOutlineUseCustom true
kw "${RC[@]}" --key InactiveOutlineUsePalette false
kw "${RC[@]}" --key DisableRoundMaximize true
kw "${RC[@]}" --key DisableOutlineMaximize true
kw "${RC[@]}" --key DisableRoundFullScreen true
kw --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled true

run qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
if [ "$DRY_RUN" != 1 ] && \
   [ "$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded kwin4_effect_shapecorners 2>/dev/null)" != true ]; then
  warn "$(L "rounded corners don't load: rebuild kwin-effect-rounded-corners for your KWin (docs/TROUBLESHOOTING.md)" \
            "las esquinas redondeadas no cargan: recompila kwin-effect-rounded-corners para tu KWin (docs/TROUBLESHOOTING.md)")"
fi
info "$(L "window decorations RedRog and RedRog-Light; $THEME_ID applied" "decoraciones RedRog y RedRog-Light; $THEME_ID aplicada")"

# KDE's QML (Kirigami) apps and ROG Control Center (Slint) paint their own solid
# background, which the Qt style cannot make translucent: a KWin rule sets them
# to 88 % opacity so the blur shows through, like the other windows (88 %, as
# the Kvantum window pane)
GLASS_APPS=("${QML_GLASS_APPS[@]}" org.opengamingcollective.rog-control-center)
for app in "${GLASS_APPS[@]}"; do
  R=(--file kwinrulesrc --group "redrog-glass-$app")
  kw "${R[@]}" --key Description "RedRog glass: $app"
  kw "${R[@]}" --key wmclass "$app"
  kw "${R[@]}" --key wmclassmatch 1
  kw "${R[@]}" --key opacityactive 77
  kw "${R[@]}" --key opacityactiverule 2
  kw "${R[@]}" --key opacityinactive 77
  kw "${R[@]}" --key opacityinactiverule 2
done
# With the RedRog glass KWin effect (packages/kwin-effect-redrog-glass) only
# the content of those apps goes translucent, at the title bar's opacity, with
# KWin's own blur: one glass with the title bar, like Dolphin. The opacity
# rules (which fade the title bar too) are then turned off.
if [ -e /usr/lib/qt6/plugins/kwin/effects/plugins/redrogglass.so ]; then
  G=(--file kwinrc --group Effect-redrogglass)
  kw "${G[@]}" --key WindowClasses "$(printf '%s\n' "${QML_GLASS_APPS[@]}")"
  kw "${G[@]}" --key Opacity 77
  kw --file kwinrc --group Plugins --key redrogglassEnabled true
  for app in "${QML_GLASS_APPS[@]}"; do
    kw --file kwinrulesrc --group "redrog-glass-$app" --key opacityactiverule 0
    kw --file kwinrulesrc --group "redrog-glass-$app" --key opacityinactiverule 0
  done
  info "$(L "RedRog glass effect on for System Settings, Discover, EasyEffects and others" "efecto de vidrio RedRog activo para Ajustes, Discover, EasyEffects y otras")"
fi

# The RedRog edition of ROG Control Center paints its own glass (crisp text):
# no opacity rule for it
if pacman -Q rog-control-center-redrog >/dev/null 2>&1; then
  R=(--file kwinrulesrc --group "redrog-glass-org.opengamingcollective.rog-control-center")
  kw "${R[@]}" --key opacityactiverule 0
  kw "${R[@]}" --key opacityinactiverule 0
fi
# Apps that hide the window's titlebar and draw their own buttons (DaVinci
# Resolve) get the RedRog titlebar with its traffic lights back
TITLEBAR_APPS=(resolve)
for app in "${TITLEBAR_APPS[@]}"; do
  R=(--file kwinrulesrc --group "redrog-titlebar-$app")
  kw "${R[@]}" --key Description "RedRog titlebar: $app"
  kw "${R[@]}" --key wmclass "$app"
  kw "${R[@]}" --key wmclassmatch 1
  # KWin 6.8: decoration drawn by KWin, forced (older KWin: noborder=false, rule 2)
  kw "${R[@]}" --key decorationpolicy server
  kw "${R[@]}" --key decorationpolicyrule 2
  kw "${R[@]}" --key noborder false
  kw "${R[@]}" --key noborderrule 2
done
if [ "$DRY_RUN" != 1 ]; then
  # KWin 6.8 lists the rules in "Order" (older versions: "rules" and "count")
  rules=$(kreadconfig6 --file kwinrulesrc --group General --key Order)
  [ -n "$rules" ] || rules=$(kreadconfig6 --file kwinrulesrc --group General --key rules)
  for app in "${GLASS_APPS[@]}"; do
    case ",$rules," in *",redrog-glass-$app,"*) ;; *) rules="${rules:+$rules,}redrog-glass-$app" ;; esac
  done
  for app in "${TITLEBAR_APPS[@]}"; do
    case ",$rules," in *",redrog-titlebar-$app,"*) ;; *) rules="${rules:+$rules,}redrog-titlebar-$app" ;; esac
  done
  kwriteconfig6 --file kwinrulesrc --group General --key Order "$rules"
  kwriteconfig6 --file kwinrulesrc --group General --key rules "$rules"
  kwriteconfig6 --file kwinrulesrc --group General --key count "$(tr ',' '\n' <<<"$rules" | grep -c .)"
fi
run qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# Safety net: the packages above rebuild their KWin effects after every KWin
# update (pacman hooks), and at each login a small user service checks that
# every RedRog effect switched on in kwinrc really loaded; if one didn't (a
# failed rebuild), a notification says so and how to fix it.
CHECK_DIR="$REAL_HOME/.local/lib/redrog"
if [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$CHECK_DIR" "$CONFIG_HOME/systemd/user"
  cat > "$CHECK_DIR/redrog-effects-check" <<'EOS'
#!/bin/bash
# RedRog: warns when a RedRog KWin effect switched on in kwinrc, or a
# RedRog widget, failed to load
# (modules/window-decoration)
sleep 20
failed=()
for e in kwin4_effect_shapecorners better_blur_dx redrogglass; do
  [ -e "/usr/lib/qt6/plugins/kwin/effects/plugins/$e.so" ] || continue
  [ "$(kreadconfig6 --file kwinrc --group Plugins --key "${e}Enabled")" = true ] || continue
  [ "$(qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.isEffectLoaded "$e" 2>/dev/null)" = true ] || failed+=("$e")
done
# the compiled widgets of packages/ break the same way when Plasma's library
# changes version (libPlasma.so.N)
for so in /usr/lib/qt6/plugins/plasma/applets/dev.xarbit.appgrid.so \
          /usr/lib/qt6/plugins/plasma/applets/dev.jhyub.supergfxctl.so; do
  [ -e "$so" ] && ldd "$so" 2>/dev/null | grep -q "not found" && failed+=("$(basename "$so" .so)")
done
[ ${#failed[@]} -eq 0 ] && exit 0
case "${LANG:-}" in
  es*) title="Efectos de RedRog sin cargar"
       body="No cargaron: ${failed[*]}. Probablemente se compilaron para otra versión de KWin: ejecuta ./install.sh --packages en ~/.dotfiles y vuelve a iniciar sesión." ;;
  *)   title="RedRog effects not loaded"
       body="Not loaded: ${failed[*]}. They were probably built for another KWin version: run ./install.sh --packages in ~/.dotfiles and log in again." ;;
esac
notify-send -a RedRog -i dialog-warning -u critical "$title" "$body"
EOS
  chmod +x "$CHECK_DIR/redrog-effects-check"
  cat > "$CONFIG_HOME/systemd/user/redrog-effects-check.service" <<EOS
[Unit]
Description=RedRog: check that the KWin effects loaded
PartOf=graphical-session.target
After=plasma-kwin_wayland.service

[Service]
Type=oneshot
ExecStart=$CHECK_DIR/redrog-effects-check

[Install]
WantedBy=graphical-session.target
EOS
  systemctl --user daemon-reload
  systemctl --user enable redrog-effects-check.service >/dev/null 2>&1 || true
fi
