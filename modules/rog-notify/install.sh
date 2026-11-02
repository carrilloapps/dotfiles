#!/usr/bin/env bash
# Localized ASUS notifications: replaces ROG Control Center's English-only
# notifications with a user service that follows the system language (gettext,
# domain "redrog"). Skipped on machines without asusd.
# describe: ASUS notifications in the user's language and keyboard color | notificaciones de ASUS en el idioma del usuario y color del teclado

if ! busctl --system status xyz.ljones.Asusd >/dev/null 2>&1; then
  info "$(L "asusd is not running: skipped" "asusd no está activo: se omite")"
  exit 0
fi
HERE="$REDROG_ROOT/modules/rog-notify"
run install -Dm755 "$HERE/redrog-rog-notify.py" "$REAL_HOME/.local/lib/redrog/redrog-rog-notify.py"
run install -Dm644 "$HERE/redrog-rog-notify.service" "$CONFIG_HOME/systemd/user/redrog-rog-notify.service"

# Compiled translations for every language in i18n/redrog
for po in "$REDROG_ROOT"/i18n/redrog/*.po; do
  lang=$(basename "$po" .po)
  run mkdir -p "$DATA_HOME/locale/$lang/LC_MESSAGES"
  run msgfmt -o "$DATA_HOME/locale/$lang/LC_MESSAGES/redrog.mo" "$po"
done

# ROG Control Center's own notifications are English-only: turn them off
RC="$CONFIG_HOME/rog/rog-control-center.cfg"
if [ -f "$RC" ]; then
  run sed -i 's/^\(\s*\)enabled: true,/\1enabled: false,/; s/receive_notify_gfx: true/receive_notify_gfx: false/; s/receive_notify_gfx_status: true/receive_notify_gfx_status: false/' "$RC"
fi

run systemctl --user daemon-reload
run systemctl --user enable --now redrog-rog-notify.service
run systemctl --user restart redrog-rog-notify.service
info "$(L "ASUS notifications follow the system language" "las notificaciones de ASUS siguen el idioma del sistema")"

# Keyboard backlight in the RedRog red (static), only on the first install:
# afterwards the color chosen in ROG Control Center is the user's and stays
STATE="$REAL_HOME/.local/state/redrog/keyboard-color-set"
if [ ! -e "$STATE" ] && has asusctl && asusctl aura effect static --help >/dev/null 2>&1; then
  if run asusctl aura effect static -c "$KEYBOARD_COLOR" >/dev/null 2>&1; then
    info "$(L "keyboard backlight" "retroiluminación del teclado"): #$KEYBOARD_COLOR"
    [ "$DRY_RUN" = 1 ] || { mkdir -p "$(dirname "$STATE")"; touch "$STATE"; }
  fi
fi
