#!/usr/bin/env bash
# Google Chrome in the RedRog colors: Chrome's "Qt" appearance, which takes
# the KDE color scheme (RedRog.colors) for the tab strip, toolbar and menus,
# in dark mode. Chrome rewrites its Preferences when it quits, so this needs
# Chrome closed; when it is running the step is skipped with a note.
# describe: Google Chrome in the RedRog colors | Google Chrome con los colores de RedRog

if ! has google-chrome-stable; then
  info "$(L "Google Chrome is not installed: skipped" "Google Chrome no está instalado: se omite")"
  return 0
fi
PREFS="$CONFIG_HOME/google-chrome/Default/Preferences"
if [ ! -f "$PREFS" ]; then
  info "$(L "open Chrome once, then run this step again" "abre Chrome una vez y vuelve a ejecutar este paso")"
  return 0
fi
# a Chrome just told to quit (pkill -x chrome; ./install.sh --only chrome)
# takes a moment to go: wait for it a little
for _ in $(seq 20); do pgrep -x chrome >/dev/null || break; sleep 0.25; done
if pgrep -x chrome >/dev/null; then
  # with "keep running in the background" Chrome stays alive without windows
  warn "$(L "quit Google Chrome (menu > Exit, or: pkill -x chrome) and run: ./install.sh --only chrome" \
            "sal de Google Chrome (menú > Salir, o: pkill -x chrome) y ejecuta: ./install.sh --only chrome")"
  return 0
fi

run cp "$PREFS" "$PREFS.before-redrog"
if [ "$DRY_RUN" != 1 ]; then
  python3 -I - "$PREFS" "$THEME_VARIANT" <<'PY'
import json, sys
path = sys.argv[1]
prefs = json.load(open(path, encoding="utf-8"))
theme = prefs.setdefault("extensions", {}).setdefault("theme", {})
theme["id"] = ""           # no theme extension
theme["system_theme"] = 2  # 0 default, 1 GTK, 2 Qt (KDE colors)
# 0: the system's light/dark mode, which follows the RedRog light/dark switch
prefs.setdefault("browser", {}).setdefault("theme", {})["color_scheme2"] = 0
json.dump(prefs, open(path, "w", encoding="utf-8"), separators=(",", ":"))
PY
fi
info "$(L "Chrome follows the RedRog colors (Qt appearance)" "Chrome sigue los colores de RedRog (apariencia Qt)")"
