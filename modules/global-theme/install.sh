#!/usr/bin/env bash
# "RedRog" and "RedRog Light" global themes: both show up in System Settings →
# Global Theme and are Plasma's dark and light looks (its automatic light/dark
# switch and the tray switch, redrog-theme-switch, move between them). Each
# one points at its own color scheme, Plasma style, window decoration and
# icons. The previews are generated from the configured WALLPAPER, which is
# not part of the repository.
# describe: RedRog global theme, emblem icon, desktop and lock screen wallpaper, no splash | tema global RedRog, icono del emblema, fondo de escritorio y de bloqueo, sin splash

SRC="$REDROG_ROOT/modules/global-theme/org.redrog.desktop"
build_lnf() {
  local LNF="$DATA_HOME/plasma/look-and-feel/$LNF_ID" desc
  run rm -rf "$LNF"
  run mkdir -p "$(dirname "$LNF")"
  run cp -r "$SRC" "$LNF"
  if [ "$THEME_VARIANT" = light ]; then
    desc="Claro y plano en blancos Pantone, acento rojo, iconos Papirus y ventanas tipo macOS"
  else
    desc="Oscuro y plano, acento rojo ROG, iconos Papirus y ventanas tipo macOS"
  fi
  if [ "$DRY_RUN" != 1 ]; then
    sed -i -e "s/\"Id\": \"org.redrog.desktop\"/\"Id\": \"$LNF_ID\"/" -e "0,/\"Name\": \"RedRog\"/s//\"Name\": \"$THEME_LABEL\"/" \
           -e "s/\"Description\": \"[^\"]*\"/\"Description\": \"$desc\"/" "$LNF/metadata.json"
    # this variant's pieces
    sed -i -e "s/^ColorScheme=RedRog$/ColorScheme=$THEME_ID/" -e "s/^Theme=Papirus-Dark$/Theme=$ICON_THEME/" \
           -e "/^\[plasmarc\]\[Theme\]/,/^\[/s/^name=RedRog$/name=$THEME_ID/" \
           -e "s/^theme=__aurorae__svg__RedRog$/theme=__aurorae__svg__$THEME_ID/" "$LNF/contents/defaults"
    # the application style that follows light/dark live, when installed
    # (modules/kvantum)
    [ -e /usr/lib/qt6/plugins/styles/darkly6.so ] && sed -i "s/^widgetStyle=kvantum$/widgetStyle=Darkly/" "$LNF/contents/defaults"
  fi
  run mkdir -p "$LNF/contents/previews"
  run magick "$WALLPAPER" -resize 1920x1080^ -gravity center -extent 1920x1080 \
      \( -size 1920x40 "xc:#${BG}99" \) -gravity north -composite \
      "$LNF/contents/previews/fullscreenpreview.jpg"
  run magick "$LNF/contents/previews/fullscreenpreview.jpg" -resize 640x360 "$LNF/contents/previews/preview.png"
}
for_each_variant build_lnf

# RedRog emblem as the "redrog" icon, and the circular "redrog-badge" variant
# for small sizes (top bar menu button)
for name in redrog:logo redrog-badge:logo-badge; do
  ICON="$DATA_HOME/icons/hicolor/scalable/apps/${name%%:*}.svg"
  run install -Dm644 "$REDROG_ROOT/assets/${name#*:}.svg" "$ICON"
  [ "$DRY_RUN" = 1 ] || sed -i "s/#ef3340/#$ACCENT/g" "$ICON"
done
# The Arch logo: "redrog-arch" (top bar menu button, one light color like the
# Apple logo) and "redrog-updates" (Updates in the menu). The update notifier
# in the tray (cachy-update) gets the Arch logo too: plain when the system is
# up to date, with a red dot when there are updates (its icons in every
# variant it offers: light, dark, blue, color-blind)
H="$DATA_HOME/icons/hicolor/scalable/apps"
run install -Dm644 "$REDROG_ROOT/assets/icons/arch-logo.svg" "$H/redrog-arch.svg"
run install -Dm644 "$REDROG_ROOT/assets/icons/arch-updates.svg" "$H/redrog-updates.svg"
for v in light dark blue; do
  run install -Dm644 "$REDROG_ROOT/assets/icons/arch-logo.svg" "$H/cachy-update-$v.svg"
  for cb in "" -cb; do
    run install -Dm644 "$REDROG_ROOT/assets/icons/arch-updates-available.svg" "$H/cachy-update_updates-available-$v$cb.svg"
  done
done
[ "$DRY_RUN" = 1 ] || sed -i "s/#ef3340/#$ACCENT/g" "$H/redrog-updates.svg" "$H"/cachy-update_updates-available-*.svg
# the tray's logo in the theme's text color (Plasma recolors ColorScheme-Text
# icons), so it reads in both variants and over the top bar's wallpaper
[ "$DRY_RUN" = 1 ] || sed -i -e 's|<svg \([^>]*\)>|<svg \1><style id="current-color-scheme">.ColorScheme-Text{color:#efeeeb}</style>|' \
    -e 's|fill="#efeeeb"|fill="currentColor" class="ColorScheme-Text"|' "$H"/cachy-update-*.svg "$H"/cachy-update_updates-available-*.svg
run gtk-update-icon-cache -q -f -t "$DATA_HOME/icons/hicolor" 2>/dev/null || true

kw --file kdeglobals --group KDE --key LookAndFeelPackage "$LNF_ID"
# RedRog is both of Plasma's looks: dark and light
kw --file kdeglobals --group KDE --key DefaultDarkLookAndFeel org.redrog.desktop
kw --file kdeglobals --group KDE --key DefaultLightLookAndFeel org.redrog.light.desktop
kw --file ksplashrc --group KSplash --key Engine none
kw --file ksplashrc --group KSplash --key Theme None

# Desktop and lock screen wallpaper (Breeze lock screen). The wallpaper is the
# user's: RedRog's (WALLPAPER) goes on a screen RedRog has not set up yet, or
# one still showing the image RedRog put there (each screen keeps a note of
# it), never over a wallpaper picked by hand, even one of the system's own.
# The lock and login screens follow the main screen's wallpaper
# (redrog-wallpaper-sync, modules/visualizer). The audio spectrum is a layer
# of its own, on top of any wallpaper.
# Each variant's wallpaper as a Plasma wallpaper package named after it,
# "RedRog" and "RedRog Light" (from WALLPAPER and LIGHT_WALLPAPER), which is
# what the desktops, the lock and the login screens show; the loose image
# files are dropped from the wallpaper picker so nothing shows twice
build_wallpaper() {
  [ "$DRY_RUN" = 1 ] && return 0
  local pkg=$WALLPAPER_PKG ext size
  [ -f "$WALLPAPER_FILE" ] || return 0
  ext=$(printf '%s' "${WALLPAPER_FILE##*.}" | tr 'A-Z' 'a-z'); [ "$ext" = jpeg ] && ext=jpg
  size=$(magick identify -format '%wx%h' "$WALLPAPER_FILE[0]" 2>/dev/null || echo 1920x1080)
  rm -rf "$pkg"
  mkdir -p "$pkg/contents/images"
  cp "$WALLPAPER_FILE" "$pkg/contents/images/$size.$ext"
  printf '{ "KPlugin": { "Id": "%s", "Name": "%s", "Authors": [{ "Name": "RedRog" }], "License": "Personal" } }\n' \
    "$THEME_ID" "$THEME_LABEL" > "$pkg/metadata.json"
}
for_each_variant build_wallpaper
wallpaper_file() { printf '%s\n' "$WALLPAPER_FILE"; }
if [ "$DRY_RUN" != 1 ]; then
  users=$(kreadconfig6 --file plasmarc --group Wallpapers --key usersWallpapers)
  kept=$(printf '%s' "$users" | tr ',' '\n' | grep -v -x -F -f <(for_each_variant wallpaper_file) | paste -sd, || true)
  [ "$kept" = "$users" ] || kw --file plasmarc --group Wallpapers --key usersWallpapers "$kept"
fi
# what RedRog put on the screens before: the loose images of earlier versions
legacy=$(for_each_variant wallpaper_file | paste -sd'|')
APPLIED="$REAL_HOME/.local/state/redrog/wallpaper-applied"
previous=$(cat "$APPLIED" 2>/dev/null || true)
plasma_script "
var legacy = '$legacy'.split('|');
desktops().forEach(function (d) {
    d.currentConfigGroup = ['RedRog'];
    var setUp = String(d.readConfig('wallpaperSynced', 'false')) == 'true';
    var ours = String(d.readConfig('wallpaperApplied', ''));
    var image = '';
    if (d.wallpaperPlugin == 'org.kde.image') {
        d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
        image = String(d.readConfig('Image', '')).replace(/^file:\\/\\//, '').replace(/\\/$/, '');
    } else if (setUp && d.wallpaperPlugin != 'org.redrog.spectrum') {
        return;   // a slideshow, a color, a plugin picked by hand
    }
    if (setUp && image != '' && image != ours && image != '$previous' && legacy.indexOf(image) < 0) return;
    d.wallpaperPlugin = 'org.kde.image';
    d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
    d.writeConfig('Image', 'file://$WALLPAPER_PKG');
    d.currentConfigGroup = ['RedRog'];
    d.writeConfig('wallpaperSynced', 'true');
    d.writeConfig('wallpaperApplied', '$WALLPAPER_PKG');
    d.reloadConfig();
});" >/dev/null
lock=$(kreadconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General --key Image)
lock=${lock#file://}
kw --file kscreenlockerrc --group Greeter --key Theme --delete
kw --file kscreenlockerrc --group Greeter --key WallpaperPluginId org.kde.image
if [ -z "$lock" ] || [ "$lock" = "$previous" ] || [[ $lock == /usr/share/wallpapers/* ]] || [[ "|$legacy" == *"|$lock|"* ]]; then
  kw --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image --group General \
     --key Image "file://$WALLPAPER_PKG"
fi
[ "$DRY_RUN" = 1 ] || { mkdir -p "$(dirname "$APPLIED")"; printf '%s\n' "$WALLPAPER_PKG" > "$APPLIED"; }
info "$(L "global theme RedRog active; RedRog wallpaper on screens without one of their own:" \
          "tema global RedRog activo; fondo de RedRog en las pantallas sin uno propio:") $WALLPAPER"
