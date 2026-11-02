#!/usr/bin/env bash
# macOS-like layout (only with ./install.sh --layout, because it rebuilds the
# panels): translucent top bar with global menu, system tray, battery percentage,
# clock and Notification Center; floating transparent dock with Launchpad
# (AppGrid), the DOCK_APPS, Downloads and Trash.
# describe: macOS-like top bar and dock (rebuilds the panels) | barra superior y dock tipo macOS (rehace los paneles)

HERE="$REDROG_ROOT/modules/layout"
APPS="$DATA_HOME/applications"

# Own widgets: battery percentage as text and the menu bar clock
for w in org.redrog.batterypercent org.redrog.clock; do
  PL="$DATA_HOME/plasma/plasmoids/$w"
  run rm -rf "$PL"
  run mkdir -p "$(dirname "$PL")"
  run cp -r "$HERE/$w" "$PL"
  # (its colors are the active theme's: it follows the light/dark switch live)
done
# Spanish (and other) translations of the battery percentage's RedRog panel
for po in "$REDROG_ROOT"/i18n/batterypercent/*.po; do
  [ -e "$po" ] || continue
  lang=$(basename "$po" .po)
  run mkdir -p "$DATA_HOME/locale/$lang/LC_MESSAGES"
  run msgfmt -o "$DATA_HOME/locale/$lang/LC_MESSAGES/plasma_applet_org.redrog.batterypercent.mo" "$po"
done

# Downloads and Trash launchers (the user's real paths, via XDG)
DOWNLOADS="$(xdg-user-dir DOWNLOAD 2>/dev/null || echo "$REAL_HOME/Downloads")"
if [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$APPS"
  cat > "$APPS/redrog-downloads.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Downloads
Name[es]=Descargas
Name[de]=Downloads
Name[fr]=Téléchargements
Name[it]=Scaricati
Name[pt_BR]=Downloads
Name[pt]=Transferências
Name[ru]=Загрузки
Name[uk]=Завантаження
Name[pl]=Pobrane
Name[nl]=Downloads
Name[tr]=İndirilenler
Name[cs]=Stažené
Name[sv]=Hämtningar
Name[zh_CN]=下载
Name[zh_TW]=下載
Name[ja]=ダウンロード
Name[ko]=다운로드
Name[ar]=التنزيلات
Name[hi]=डाउनलोड
Name[id]=Unduhan
Name[vi]=Tải về
Exec=dolphin --new-window "$DOWNLOADS"
Icon=folder-downloads
NoDisplay=true
EOF
  cat > "$APPS/redrog-trash.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Trash
Name[es]=Papelera
Name[de]=Papierkorb
Name[fr]=Corbeille
Name[it]=Cestino
Name[pt_BR]=Lixeira
Name[pt]=Lixo
Name[ru]=Корзина
Name[uk]=Смітник
Name[pl]=Kosz
Name[nl]=Prullenbak
Name[tr]=Çöp Kutusu
Name[cs]=Koš
Name[sv]=Papperskorg
Name[zh_CN]=回收站
Name[zh_TW]=垃圾桶
Name[ja]=ごみ箱
Name[ko]=휴지통
Name[ar]=سلة المهملات
Name[hi]=रद्दी
Name[id]=Tempat Sampah
Name[vi]=Thùng rác
Exec=dolphin --new-window trash:/
Icon=user-trash
NoDisplay=true
Actions=empty;

[Desktop Action empty]
Name=Empty Trash
Name[es]=Vaciar papelera
Exec=ktrash6 --empty
EOF
fi
run kbuildsycoca6 >/dev/null 2>&1

# Dock launchers: the DOCK_APPS that exist + Downloads + Trash
launchers=()
for app in "${DOCK_APPS[@]}"; do
  for dir in "$APPS" /usr/share/applications "$DATA_HOME/flatpak/exports/share/applications" /var/lib/flatpak/exports/share/applications; do
    if [ -f "$dir/$app.desktop" ]; then launchers+=("\"applications:$app.desktop\""); break; fi
  done
done
launchers+=('"applications:redrog-downloads.desktop"' '"applications:redrog-trash.desktop"')
LAUNCHERS="[$(IFS=,; echo "${launchers[*]}")]"

# Panel Colorizer styles if installed: transparent dock; top bar clear while no
# window is maximized and frosted when one is (saved as user presets)
PRESETS=/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets
USER_PRESETS="$CONFIG_HOME/panel-colorizer/presets"
DOCK_STYLE=null; CLEAR_STYLE=null; FROSTED_STYLE=null
if [ -d "$PRESETS" ]; then
  # Brightness (0-1) of the strip of wallpaper behind the top bar
  LUMA=$(magick "$WALLPAPER" -resize 1920x1080^ -gravity north -crop 1920x48+0+0 +repage \
           -colorspace Gray -format '%[fx:mean]' info: 2>/dev/null || echo 0)
  if [ "$DRY_RUN" = 1 ]; then OUT=$(mktemp -d); else OUT="$USER_PRESETS"; fi
  { read -r DOCK_STYLE; read -r CLEAR_STYLE; read -r FROSTED_STYLE; } \
    < <(python3 -I "$HERE/colorizer-styles.py" "$PRESETS" "$LUMA" "$OUT")
  [ "$DRY_RUN" = 1 ] && rm -rf "$OUT"
else
  warn "$(L "Panel Colorizer is not installed: panels keep their native background" "Panel Colorizer no está instalado: los paneles conservan el fondo nativo")"
fi

# Alt+Space belongs to the launcher; KRunner keeps Alt+F2 and the Search key
run python3 -I "$REDROG_ROOT/lib/set-shortcut.py" org.kde.krunner.desktop _launch Alt+F2 Search

AUTOLOAD=$(printf '{"enabled":true,"normal":"%s","maximized":"%s","fullscreenWindow":"%s"}' \
  "$USER_PRESETS/RedRog Clear" "$USER_PRESETS/RedRog Frosted" "$USER_PRESETS/RedRog Frosted")
plasma_script "var DOCK_STYLE = $DOCK_STYLE; var CLEAR_STYLE = $CLEAR_STYLE; var FROSTED_STYLE = $FROSTED_STYLE;
var TOP_AUTOLOAD = $(python3 -Ic 'import json,sys; print(json.dumps(sys.argv[1]))' "$AUTOLOAD"); var LAUNCHERS = $LAUNCHERS;
$(cat "$HERE/layout-macos.js")"
info "$(L "macOS-like panels created (${#launchers[@]} dock launchers)" "paneles tipo macOS creados (${#launchers[@]} lanzadores en el dock)")"

# The top bar's veil on each screen, from the wallpaper behind it (like
# macOS: a soft dark veil where light icons would get lost on a light
# wallpaper, a light one for dark icons on a dark wallpaper); recomputed when
# a wallpaper, a screen or the light/dark variant changes
run install -D -m 755 "$HERE/redrog-panel-veil" "$REAL_HOME/.local/lib/redrog/redrog-panel-veil"
[ "$DRY_RUN" = 1 ] || "$REAL_HOME/.local/lib/redrog/redrog-panel-veil" >/dev/null 2>&1 || true
