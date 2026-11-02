#!/usr/bin/env bash
# Dolphin like Finder: full-width tabs and status bar, and a Places sidebar
# with room on the left. The sidebar spacing is hard-coded in KDE, so it comes
# from a small Qt style sheet (dolphin.qss) that Dolphin loads at start: a
# "dolphin" launcher in ~/.local/bin (ahead of /usr/bin in PATH) and a systemd
# drop-in for the D-Bus started instance pass it with -stylesheet.
# describe: Finder-like Dolphin (sidebar spacing, full-width tabs) | Dolphin tipo Finder (márgenes de la barra lateral, pestañas a todo el ancho)

has dolphin || { warn "$(L "Dolphin is not installed: skipped" "Dolphin no está instalado: se omite")"; return 0; }

QSS="$CONFIG_HOME/redrog/dolphin.qss"
run install -Dm644 "$REDROG_ROOT/modules/dolphin/dolphin.qss" "$QSS"

kw --file dolphinrc --group General --key TabStyle 1        # full-width tabs
kw --file dolphinrc --group General --key ShowStatusBar 1   # full-width status bar

if [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$REAL_HOME/.local/bin"
  cat > "$REAL_HOME/.local/bin/dolphin" <<EOF2
#!/bin/sh
# RedRog: start Dolphin with its sidebar style sheet (modules/dolphin)
exec /usr/bin/dolphin -stylesheet "$QSS" "\$@"
EOF2
  chmod +x "$REAL_HOME/.local/bin/dolphin"
  mkdir -p "$CONFIG_HOME/systemd/user/plasma-dolphin.service.d"
  cat > "$CONFIG_HOME/systemd/user/plasma-dolphin.service.d/redrog.conf" <<EOF2
[Service]
ExecStart=
ExecStart=/usr/bin/dolphin -stylesheet $QSS --daemon
EOF2
fi
run systemctl --user daemon-reload
info "$(L "Dolphin sidebar spacing applies the next time Dolphin starts" "los márgenes de la barra lateral de Dolphin se aplican la próxima vez que se abra")"
