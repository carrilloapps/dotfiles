#!/usr/bin/env bash
# RedRog installer. See README.md and docs/INSTALL.md.
#
#   ./install.sh --all               everything, in one go: packages (and the
#                                    PKGBUILDs to compile), theme, top bar and
#                                    dock, root steps
#   ./install.sh                     apply the theme (no root needed)
#   ./install.sh --layout            also build the macOS-like top bar and dock
#   ./install.sh --packages          install dependencies (pacman, AUR, local PKGBUILDs)
#   ./install.sh --system            root steps: Limine, login screen, ROG translation, network
#   ./install.sh --only gtk,terminal  only those modules
#   ./install.sh --dry-run ...       show what would happen without changing anything
#   ./install.sh --list              list the modules
set -eo pipefail
REDROG_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export REDROG_ROOT

# User modules, in the order they are applied
MODULES=(colors plasma-style kvantum window-decoration gtk appearance terminal firefox chrome spotify
         notifications rog-notify asus-laptop global-theme visualizer audio audacity obs steam
         dolphin hud apps artcraft thunderbird touchpad keyboard theme-switch maintenance)

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; }

DO_LAYOUT=0; DO_PACKAGES=0; DO_SYSTEM=0; SYSTEM_STAGE=0; LIST=0; ONLY=""; export DRY_RUN=0
while [ $# -gt 0 ]; do
  case "$1" in
    --all)          DO_PACKAGES=1; DO_LAYOUT=1; DO_SYSTEM=1 ;;
    --layout)       DO_LAYOUT=1 ;;
    --packages)     DO_PACKAGES=1 ;;
    --system)       DO_SYSTEM=1 ;;
    --system-stage) SYSTEM_STAGE=1 ;;   # internal: already running as root
    --only)         ONLY="${2:?--only needs a list of modules}"; shift ;;
    --dry-run)      DRY_RUN=1 ;;
    --list)         LIST=1 ;;
    -h|--help)      usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 1 ;;
  esac
  shift
done

source "$REDROG_ROOT/lib/common.sh"

# "# describe: English | Español" line of each module, in the user's language
describe() {
  local d; d=$(sed -n 's/^# describe: //p' "$REDROG_ROOT/modules/$1/install.sh")
  L "${d%% | *}" "${d##* | }"
}
run_module() {
  step "$1 — $(describe "$1")"
  ( set -eo pipefail; source "$REDROG_ROOT/lib/common.sh"; source "$REDROG_ROOT/modules/$1/install.sh" )
}

if [ "$LIST" = 1 ]; then
  for m in "${MODULES[@]}" layout system; do printf '  %-18s %s\n' "$m" "$(describe "$m")"; done
  exit 0
fi

# ── Root stage (re-executed through sudo) ────────────────────────────────────
if [ "$SYSTEM_STAGE" = 1 ]; then
  run_module system
  exit 0
fi

[ "$(id -u)" != 0 ] || die "$(L "Don't run the installer with sudo: it asks for it when needed (--packages, --system)" \
                               "No ejecutes el instalador con sudo: lo pide cuando hace falta (--packages, --system)")"
has plasmashell || die "$(L "RedRog targets KDE Plasma 6 and plasmashell was not found" \
                            "RedRog es para KDE Plasma 6 y no se encontró plasmashell")"

# ── Dependencies ─────────────────────────────────────────────────────────────
list_packages() { grep -vE '^\s*(#|$)' "$REDROG_ROOT/packages/$1"; }

# A package of packages/ needs no build when every package it makes is
# installed at its version or a newer one (makepkg's --needed only looks at
# the end, after building, and installs an older version over a newer one).
# The KWin effects are rebuilt after every KWin update by their own pacman
# hooks, not here. REDROG_REBUILD=1 builds them all.
local_package_current() {   # PKGBUILD folder
  [ "${REDROG_REBUILD:-0}" = 1 ] && return 1
  local info epoch ver rel want name have
  info=$(cd "$1" && makepkg --printsrcinfo 2>/dev/null) || return 1
  epoch=$(sed -n 's/^\tepoch = //p' <<< "$info" | head -1)
  ver=$(sed -n 's/^\tpkgver = //p' <<< "$info" | head -1)
  rel=$(sed -n 's/^\tpkgrel = //p' <<< "$info" | head -1)
  [ -n "$ver" ] && [ -n "$rel" ] || return 1
  want="${epoch:+$epoch:}$ver-$rel"
  while read -r name; do
    have=$(pacman -Q "$name" 2>/dev/null | awk '{print $2}')
    [ -n "$have" ] && [ "$(vercmp "$have" "$want")" -ge 0 ] || return 1
  done < <(sed -n 's/^pkgname = //p' <<< "$info")
  return 0
}

install_packages() {
  step "$(L "Repository packages" "Paquetes de los repositorios")"
  mapfile -t pkgs < <(list_packages pacman.txt)
  run sudo pacman -S --needed "${pkgs[@]}"

  step "$(L "AUR packages" "Paquetes del AUR")"
  local helper=""
  for h in paru yay; do has "$h" && { helper=$h; break; }; done
  mapfile -t aur < <(list_packages aur.txt)
  if [ -n "$helper" ]; then
    # without the packages' own test suites: some fail on newer Python versions
    # although the program works
    run "$helper" -S --needed --mflags --nocheck "${aur[@]}"
  else
    warn "$(L "no AUR helper (paru/yay) found; install manually:" "no hay ayudante del AUR (paru/yay); instala a mano:") ${aur[*]}"
  fi

  step "$(L "Patched packages (packages/)" "Paquetes con correcciones (packages/)")"
  local pkg tmp
  while read -r pkg; do
    # the RedRog ROG Control Center only on ASUS laptops (asusctl present)
    [ "$pkg" = rog-control-center ] && ! has asusctl && continue
    if [ "$pkg" = rog-control-center ]; then
      # translations compiled by modules/system for the official package (no
      # package owns them) would block installing the RedRog edition
      for mo in /usr/share/locale/*/LC_MESSAGES/rog-control-center.mo; do
        [ -e "$mo" ] && ! pacman -Qo "$mo" >/dev/null 2>&1 && run sudo rm -f "$mo"
      done
    fi
    if local_package_current "$REDROG_ROOT/packages/$pkg"; then
      info "$(L "$pkg: installed and current" "$pkg: instalado y al día")"
      continue
    fi
    tmp=$(mktemp -d)
    run cp -r "$REDROG_ROOT/packages/$pkg/." "$tmp/"
    ( cd "$tmp" && REDROG_ROOT="$REDROG_ROOT" run makepkg -si --needed --noconfirm )
    rm -rf "$tmp"
  done < <(list_packages local.txt)

  if has papirus-folders; then run papirus-folders -C "$ICON_FOLDER_COLOR" --theme "$ICON_THEME"; fi
}

# ── Migration from earlier (pre-RedRog) names ────────────────────────────────
migrate_legacy() {
  local p found=0
  for p in \
    "$DATA_HOME/color-schemes/ArcDarkROG.colors" "$CONFIG_HOME/Kvantum/ArcDarkROG" \
    "$DATA_HOME/plasma/desktoptheme/Arc-Dark" "$DATA_HOME/aurorae/themes/Arc-Dark" \
    "$DATA_HOME/themes/Arc-Dark-ROG" "$DATA_HOME/konsole/ArcDarkROG.colorscheme" \
    "$DATA_HOME/konsole/ArcROG.profile" "$DATA_HOME/plasma/look-and-feel/org.local.arcdarkrog" \
    "$DATA_HOME/plasma/plasmoids/org.local.batterypercent" \
    "$DATA_HOME/applications/dock-descargas.desktop" "$DATA_HOME/applications/dock-papelera.desktop"; do
    if [ -e "$p" ] || [ -L "$p" ]; then run rm -rf "$p"; found=1; fi
  done
  [ "$found" = 0 ] || info "$(L "removed leftovers from earlier versions" "eliminados restos de versiones anteriores")"
}

[ "$DO_PACKAGES" = 1 ] && install_packages

if [ -n "$ONLY" ]; then
  IFS=, read -r -a MODULES <<< "$ONLY"
else
  step "$(L "Migration" "Migración")"
  migrate_legacy
fi
for m in "${MODULES[@]}"; do
  [ -f "$REDROG_ROOT/modules/$m/install.sh" ] || die "$(L "unknown module: $m (see --list)" "módulo desconocido: $m (ver --list)")"
  case "$m" in
    system) DO_SYSTEM=1 ;;
    layout) DO_LAYOUT=1 ;;
    *)      run_module "$m" ;;
  esac
done
[ "$DO_LAYOUT" = 1 ] && run_module layout

if [ "$DO_SYSTEM" = 1 ]; then
  step "$(L "Root steps" "Pasos con root")"
  sudo env REDROG_ROOT="$REDROG_ROOT" DRY_RUN="$DRY_RUN" LANG="${LANG:-}" \
       bash "$REDROG_ROOT/install.sh" --system-stage
fi

step "$(L "Done" "Listo")"
info "$(L "Log out and back in so everything (KWin, Kvantum) reloads." \
          "Cierra sesión y vuelve a entrar para que todo (KWin, Kvantum) se recargue.")"
