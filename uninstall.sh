#!/usr/bin/env bash
# RedRog uninstaller: switches back to Breeze Dark and removes what RedRog installed.
#
#   ./uninstall.sh                  theme, colors, windows, GTK, Konsole, Firefox…
#   ./uninstall.sh --reset-layout   also restore Plasma's default panels
#   ./uninstall.sh --dry-run        show what would happen without changing anything
# Packages and /boot are left alone (limine.conf backups live in /var/backups/redrog/).
set -eo pipefail
REDROG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DRY_RUN=0; RESET_LAYOUT=0
for a in "$@"; do
  case "$a" in
    --dry-run) DRY_RUN=1 ;;
    --reset-layout) RESET_LAYOUT=1 ;;
    -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $a" >&2; exit 1 ;;
  esac
done
source "$REDROG_ROOT/lib/common.sh"

step "$(L "Switching back to Breeze Dark" "Volviendo a Breeze oscuro")"
lnf_args=(-a org.kde.breezedark.desktop); [ "$RESET_LAYOUT" = 1 ] && lnf_args+=(--resetLayout)
run plasma-apply-lookandfeel "${lnf_args[@]}" >/dev/null
run plasma-apply-colorscheme BreezeDark >/dev/null
run plasma-apply-desktoptheme breeze-dark >/dev/null
kw --file kdeglobals --group KDE --key widgetStyle Breeze
kw --file kdeglobals --group KDE --key DefaultDarkLookAndFeel --delete
kw --file kwinrc --group org.kde.kdecoration2 --key library org.kde.breeze
kw --file kwinrc --group org.kde.kdecoration2 --key theme Breeze
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnLeft --delete
kw --file kwinrc --group org.kde.kdecoration2 --key ButtonsOnRight --delete
kw --file kwinrc --group Plugins --key kwin4_effect_shapecornersEnabled false
for k in PopupPosition PopupTimeout LowPriorityHistory; do kw --file plasmanotifyrc --group Notifications --key "$k" --delete; done
kw --file konsolerc --group "Desktop Entry" --key DefaultProfile --delete
# Xwayland wrapper from asus-laptop (only ours: it carries the RedRog marker)
grep -q 'RedRog (modules/asus-laptop)' "$REAL_HOME/.local/bin/Xwayland" 2>/dev/null && run rm -f "$REAL_HOME/.local/bin/Xwayland"
for k in TerminalApplication TerminalService; do kw --file kdeglobals --group General --key "$k" --delete; done
for v in 3.0 4.0; do kw --file "$CONFIG_HOME/gtk-$v/settings.ini" --group Settings --key gtk-theme-name Breeze; done
has gsettings && run gsettings set org.gnome.desktop.interface gtk-theme Breeze

# Desktop audio visualizer added by the visualizer module
plasma_script "desktops().forEach(function (d) { d.widgets('luisbocanegra.audio.visualizer').forEach(function (w) { w.remove(); }); if (d.wallpaperPlugin === 'org.redrog.spectrum') d.wallpaperPlugin = 'org.kde.image'; });"

step "$(L "Stopping the ASUS notification service" "Deteniendo el servicio de notificaciones de ASUS")"
run systemctl --user disable --now redrog-rog-notify.service 2>/dev/null || true

step "$(L "Removing RedRog files" "Borrando archivos de RedRog")"
# EasyEffects: the speaker autoload, and the neutral fallback if it is ours
for f in "$DATA_HOME"/easyeffects/autoload/output/*.json; do
  [ -f "$f" ] && grep -q '"RedRog Laptop Speakers"' "$f" && run rm -f "$f"
done
EERC="$CONFIG_HOME/easyeffects/db/easyeffectsrc"
if [ "$(kreadconfig6 --file "$EERC" --group Window --key outputAutoloadingFallbackPreset)" = "RedRog Neutral" ]; then
  for k in outputAutoloadingUsesFallback outputAutoloadingFallbackPreset; do kw --file "$EERC" --group Window --key "$k" --delete; done
fi
for p in \
  "$DATA_HOME/color-schemes/$REDROG_NAME.colors" "$DATA_HOME/plasma/desktoptheme/$REDROG_NAME" \
  "$CONFIG_HOME/Kvantum/$REDROG_NAME" "$DATA_HOME/aurorae/themes/$REDROG_NAME" \
  "$DATA_HOME/themes/$REDROG_NAME" "$DATA_HOME/konsole/$REDROG_NAME.colorscheme" \
  "$DATA_HOME/konsole/$REDROG_NAME.profile" "$CONFIG_HOME/kitty/redrog-theme.conf" "$CONFIG_HOME/kitty/redrog-keys.conf" "$CONFIG_HOME/kitty/tab_bar.py" "$DATA_HOME/kwin/scripts/redrog-menu-placement" "$DATA_HOME/plasma/look-and-feel/org.redrog.desktop" \
  "$DATA_HOME/plasma/plasmoids/org.redrog.hud" "$DATA_HOME"/locale/*/LC_MESSAGES/plasma_applet_org.redrog.hud.mo \
  "$DATA_HOME/plasma/plasmoids/org.redrog.batterypercent" "$DATA_HOME/plasma/plasmoids/org.redrog.clock" \
  "$DATA_HOME/applications/redrog-downloads.desktop" "$DATA_HOME/applications/redrog-trash.desktop" \
  "$CONFIG_HOME/systemd/user/redrog-rog-notify.service" "$REAL_HOME/.local/lib/redrog" \
  "$DATA_HOME"/locale/*/LC_MESSAGES/redrog.mo \
  "$DATA_HOME"/locale/*/LC_MESSAGES/plasma_applet_luisbocanegra.audio.visualizer.mo \
  "$CONFIG_HOME/redrog/dolphin.qss" "$REAL_HOME/.local/bin/dolphin" "$CONFIG_HOME/systemd/user/plasma-dolphin.service.d/redrog.conf" \
  "$CONFIG_HOME/autostart/easyeffects-service.desktop" "$CONFIG_HOME/autostart/redrog-audio-login.desktop" "$DATA_HOME/easyeffects/output/RedRog Laptop Speakers.json" \
  "$DATA_HOME/easyeffects/output/RedRog Neutral.json" "$DATA_HOME/applications/redrog-audio-reset.desktop" \
  "$DATA_HOME/applications/redrog-chrome-nvidia.desktop" "$DATA_HOME/applications/redrog-rog-control-center.desktop" \
  "$DATA_HOME/plasma/wallpapers/org.redrog.spectrum" "$DATA_HOME"/locale/*/LC_MESSAGES/plasma_wallpaper_org.redrog.spectrum.mo; do
  [ -e "$p" ] && run rm -rf "$p" && info "${p/#$REAL_HOME/\~}"
done
kw --file "$CONFIG_HOME/Kvantum/kvantum.kvconfig" --group General --key theme --delete

# Root pieces (Limine hook): removed only when run as root
if [ "$(id -u)" = 0 ]; then
  for f in /etc/pacman.d/hooks/zz-redrog-limine.hook /usr/local/lib/redrog/limine-theme.sh; do
    [ -e "$f" ] && run rm -f "$f" && info "$f"
  done
fi

# Firefox: restore whatever was there before RedRog
for d in "$CONFIG_HOME/mozilla/firefox" "$REAL_HOME/.mozilla/firefox"; do
  for f in "$d"/*/user.js "$d"/*/chrome/userChrome.css "$d"/*/chrome/userContent.css; do
    [ -f "$f" ] && grep -q RedRog "$f" || continue
    if [ -f "$f.before-redrog" ]; then run mv "$f.before-redrog" "$f"; else run rm -f "$f"; fi
  done
done

run qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
step "$(L "Done" "Listo")"
info "$(L "Log out and back in. Packages: see packages/*.txt if you want to remove them." \
          "Cierra sesión y vuelve a entrar. Paquetes: ver packages/*.txt si quieres quitarlos.")"
[ "$RESET_LAYOUT" = 1 ] || info "$(L "Panels were not touched (use --reset-layout for Plasma's defaults)." \
                                     "Los paneles no se tocaron (usa --reset-layout para volver a los de Plasma).")"
