#!/usr/bin/env bash
# Shared helpers for install.sh, uninstall.sh and the modules.
# Usage: source "$REDROG_ROOT/lib/common.sh"

REDROG_ROOT="${REDROG_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
REDROG_NAME="RedRog"
VENDOR_ARC="$REDROG_ROOT/vendor/arc-kde"
DRY_RUN="${DRY_RUN:-0}"

# The system's tools first: a python3 from Homebrew (or pyenv, conda...) earlier
# in PATH lacks the distribution's modules (Pillow) and broke the GTK module
export PATH="/usr/bin:/usr/local/bin:$PATH"

# Real user (also under sudo) and their XDG directories
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(getent passwd "$REAL_USER" | cut -d: -f6)"
DATA_HOME="${XDG_DATA_HOME:-$REAL_HOME/.local/share}"
CONFIG_HOME="${XDG_CONFIG_HOME:-$REAL_HOME/.config}"

# Configuration: defaults + the user's own overrides (config/user.conf) and
# the dark or light variant (lib/palette.sh)
HOME="$REAL_HOME" source "$REDROG_ROOT/lib/palette.sh"

# ── Localized messages ───────────────────────────────────────────────────────
# L "English text" "Texto en español": prints the one matching the user's locale.
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
  es*) REDROG_LANG=es ;;
  *)   REDROG_LANG=en ;;
esac
L() { if [ "$REDROG_LANG" = es ] && [ -n "${2:-}" ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }

c_red=$'\e[1;31m'; c_dim=$'\e[2m'; c_off=$'\e[0m'
[ -t 1 ] || { c_red=""; c_dim=""; c_off=""; }
step() { printf '\n%s▶%s %s\n' "$c_red" "$c_off" "$*"; }
info() { printf '  %s\n' "$*"; }
warn() { printf '  %s!%s %s\n' "$c_red" "$c_off" "$*" >&2; }
die()  { printf '%s✗%s %s\n' "$c_red" "$c_off" "$*" >&2; exit 1; }

# ── Actions (honor --dry-run) ────────────────────────────────────────────────
run() {
  if [ "$DRY_RUN" = 1 ]; then printf '  %s[dry-run]%s %s\n' "$c_dim" "$c_off" "$*"; else "$@"; fi
}
# A negative value ("-80") would be read as options: "--" goes before it
kw() {
  local last="${!#}"
  if [[ "$last" == -[0-9]* ]]; then run kwriteconfig6 "${@:1:$#-1}" -- "$last"
  else run kwriteconfig6 "$@"; fi
}
recolor() { run python3 -I "$REDROG_ROOT/lib/recolor.py" "$@"; }
# Both variants are installed side by side (RedRog and RedRog-Light) so
# redrog-theme-switch can move between them in seconds.
# for_each_variant CMD...: runs CMD once per variant, dark then light, in a
# subshell with that variant's palette and REDROG_NAME set to its theme id
for_each_variant() {
  local v
  for v in dark light; do
    ( export REDROG_VARIANT=$v; HOME="$REAL_HOME" source "$REDROG_ROOT/lib/palette.sh"
      REDROG_NAME=$THEME_ID; "$@" ) || return 1
  done
}
# repaint_variants SRC DEST: DEST gets SRC in the active palette (repaint);
# both variants are kept in ~/.local/lib/redrog/variants and listed in its
# manifest, for redrog-theme-switch to swap in
VARIANTS_DIR="$REAL_HOME/.local/lib/redrog/variants"
repaint_variants() {
  [ "$DRY_RUN" = 1 ] && return 0
  local src=$1 dest=$2 id v
  id=$(printf '%s' "${dest#"$REAL_HOME"/}" | tr '/' '%')
  for v in dark light; do
    mkdir -p "$VARIANTS_DIR/$v"
    ( export REDROG_VARIANT=$v; HOME="$REAL_HOME" source "$REDROG_ROOT/lib/palette.sh"
      install -m "$(stat -c %a "$src")" "$src" "$VARIANTS_DIR/$v/$id"; repaint "$VARIANTS_DIR/$v/$id" )
  done
  touch "$VARIANTS_DIR/manifest"
  grep -qxF "$id|$dest" "$VARIANTS_DIR/manifest" || printf '%s|%s\n' "$id" "$dest" >> "$VARIANTS_DIR/manifest"
  mkdir -p "$(dirname "$dest")"
  install -m "$(stat -c %a "$src")" "$VARIANTS_DIR/$THEME_VARIANT/$id" "$dest"
}

# repaint FILE...: files written in RedRog's dark palette (QML widgets,
# scripts) take the active palette, in place. On the dark variant with the
# stock palette nothing changes. Accent first: the light hover is the dark accent
repaint() {
  [ "$DRY_RUN" = 1 ] && return 0
  sed -i -e "s/ef3340/$ACCENT/gI; s/f8485e/$ACCENT_ALT/gI" \
         -e "s/1c1c1c/$BG/gI; s/252524/$SURFACE/gI; s/313131/$SURFACE_HI/gI; s/2b2b2a/$SELECTION/gI" \
         -e "s/efeeeb/$FG/gI; s/888680/$FG_DIM/gI; s/c9c7c2/$TEXT_SOFT/gI" \
         -e "s/161616/$SIDEBAR/gI; s/3a3a39/$CONTROL_HI/gI; s/4a4948/$TRACK/gI" "$@"
}

has() { command -v "$1" >/dev/null 2>&1; }
need() {
  has "$1" || die "$(L "Missing command '$1'. Install the dependencies: ./install.sh --packages" \
                       "Falta el comando '$1'. Instala las dependencias: ./install.sh --packages")"
}

# Runs a Plasma (JavaScript) script in plasmashell
plasma_script() {
  if [ "$DRY_RUN" = 1 ]; then
    printf '  %s[dry-run]%s plasmashell evaluateScript (%s lines)\n' "$c_dim" "$c_off" "$(printf '%s\n' "$1" | wc -l)"
  else
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$1"
  fi
}

# QML (Qt Quick / Kirigami) apps and dialogs that paint an opaque background
# the Qt style cannot make translucent: the RedRog glass effect makes their
# content translucent at the title bar's opacity and Better Blur DX blurs
# behind them (modules/window-decoration, modules/plasma-style). Window
# classes, as KWin reports them.
QML_GLASS_APPS=(
  systemsettings org.kde.discover org.kde.plasma-systemmonitor org.kde.kinfocenter
  com.github.wwmm.easyeffects
  org.kde.polkit-kde-authentication-agent-1   # "Authentication required"
  xdg-desktop-portal-kde                      # screen sharing, permissions
  org.kde.kdeconnect.app org.kde.kdeconnect.handler
  # Dolphin, a Qt widgets app: Darkly's own translucency does not reach its
  # window here, so its glass (as the Kvantum theme gave it) comes from the
  # effect too, live for any window whenever the app started
  org.kde.dolphin
)
