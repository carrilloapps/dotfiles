#!/usr/bin/env bash
# Qt application style. Darkly (packages/aur.txt) when installed: a native
# style that reads the color scheme, so every open app follows the light/dark
# switch live, set up like RedRog's look (flat, frosted menus, rounded
# corners, Finder-like tabs and macOS-like controls). The "RedRog" Kvantum themes are
# built too, as the fallback without Darkly: WhiteSur dark (or WhiteSur light
# for the light variant; vendor/whitesur-kvantum) recolored to the palette,
# plus the tweaks in tweaks.py (opaque windows, translucent blurred menus,
# macOS spacing and subtle gray list selection); Kvantum can't follow a switch
# in apps already open.
# describe: macOS-like Qt application style (Kvantum RedRog) | estilo de aplicaciones Qt tipo macOS (Kvantum RedRog)

need kvantummanager
# Both themes, "RedRog" (dark) and "RedRog-Light", for the light/dark switch
build_kvantum() {
  local KV="$CONFIG_HOME/Kvantum/$REDROG_NAME" ws base fg
  # Base: WhiteSur (macOS-like rounded controls, translucent menus); its
  # window gray and text color are the anchors for the palette mapping
  WS="$REDROG_ROOT/vendor/whitesur-kvantum"
  if [ "$THEME_VARIANT" = light ]; then
    ws=WhiteSur; base=f5f5f5; fg=333333
    # its selection and text colors carry an alpha ("#3484e250")
    export RECOLOR_HEX8=1
  else
    ws=WhiteSurDark; base=242424; fg=dedede
  fi
  # (with a lighter warm tint: its many mid grays would turn brownish)
  export RECOLOR_BASE=$base RECOLOR_FG=$fg RECOLOR_HUE_MAX=0.8 RECOLOR_WARMTH=0.3
  recolor "$WS/$ws.svg" "$KV/$REDROG_NAME.svg"
  recolor "$WS/$ws.kvconfig" "$KV/$REDROG_NAME.kvconfig"
  unset RECOLOR_BASE RECOLOR_FG RECOLOR_HUE_MAX RECOLOR_WARMTH RECOLOR_HEX8
  run python3 -I "$REDROG_ROOT/modules/kvantum/tweaks.py" "$KV/$REDROG_NAME.kvconfig" >/dev/null
}
for_each_variant build_kvantum
kw --file "$CONFIG_HOME/Kvantum/kvantum.kvconfig" --group General --key theme "$THEME_ID"
if [ -e /usr/lib/qt6/plugins/styles/darkly6.so ]; then
  D=(--file darklyrc --group Style)
  # the window itself opaque: its glass comes from the RedRog glass effect
  # (modules/window-decoration), at the title bar's very opacity and color, so
  # title bar and content are one glass with no seam (translucency of its own
  # here would add up with the effect's); menus as frosted glass (82 %)
  for k in ToolBarOpacity MenuBarOpacity TabBarOpacity DolphinSidebarOpacity DolphinViewOpacity; do
    kw "${D[@]}" --key "$k" 100
  done
  kw "${D[@]}" --key MenuOpacity 82
  kw "${D[@]}" --key TransparentDolphinView false
  # macOS-like: rounded corners, no scroll bar arrows, no icons on buttons,
  # tabs across the whole width (modules/dolphin)
  kw "${D[@]}" --key CornerRadius 6
  kw "${D[@]}" --key ScrollBarAddLineButtons 0
  kw "${D[@]}" --key ScrollBarSubLineButtons 0
  kw "${D[@]}" --key ShowIconsOnPushButtons false
  kw "${D[@]}" --key TabBarTabExpandFullWidth true
  # flat: no frames around side panels, docks and views, no separators
  # between bars or along scroll bars; tabs as in Finder: segments across the
  # whole width in a strip, centered titles, the active one told by its tone
  # only (no accent line or fill)
  for k in SidePanelDrawFrame DockWidgetDrawFrame TitleWidgetDrawFrame KTextEditDrawFrame \
           ToolBarDrawItemSeparator ToolBarDrawSeparator ViewDrawFocusIndicator \
           renderThinSeperatorBetweenTheScrollBar; do
    kw "${D[@]}" --key "$k" false
  done
  kw "${D[@]}" --key DocumentModeTabs true
  kw "${D[@]}" --key TabBarAltStyle false
  kw "${D[@]}" --key TabBarDrawCenteredTabs true
  kw "${D[@]}" --key TabDrawHighlight false
  kw "${D[@]}" --key TabUseHighlightColor false
  was=$(kreadconfig6 --file kdeglobals --group KDE --key widgetStyle)
  kw --file kdeglobals --group KDE --key widgetStyle Darkly
  # Plasma's own menus keep the style the shell started with: once, when the
  # style becomes Darkly, the shell restarts to load it (from then on its
  # menus follow light/dark live like every app)
  if [ "$DRY_RUN" != 1 ] && [ "$was" != Darkly ] && systemctl --user -q is-active plasma-plasmashell.service; then
    systemctl --user reset-failed plasma-plasmashell.service 2>/dev/null
    systemctl --user restart plasma-plasmashell.service
  fi
  [ "$DRY_RUN" = 1 ] || dbus-send --session --type=signal /DarklyStyle org.kde.Darkly.Style.reparseConfiguration 2>/dev/null || true
  info "$(L "application style: Darkly (follows light/dark live); Kvantum themes kept as the fallback" "estilo de aplicaciones: Darkly (sigue claro/oscuro en vivo); temas de Kvantum como respaldo")"
else
  kw --file kdeglobals --group KDE --key widgetStyle kvantum
  info "$(L "Kvantum themes RedRog and RedRog-Light; $THEME_ID applied" "temas de Kvantum RedRog y RedRog-Light; $THEME_ID aplicado")"
fi
