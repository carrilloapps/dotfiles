#!/usr/bin/env bash
# The light/dark switch: both variants are installed side by side by the
# theme modules (RedRog and RedRog Light), and redrog-theme-switch moves the
# whole desktop between them in seconds: Plasma's global theme plus what it
# leaves out (accent, Kvantum, GTK, kitty, Spotify, OBS, the files kept in
# both variants). A tray item (org.redrog.themeswitch, a moon or a sun) picks
# Light, Dark or Automatic (Plasma's own light/dark schedule, which a small
# service follows), with a preview. The choice is kept across logins and
# reinstalls (~/.local/state/redrog/theme-variant).
# describe: light/dark switch in the system tray | cambio claro/oscuro en la bandeja del sistema

LIB="$REAL_HOME/.local/lib/redrog"
W=org.redrog.themeswitch

# What the switch needs of each variant, and both palettes for the preview
if [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$LIB/theme"
  write_env() {
    cat > "$LIB/theme/$THEME_VARIANT.env" <<EOF
# RedRog $THEME_VARIANT variant, for redrog-theme-switch (modules/theme-switch)
THEME_ID="$THEME_ID"
THEME_LABEL="$THEME_LABEL"
LNF_ID="$LNF_ID"
ICON_THEME="$ICON_THEME"
WALLPAPER="$WALLPAPER_PKG"
WALLPAPER_FILE="$WALLPAPER_FILE"
ACCENT_RGB="$(rgb "$ACCENT")"
BG="$BG"
OUTLINE="$(rgb "$SURFACE_HI")"
OUTLINE_INACTIVE="$(rgb "$SURFACE")"
DARK=$([ "$THEME_VARIANT" = dark ] && echo true || echo false)
EOF
    printf '"%s": {"variant": "%s", "bg": "%s", "surface": "%s", "surface_hi": "%s", "fg": "%s", "fg_dim": "%s", "accent": "%s"}' \
      "$THEME_VARIANT" "$THEME_VARIANT" "$BG" "$SURFACE" "$SURFACE_HI" "$FG" "$FG_DIM" "$ACCENT"
    if [ "$THEME_VARIANT" = dark ]; then printf ',\n'; fi
  }
  { echo "{"; for_each_variant write_env; printf '\n}\n'; } > "$LIB/theme/palettes.json"
  # the variant this install applied is the one kept from now on
  mkdir -p "$REAL_HOME/.local/state/redrog"
  echo "$THEME_VARIANT" > "$REAL_HOME/.local/state/redrog/theme-variant"
fi

run install -D -m 755 "$REDROG_ROOT/modules/theme-switch/redrog-theme-switch" "$LIB/redrog-theme-switch"
# the animated transition (frozen screens, a circle revealing the new look)
run install -D -m 644 "$REDROG_ROOT/modules/theme-switch/transition/Transition.qml" "$LIB/theme/transition/Transition.qml"
# its logo: the boot splash's Arch logo, charging and flashing (modules/system), or the
# original Arch Charge Big frames; without either the veil goes on alone
for splash in /usr/share/plymouth/themes/redrog-arch /usr/share/plymouth/themes/arch-charge-big; do
  if [ -f "$splash/progress-00.png" ]; then
    run mkdir -p "$LIB/theme/transition/arch"
    run cp "$splash"/progress-*.png "$splash"/throbber-*.png "$LIB/theme/transition/arch/"
    break
  fi
done
run mkdir -p "$REAL_HOME/.local/bin"
run ln -sfn "$LIB/redrog-theme-switch" "$REAL_HOME/.local/bin/redrog-theme-switch"

# Earlier versions gave long-running services (Plasma, the portal, polkit) a
# Breeze override so their dialogs followed light/dark; the application style
# does that by itself now (modules/kvantum), and apps started from them
# inherited it: those drop-ins are removed
if [ "$DRY_RUN" != 1 ]; then
  for unit in plasma-plasmashell plasma-xdg-desktop-portal-kde plasma-polkit-agent; do
    rm -f "$CONFIG_HOME/systemd/user/$unit.service.d/redrog-style.conf"
    rmdir "$CONFIG_HOME/systemd/user/$unit.service.d" 2>/dev/null || true
  done
  # Breeze's menus as frosted glass too, for apps that ask for Breeze
  kwriteconfig6 --file breezerc --group Style --key MenuOpacity 82
fi

# Plasma's automatic light/dark switch moves between the two RedRog themes;
# this service finishes each of its switches (Kvantum, GTK, kitty...)
if [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$CONFIG_HOME/systemd/user"
  cat > "$CONFIG_HOME/systemd/user/redrog-theme-watch.service" <<UNIT
[Unit]
Description=RedRog light/dark: finish Plasma's automatic switches
PartOf=graphical-session.target
After=plasma-plasmashell.service

[Service]
ExecStart=$LIB/redrog-theme-switch watch
Restart=on-failure
RestartSec=5
Nice=10

[Install]
WantedBy=graphical-session.target
UNIT
fi
run systemctl --user daemon-reload
run systemctl --user enable redrog-theme-watch.service >/dev/null 2>&1 || true
run systemctl --user restart redrog-theme-watch.service >/dev/null 2>&1 || true

# The tray item, next to the others on every screen's tray (always shown).
# Plasma finds a new tray item only when it starts, so the panels restart
# once when the widget is new, before the trays list it (a restart saves the
# panels' settings as they were, which would drop it).
new=0
[ -d "$DATA_HOME/plasma/plasmoids/$W" ] && cmp -s "$REDROG_ROOT/modules/theme-switch/$W/metadata.json" \
  "$DATA_HOME/plasma/plasmoids/$W/metadata.json" || new=1
run rm -rf "$DATA_HOME/plasma/plasmoids/$W"
run mkdir -p "$DATA_HOME/plasma/plasmoids"
run cp -r "$REDROG_ROOT/modules/theme-switch/$W" "$DATA_HOME/plasma/plasmoids/$W"
for po in "$REDROG_ROOT"/i18n/themeswitch/*.po; do
  [ -e "$po" ] || continue
  lang=$(basename "$po" .po)
  run mkdir -p "$DATA_HOME/locale/$lang/LC_MESSAGES"
  run msgfmt -o "$DATA_HOME/locale/$lang/LC_MESSAGES/plasma_applet_$W.mo" "$po"
done
if [ "$DRY_RUN" != 1 ] && [ "$new" = 1 ]; then
  systemctl --user restart plasma-plasmashell.service
  for _ in $(seq 30); do
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'print(1)' >/dev/null 2>&1 && break
    sleep 1
  done
  sleep 2
fi
plasma_script "
function list(t, key) {
    var v = t.readConfig(key, []);
    return typeof v == 'string' ? (v ? v.split(',') : []) : v;
}
panels().forEach(function (p) {
    p.widgetIds.forEach(function (id) {
        var t = p.widgetById(id);
        if (t.type != 'org.kde.plasma.systemtray') return;
        t.currentConfigGroup = ['General'];
        var extra = list(t, 'extraItems'), shown = list(t, 'shownItems'), hidden = list(t, 'hiddenItems');
        // an unsaved list means Plasma's defaults, which already enable it
        if (extra.length && extra.indexOf('$W') < 0) extra.push('$W');
        if (shown.indexOf('$W') < 0) shown.push('$W');
        hidden = hidden.filter(function (x) { return x != '$W'; });
        if (extra.length) t.writeConfig('extraItems', extra);
        t.writeConfig('shownItems', shown);
        t.writeConfig('hiddenItems', hidden);
        t.reloadConfig();
    });
});" >/dev/null
info "$(L "light/dark switch in the tray (redrog-theme-switch); now:" "cambio claro/oscuro en la bandeja (redrog-theme-switch); ahora:") $THEME_LABEL"
