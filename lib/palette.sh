# RedRog palette: the defaults, the user's overrides and the variant. Sourced by
# lib/common.sh and lib/recolor.py, so the installer and the recolored themes
# always read the same colors.
# Usage: source lib/palette.sh   (REDROG_ROOT set, HOME the real user's)
# shellcheck source=../config/redrog.conf
source "$REDROG_ROOT/config/redrog.conf"
[ -f "$REDROG_ROOT/config/user.conf" ] && source "$REDROG_ROOT/config/user.conf"
[ -n "$WALLPAPER" ] || WALLPAPER="$REDROG_ROOT/vendor/arc-kde/wallpapers/Arc-Dark/contents/images/2560x1440.png"
# The active variant: REDROG_VARIANT in the environment (a quick try), else
# the last one picked with redrog-theme-switch (the tray's light/dark switch),
# else THEME_VARIANT
_picked=$(cat "$HOME/.local/state/redrog/theme-variant" 2>/dev/null || true)
case "$_picked" in light|dark) THEME_VARIANT=$_picked ;; esac
unset _picked
THEME_VARIANT="${REDROG_VARIANT:-${THEME_VARIANT:-dark}}"
# The light variant takes the LIGHT_ palette, and the light Arc sources
if [ "$THEME_VARIANT" = light ]; then
  for _k in ACCENT ACCENT_ALT BG DEEP SURFACE SURFACE_HI SELECTION FG FG_DIM ICON_THEME ARC_BASE ARC_FG; do
    _v="LIGHT_$_k"
    [ -n "${!_v:-}" ] && printf -v "$_k" '%s' "${!_v}"
  done
  unset _k _v
  # its own wallpaper, if set
  [ -n "${LIGHT_WALLPAPER:-}" ] && WALLPAPER=$LIGHT_WALLPAPER
  ARC_COLORS="Arc.colors"; ARC_PLASMA="Arc-Color"; ARC_AURORAE="Arc"; ARC_KVANTUM="Arc"
  ARC_GTK="Arc-Lighter"; BREEZE_SCHEME="BreezeLight"
  # names of this variant's themes, installed next to the dark ones
  THEME_ID="RedRog-Light"; THEME_LABEL="RedRog Light"; LNF_ID="org.redrog.light.desktop"
  # derived tones (below): the light counterparts of the dark ones
  # light glass needs more body than dark: dark text over it must still read
  # (APCA Lc 60, the blend at Y 0.4) over a black wallpaper, as macOS's light
  # materials do (about 0.7)
  GLASS_ALPHA=0.75
  TRACK="c8c4bc"; TRACK_EDGE="b8b4ac"; CONTROL_HI="d2cec6"; SIDEBAR="e8e5df"; OVERLAY="000000"; TEXT_SOFT="4a4743"; TEXT_STRONG="$FG"
else
  THEME_VARIANT=dark
  ARC_COLORS="ArcDark.colors"; ARC_PLASMA="Arc-Dark"; ARC_AURORAE="Arc-Dark"; ARC_KVANTUM="ArcDark"
  ARC_GTK="Arc-Dark"; BREEZE_SCHEME="BreezeDark"
  # names of this variant's themes (color scheme, Plasma style, Kvantum,
  # window decoration, GTK) and of its global theme
  THEME_ID="RedRog"; THEME_LABEL="RedRog"; LNF_ID="org.redrog.desktop"
  # Derived tones: a switch's track when off, a focused button or combo box,
  # sidebars (a shade off the window), the color of translucent veils and
  # hairlines over the glass (white on dark, black on light), softer text and
  # the strongest text (a selected tab)
  # opacity of the frosted dialogs, menus and popups over the blur
  GLASS_ALPHA=0.5
  TRACK="4a4948"; TRACK_EDGE="3d3c3b"; CONTROL_HI="3a3a39"; SIDEBAR="161616"; OVERLAY="ffffff"; TEXT_SOFT="c9c7c2"; TEXT_STRONG="ffffff"
fi
# This variant's wallpaper as a Plasma wallpaper package named after it
# ("RedRog", "RedRog Light"; modules/global-theme makes it from WALLPAPER)
WALLPAPER_FILE=$WALLPAPER
WALLPAPER_PKG="$HOME/.local/share/wallpapers/$THEME_ID"
