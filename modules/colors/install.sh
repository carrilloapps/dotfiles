#!/usr/bin/env bash
# "RedRog" and "RedRog Light" color schemes: Arc's (Arc Dark, Arc for the light
# one) recolored to each palette, with exact backgrounds and text colors
# pinned on top (windows in $BG, views in $SURFACE).
# describe: RedRog color scheme and accent color | esquema de colores RedRog y color de acento

# Both schemes, "RedRog" (dark) and "RedRog Light", for the light/dark switch
build_scheme() {
  local CS="$DATA_HOME/color-schemes/$REDROG_NAME.colors"
  run mkdir -p "$(dirname "$CS")"
  recolor "$VENDOR_ARC/color-schemes/$ARC_COLORS" "$CS"
  run sed -i "s/^Name=.*/Name=$THEME_LABEL/" "$CS"

  for g in Window Header 'Header][Inactive' Complementary Tooltip; do
    kw --file "$CS" --group "Colors:$g" --key BackgroundNormal "$(rgb "$BG")"
    kw --file "$CS" --group "Colors:$g" --key BackgroundAlternate "$(rgb "$BG")"
  done
  # One tone for windows and views (sidebars, file lists), like the Claude app;
  # alternating rows only a hair lighter
  kw --file "$CS" --group Colors:View --key BackgroundNormal "$(rgb "$BG")"
  kw --file "$CS" --group Colors:View --key BackgroundAlternate "$(rgb "$SELECTION")"
  kw --file "$CS" --group Colors:Button --key BackgroundNormal "$(rgb "$SURFACE_HI")"
  kw --file "$CS" --group Colors:Button --key BackgroundAlternate "$(rgb "$SURFACE")"
  for g in Window View Button Header Complementary Tooltip Selection; do
    kw --file "$CS" --group "Colors:$g" --key ForegroundNormal "$(rgb "$FG")"
    kw --file "$CS" --group "Colors:$g" --key ForegroundInactive "$(rgb "$FG_DIM")"
  done
}
for_each_variant build_scheme

# Plasma refuses to re-apply a scheme with the same name ("already in use") and
# kdeglobals would keep the old colors, so switch to Breeze's first.
run plasma-apply-colorscheme "$BREEZE_SCHEME" >/dev/null
run plasma-apply-colorscheme "$THEME_ID" >/dev/null
kw --file kdeglobals --group General --key AccentColor "$(rgb "$ACCENT")"
kw --file kdeglobals --group General --key accentColorFromWallpaper false
info "$(L "color schemes RedRog and RedRog Light; $THEME_LABEL applied (accent #$ACCENT)" "esquemas RedRog y RedRog Light; $THEME_LABEL aplicado (acento #$ACCENT)")"

# Separator and frame lines (Kirigami, System Settings): 10 % towards the text
# color gives the theme's hairline gray instead of lines in the text color
kw --file kdeglobals --group KDE --key frameContrast 0.1
kw --file kdeglobals --group KDE --key contrast 2
