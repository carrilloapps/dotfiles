#!/usr/bin/env bash
# System hologram on the desktop (org.redrog.hud): CPU and GPU temperatures
# and load, memory, frequency, fans, disk, network and battery, in the top
# right corner below the top bar, placed only on the first install (moving or
# removing it is respected). It never wakes the NVIDIA card.
# describe: system hologram on the desktop (temperatures, memory, fans) | holograma del sistema en el escritorio (temperaturas, memoria, ventiladores)

ID=org.redrog.hud
run rm -rf "$DATA_HOME/plasma/plasmoids/$ID"
run mkdir -p "$DATA_HOME/plasma/plasmoids"
run cp -r "$REDROG_ROOT/modules/hud/$ID" "$DATA_HOME/plasma/plasmoids/$ID"
# (its colors and glass follow the active variant, like the other widgets)
for po in "$REDROG_ROOT"/i18n/hud/*.po; do
  [ -e "$po" ] || continue
  lang=$(basename "$po" .po)
  run mkdir -p "$DATA_HOME/locale/$lang/LC_MESSAGES"
  run msgfmt -o "$DATA_HOME/locale/$lang/LC_MESSAGES/plasma_applet_$ID.mo" "$po"
done
run kbuildsycoca6 >/dev/null 2>&1

# Placed once: on later runs it stays where the user put it, and if the user
# removed it, it is not added back
STATE="$REAL_HOME/.local/state/redrog/hud-placed"
if [ ! -e "$STATE" ]; then
  plasma_script "
var desk = desktops().filter(function (d) { return d.screen === 0; })[0] || desktops()[0];
if (desk.widgets('$ID').length === 0) {
    var geo = screenGeometry(desk.screen);
    var w = 340, h = 470;
    desk.addWidget('$ID', geo.width - w - 28, Math.round(gridUnit * 3), w, h);
}
"
  [ "$DRY_RUN" = 1 ] || { mkdir -p "$(dirname "$STATE")"; touch "$STATE"; }
fi
info "$(L "system hologram on the desktop, top right" "holograma del sistema en el escritorio, arriba a la derecha")"
