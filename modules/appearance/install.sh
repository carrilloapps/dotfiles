#!/usr/bin/env bash
# Icons, accent-colored folders, fonts and cursor across KDE.
# describe: Papirus icons, Inter fonts and macOS cursor | iconos Papirus, fuentes Inter y cursor de macOS

kw --file kdeglobals --group Icons --key Theme "$ICON_THEME"
case "$(readlink /usr/share/icons/Papirus/64x64/places/folder.svg 2>/dev/null)" in
  *"$ICON_FOLDER_COLOR"*) ;;
  *) has papirus-folders && warn "$(L "folder color: run" "color de carpetas: ejecuta") papirus-folders -C $ICON_FOLDER_COLOR --theme $ICON_THEME" ;;
esac

font() { printf '%s,%s,-1,5,%s,0,0,0,0,0,0,0,0,0,0,1' "$1" "$2" "${3:-400}"; }
for k in font menuFont toolBarFont; do kw --file kdeglobals --group General --key $k "$(font "$FONT_UI" "$FONT_SIZE")"; done
kw --file kdeglobals --group General --key smallestReadableFont "$(font "$FONT_UI" $((FONT_SIZE - 2)))"
kw --file kdeglobals --group General --key fixed "$(font "$FONT_MONO" "$FONT_SIZE")"
kw --file kdeglobals --group WM --key activeFont "$(font "$FONT_UI" "$FONT_SIZE" 600)"
kw --file kwinrc --group WM --key titleFont "$(font "$FONT_UI" "$FONT_SIZE" 600)"

if [ -d "/usr/share/icons/$CURSOR_THEME/cursors" ] || [ -d "$DATA_HOME/icons/$CURSOR_THEME/cursors" ]; then
  kw --file kcminputrc --group Mouse --key cursorTheme "$CURSOR_THEME"
  run plasma-apply-cursortheme "$CURSOR_THEME" >/dev/null 2>&1 || true
else
  warn "$(L "cursor theme $CURSOR_THEME is not installed (./install.sh --packages)" "el cursor $CURSOR_THEME no está instalado (./install.sh --packages)")"
fi
run find "$REAL_HOME/.cache" -maxdepth 1 \( -name 'plasma_theme_*.kcache' -o -name 'ksvg-elements*' -o -name 'icon-cache.kcache' \) -exec rm -rf {} +
# Num Lock on as soon as the session starts (KWin applies it; 0 = on)
kw --file kcminputrc --group Keyboard --key NumLock 0

info "$(L "icons" "iconos") $ICON_THEME, $(L "font" "fuente") $FONT_UI, cursor $CURSOR_THEME"

# Apps that ship their own icon get Papirus' drawing of it when Papirus has
# one under another name, so the menu and the dock look like one set. They go
# in ~/.local/share/icons/<theme> (merged with the system copy of the theme,
# kept across Papirus updates). Apps Papirus has no drawing for keep their own.
ICON_ALIASES=(
  "spotify-launcher=spotify"
  "audacity4portable=audacity"
  "scrcpy=guiscrcpy"
  "io.github.benjamimgois.goverlay=goverlay"
  "rquickshare-x=rquickshare"
  "LimineSnapperSync=yast-snapper"
  # CachyOS' tools with the Arch logo instead of CachyOS' (the updater with
  # Papirus' Arch updater, see modules/global-theme for the updater)
  "org.cachyos.hello=distributor-logo-archlinux"
  "cachyos-pi=distributor-logo-archlinux"
  "org.cachyos.KernelManager=distributor-logo-archlinux"
  "org.cachyos.scx-manager=distributor-logo-archlinux"
)
if [ -d "/usr/share/icons/$ICON_THEME" ] && [ "$DRY_RUN" != 1 ]; then
  aliased=0
  for pair in "${ICON_ALIASES[@]}"; do
    name=${pair%%=*}; target=${pair#*=}
    for dir in /usr/share/icons/"$ICON_THEME"/*/apps; do
      size=$(basename "$(dirname "$dir")")
      [ -e "$dir/$target.svg" ] || continue
      mkdir -p "$DATA_HOME/icons/$ICON_THEME/$size/apps"
      ln -sf "$(readlink -f "$dir/$target.svg")" "$DATA_HOME/icons/$ICON_THEME/$size/apps/$name.svg"
    done
    aliased=$((aliased + 1))
  done
  run kbuildsycoca6 >/dev/null 2>&1 || true
  info "$(L "$aliased apps use Papirus icons instead of their own" "$aliased apps usan iconos de Papirus en vez de los propios")"
fi
