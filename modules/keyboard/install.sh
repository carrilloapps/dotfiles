#!/usr/bin/env bash
# Keyboard layouts: Latin American Spanish ("es") and US English ("en", the
# programmers' layout, no dead keys) by default (KEYBOARD_LAYOUTS, put in the
# system keymap by modules/system, ./install.sh --system), switched
# from the tray selector or with Meta+Alt+K, one layout for all windows. The
# layout follows the keyboard in use (redrog-keyboard-layout): a keyboard
# listed in KEYBOARD_AUTO_DEVICES switches to KEYBOARD_AUTO_LAYOUT when it
# connects and back to the first layout when it goes away; in between the
# layout picked by hand stays, also across logins.
# describe: keyboard layouts that follow the keyboard in use | distribuciones de teclado que siguen al teclado en uso

layouts=() labels=() variants=()
for entry in "${KEYBOARD_LAYOUTS[@]}"; do
  spec=${entry%%|*}                     # "us" or "us(altgr-intl)"
  label=${entry#*|}
  layout=${spec%%(*}
  variant=""; [[ $spec == *"("* ]] && { variant=${spec#*(}; variant=${variant%)}; }
  layouts+=("$layout"); variants+=("$variant"); labels+=("$label")
done
[ ${#layouts[@]} -gt 0 ] || { info "$(L "no KEYBOARD_LAYOUTS: skipped" "sin KEYBOARD_LAYOUTS: se omite")"; return 0; }
join() { local IFS=,; printf '%s' "$*"; }

# Plasma's layouts: the system's (the system keymap holds them, set by
# modules/system; Plasma 6.8's KWin ignores a list of the user's own), with
# global switching and short labels in the tray
kw --file kxkbrc --group Layout --key Use false
kw --file kxkbrc --group Layout --key LayoutList --delete
kw --file kxkbrc --group Layout --key VariantList --delete
kw --file kxkbrc --group Layout --key DisplayNames "$(join "${labels[@]}")"
kw --file kxkbrc --group Layout --key SwitchMode Global
# right now, as System Settings does
[ "$DRY_RUN" = 1 ] || dbus-send --session --type=signal /Layouts org.kde.keyboard.reloadConfig 2>/dev/null || true
info "$(L "keyboard layouts:" "distribuciones de teclado:") $(join "${labels[@]}") (Meta+Alt+K)"

# The selector in the system tray of every screen (org.redrog.keyboard): a
# key cap next to the other hardware items (the GPU mode), on the top bar
# while more than one keyboard is connected (among the hidden items
# otherwise), in place of Plasma's own indicator (hidden). Plasma finds a new tray item only
# when it starts, so the panels restart once when the widget is new.
W=org.redrog.keyboard
new=0
[ -d "$DATA_HOME/plasma/plasmoids/$W" ] && cmp -s "$REDROG_ROOT/modules/keyboard/$W/metadata.json" \
  "$DATA_HOME/plasma/plasmoids/$W/metadata.json" || new=1
run rm -rf "$DATA_HOME/plasma/plasmoids/$W"
run mkdir -p "$DATA_HOME/plasma/plasmoids"
run cp -r "$REDROG_ROOT/modules/keyboard/$W" "$DATA_HOME/plasma/plasmoids/$W"
# (its colors are the active theme's: it follows the light/dark switch live)
for po in "$REDROG_ROOT"/i18n/keyboard/*.po; do
  [ -e "$po" ] || continue
  lang=$(basename "$po" .po)
  run mkdir -p "$DATA_HOME/locale/$lang/LC_MESSAGES"
  run msgfmt -o "$DATA_HOME/locale/$lang/LC_MESSAGES/plasma_applet_$W.mo" "$po"
done
plasma_script "
function list(t, key) {
    var v = t.readConfig(key, []);
    return typeof v == 'string' ? (v ? v.split(',') : []) : v;
}
panels().forEach(function (p) {
    p.widgetIds.forEach(function (id) {
        var t = p.widgetById(id);
        // earlier versions sat in the bar itself
        if (t.type == '$W') { t.remove(); return; }
        if (t.type != 'org.kde.plasma.systemtray') return;
        t.currentConfigGroup = ['General'];
        var extra = list(t, 'extraItems'), shown = list(t, 'shownItems'), hidden = list(t, 'hiddenItems');
        // an unsaved list means Plasma's defaults, which already enable it
        if (extra.length && extra.indexOf('$W') < 0) extra.push('$W');
        // not pinned: it shows itself while more than one keyboard is connected
        shown = shown.filter(function (x) { return x != '$W'; });
        shown = shown.filter(function (x) { return x != 'org.kde.plasma.keyboardlayout'; });
        hidden = hidden.filter(function (x) { return x != '$W'; });
        if (hidden.indexOf('org.kde.plasma.keyboardlayout') < 0) hidden.push('org.kde.plasma.keyboardlayout');
        if (extra.length) t.writeConfig('extraItems', extra);
        t.writeConfig('shownItems', shown);
        t.writeConfig('hiddenItems', hidden);
        t.reloadConfig();
    });
});" >/dev/null
if [ "$DRY_RUN" != 1 ] && [ "$new" = 1 ]; then
  systemctl --user restart plasma-plasmashell.service
fi
info "$(L "layout selector in the system tray of every screen" "selector de distribución en la bandeja de todas las pantallas")"

# The layout follows the keyboard in use
LIB="$REAL_HOME/.local/lib/redrog"
run install -D -m 755 "$REDROG_ROOT/modules/keyboard/redrog-keyboard-layout" "$LIB/redrog-keyboard-layout"
if [ "$DRY_RUN" != 1 ]; then
  auto=${KEYBOARD_AUTO_LAYOUT:-us}
  mkdir -p "$CONFIG_HOME/redrog" "$CONFIG_HOME/systemd/user"
  python3 -I - "$CONFIG_HOME/redrog/keyboard.json" "${auto%%(*}" "${layouts[0]}" "${KEYBOARD_AUTO_DEVICES[@]}" <<'PY'
import json, sys
dest, connected, disconnected, *devices = sys.argv[1:]
json.dump({"auto_devices": devices, "connected_layout": connected, "disconnected_layout": disconnected},
          open(dest, "w"), indent=2, ensure_ascii=False)
PY
  cat > "$CONFIG_HOME/systemd/user/redrog-keyboard-layout.service" <<UNIT
[Unit]
Description=The keyboard layout follows the keyboard in use (RedRog)
PartOf=graphical-session.target
After=plasma-kded6.service

[Service]
ExecStart=$LIB/redrog-keyboard-layout
Restart=on-failure
RestartSec=5
Nice=10

[Install]
WantedBy=graphical-session.target
UNIT
fi
run systemctl --user daemon-reload
run systemctl --user enable redrog-keyboard-layout.service >/dev/null 2>&1 || true
run systemctl --user restart redrog-keyboard-layout.service >/dev/null 2>&1 || true
if [ ${#KEYBOARD_AUTO_DEVICES[@]} -gt 0 ]; then
  info "$(L "automatic layout for:" "distribución automática para:") ${KEYBOARD_AUTO_DEVICES[*]} → ${KEYBOARD_AUTO_LAYOUT:-us}"
fi
