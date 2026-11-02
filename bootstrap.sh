#!/usr/bin/env bash
# RedRog in one command, on a fresh Arch / CachyOS with KDE Plasma 6:
# gets the repository into ~/.dotfiles (or updates it) and runs
# ./install.sh --all (packages, theme, top bar and dock, root steps).
#
# One-liner to run from any terminal:
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/carrilloapps/dotfiles/main/bootstrap.sh)"
# or with wget:
#   bash -c "$(wget -qO- https://raw.githubusercontent.com/carrilloapps/dotfiles/main/bootstrap.sh)"
#
# Options are passed to install.sh (e.g. bash -c "$(...)" _ --dry-run).
# REDROG_DIR changes the target folder (default ~/.dotfiles).
set -euo pipefail
REPO=carrilloapps/dotfiles
DIR="${REDROG_DIR:-$HOME/.dotfiles}"

say() { printf '\033[1;31m▶\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m✗\033[0m %s\n' "$*" >&2; exit 1; }

[ "$(id -u)" != 0 ] || die "Run it as your user, not with sudo: it asks for sudo when needed."
command -v pacman >/dev/null || die "RedRog needs Arch Linux or CachyOS (pacman)."
command -v plasmashell >/dev/null || die "RedRog needs KDE Plasma 6."

# git is the only prerequisite needed to fetch the dotfiles
missing=()
command -v git >/dev/null || missing+=(git)
if [ ${#missing[@]} -gt 0 ]; then
  say "Installing ${missing[*]}"
  sudo pacman -S --needed --noconfirm "${missing[@]}"
fi

if [ -d "$DIR/.git" ]; then
  say "Updating $DIR"
  git -C "$DIR" pull --ff-only
else
  say "Downloading RedRog into $DIR"
  if ssh -o BatchMode=yes -o ConnectTimeout=3 -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    git clone "git@github.com:$REPO.git" "$DIR"
  elif command -v gh >/dev/null && gh auth status >/dev/null 2>&1; then
    gh repo clone "$REPO" "$DIR"
  else
    git clone "https://github.com/$REPO.git" "$DIR"
  fi
fi

say "Running the installer"
cd "$DIR"
exec ./install.sh --all "$@"
