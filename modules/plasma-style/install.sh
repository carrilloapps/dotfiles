#!/usr/bin/env bash
# "RedRog" Plasma style (panels, menus, notifications): Arc-Dark (Arc-Color for
# the light variant) recolored, with
# its own metadata.json (Plasma 6 no longer reads metadata.desktop) and
# macOS-like dock indicators and frosted rounded dialogs (from WhiteSur —
# see CREDITS.md).
# describe: RedRog Plasma style with macOS-like dock indicators | estilo de Plasma RedRog con indicadores de dock tipo macOS

HERE="$REDROG_ROOT/modules/plasma-style"
# Both styles, "RedRog" (dark) and "RedRog-Light", for the light/dark switch
build_style() {
  local PT="$DATA_HOME/plasma/desktoptheme/$REDROG_NAME" on_dark on_light
  run rm -rf "$PT"
  recolor "$VENDOR_ARC/plasma/desktoptheme/$ARC_PLASMA" "$PT"
  run rm -f "$PT/metadata.desktop" "$PT/widgets/tasks.svg" "$PT/widgets/tasks.svgz"
  run cp "$HERE/tasks.svgz" "$PT/widgets/tasks.svgz"
  # Rounded, frosted-glass dialogs (notifications, menus, popups) like macOS
  run rm -f "$PT/dialogs/background.svg" "$PT/dialogs/background.svgz"
  run python3 -I "$HERE/translucent.py" "$HERE/dialog-background.svgz" "$PT" "$BG" "$GLASS_ALPHA"
  # Popup headings (notification title rows, tray and launcher headers) take no
  # fill of their own, so the frosted dialog shows through as on macOS
  # (any fill: the palette's hex or the color scheme's currentColor; the
  # hairlines have none, the red layout hints stay)
  [ "$DRY_RUN" = 1 ] || sed -i -E '/#ff0000/!s/style="fill:([^";]+)(;fill-opacity:[0-9.]+)?/style="fill:\1;fill-opacity:0/g' \
    "$PT/widgets/plasmoidheading.svg"
  # Arc was made for Plasma 5: files Plasma 6 reads for new elements (power
  # profile and volume warning icons, the window pin, text field focus rings,
  # insets, shadows, button masks...) drew nothing. The missing elements are
  # copied from Breeze, in the RedRog colors (lib/plasma6-complete.py); the
  # switch and the dock indicators below are RedRog's own
  run python3 -I "$REDROG_ROOT/lib/plasma6-complete.py" "$PT" /usr/share/plasma/desktoptheme/default \
      widgets/switch.svg widgets/tasks.svg >/dev/null
  # ...and Breeze's colors in them become RedRog's (accent, panels, text);
  # warning orange and success green keep their meaning. Breeze's darks are the
  # background and its lights the text on the dark variant, the other way
  # round on the light one
  if [ "$THEME_VARIANT" = light ]; then on_dark=$FG; on_light=$BG; else on_dark=$BG; on_light=$FG; fi
  if [ "$DRY_RUN" != 1 ]; then
    find "$PT" -name '*.svg' -exec sed -i -E \
      -e "s/#(3daee9|1d99f3|da4453|ed1515)/#$ACCENT/gI" \
      -e "s/#(31363b|232629|2a2e32|1b1e20|292c30)/#$on_dark/gI" \
      -e "s/#(4d4d4d|475057)/#$SURFACE_HI/gI" \
      -e "s/#(eff0f1|fcfcfc|ffffff)/#$on_light/gI" \
      -e "s/#(bdc3c7|7f8c8d|a1a9b1)/#$FG_DIM/gI" {} +
  fi
  # Switches (Wi-Fi, Bluetooth, airplane mode...): Arc's switch.svg uses the
  # Plasma 5 element names (groove-*), which Plasma 6 ignores, so only the knobs
  # showed. A Plasma 6 switch in the style of macOS: gray track when off, the
  # accent when on, a light knob with a soft shadow
  if [ "$DRY_RUN" != 1 ]; then
    cat > "$PT/widgets/switch.svg" <<EOF
  <svg xmlns="http://www.w3.org/2000/svg" width="120" height="40" viewBox="0 0 120 40">
   <g id="inactive-left"><path d="M8 0A8 8 0 0 0 8 16Z" fill="#$TRACK"/></g>
   <g id="inactive-center"><rect x="8" y="0" width="4" height="16" fill="#$TRACK"/></g>
   <g id="inactive-right"><path d="M12 0A8 8 0 0 1 12 16Z" fill="#$TRACK"/></g>
   <g id="active-left"><path d="M8 20A8 8 0 0 0 8 36Z" fill="#$ACCENT"/></g>
   <g id="active-center"><rect x="8" y="20" width="4" height="16" fill="#$ACCENT"/></g>
   <g id="active-right"><path d="M12 20A8 8 0 0 1 12 36Z" fill="#$ACCENT"/></g>
   <rect id="hint-bar-size" x="24" y="0" width="30" height="16" fill="none"/>
   <rect id="hint-stretch-borders" x="24" y="20" width="4" height="4" fill="none"/>
   <g id="handle-shadow"><rect x="58" y="0" width="16" height="16" fill="none"/><circle cx="66" cy="8.6" r="7.4" fill="#000" fill-opacity="0.28"/></g>
   <g id="handle"><rect x="78" y="0" width="16" height="16" fill="none"/><circle cx="86" cy="8" r="6.6" fill="#f4f3f1"/></g>
   <g id="handle-hover"><rect x="98" y="0" width="16" height="16" fill="none"/><circle cx="106" cy="8" r="6.6" fill="#ffffff"/></g>
   <g id="handle-pressed"><rect x="78" y="20" width="16" height="16" fill="none"/><circle cx="86" cy="28" r="6.6" fill="#dcdbd8"/></g>
   <g id="handle-focus"><rect x="98" y="20" width="16" height="16" fill="none"/><circle cx="106" cy="28" r="7.4" fill="none" stroke="#$ACCENT" stroke-width="1.2"/></g>
  </svg>
EOF
  fi
  if [ "$DRY_RUN" != 1 ]; then
    cat > "$PT/metadata.json" <<EOF
  {
      "KPlugin": {
          "Id": "$REDROG_NAME",
          "Name": "$THEME_LABEL",
          "Description": "RedRog Plasma style ($THEME_VARIANT), based on Arc",
          "Description[es]": "Estilo de Plasma de RedRog ($THEME_VARIANT), basado en Arc",
          "License": "GPL-3.0-or-later",
          "Version": "1.0",
          "EnabledByDefault": true,
          "Authors": [{ "Name": "RedRog" }, { "Name": "Alexey Varfolomeev (Arc KDE)" }]
      },
      "X-Plasma-API": "5.0"
  }
EOF
  fi
  # Plasma keeps rendered theme SVGs in a cache: dropped so changes show up
  run rm -f "$REAL_HOME/.cache/plasma_theme_$REDROG_NAME.kcache" "$REAL_HOME"/.cache/plasma-svgelements-"$REDROG_NAME"*
}
for_each_variant build_style
run plasma-apply-desktoptheme "$THEME_ID" >/dev/null

# The frosted top bar, dialogs, menus and Qt windows need KWin's own blur
# effect (Better Blur DX alone does not blur panels).
kw --file kwinrc --group Plugins --key blurEnabled true
# Popups (Launchpad, the top bar menus, the tray) appear like on macOS: a quick
# fade with a slight zoom in place, not sliding in from the panel edge
kw --file kwinrc --group Plugins --key slidingpopupsEnabled false
kw --file kwinrc --group Plugins --key fadingpopupsEnabled true
if [ "$DRY_RUN" != 1 ]; then
  qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect slidingpopups >/dev/null 2>&1 || true
  qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.loadEffect fadingpopups >/dev/null 2>&1 || true
fi
# KDE's QML apps (System Settings, Discover, EasyEffects...) do not ask for
# blur: if Better Blur DX is installed, it forces blur only for them (their
# content is made translucent by the RedRog glass effect or a KWin rule in
# modules/window-decoration), on top of KWin's own blur for everything else.
# KWin 6.8 ignores blur forced by other effects, so this stays even with the
# glass effect
if [ -e /usr/lib/qt6/plugins/kwin/effects/plugins/better_blur_dx.so ]; then
  B=(--file kwinrc --group Effect-better-blur-dx)
  # one class per line (a comma-separated list matches nothing). ROG Control
  # Center (RedRog edition) asks for KWin's own blur, so it is not listed
  kw "${B[@]}" --key WindowClasses "$(printf '%s\n' "${QML_GLASS_APPS[@]}")"
  kw "${B[@]}" --key BlurMatching true
  kw "${B[@]}" --key BlurNonMatching false
  for k in BlurDocks BlurMenus; do kw "${B[@]}" --key $k false; done
  # their title bars too, so title bar and window go through the same blur
  # (KWin's own blur renders the color a little differently: a visible seam)
  kw "${B[@]}" --key BlurDecorations true
  for k in Brightness Saturation Contrast; do kw "${B[@]}" --key $k 100; done
  # same strength and grain as KWin's blur, so these apps match Dolphin and
  # the launcher
  kw "${B[@]}" --key BlurStrength 12
  kw "${B[@]}" --key NoiseStrength 2
  kw --file kwinrc --group Plugins --key better_blur_dxEnabled true
else
  kw --file kwinrc --group Plugins --key better_blur_dxEnabled false
fi
kw --file kwinrc --group Effect-blur --key BlurStrength 12
kw --file kwinrc --group Effect-blur --key NoiseStrength 2
run qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
info "$(L "Plasma style $REDROG_NAME applied" "estilo de Plasma $REDROG_NAME aplicado")"
