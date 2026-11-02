#!/usr/bin/env bash
# Restores the manifest.txt paths into $HOME from this folder (never touches /etc).
# Usage: scripts/restore.sh [commit]   — without a commit, uses the working tree.
# Before overwriting, saves a copy in ~/.cache/dotfiles-backup/<date>/.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
REF="${1:-}"
BK="$HOME/.cache/dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

if [[ -n "$REF" ]]; then
  TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
  git -C "$REPO" archive "$REF" home | tar -x -C "$TMP"
  SRC_ROOT="$TMP/home"
else
  SRC_ROOT="$REPO/home"
fi

while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* || "$line" == /* ]] && continue
  rel="${line%/}"
  src="$SRC_ROOT/$rel"; dst="$HOME/$rel"
  if [[ -e "$dst" ]]; then
    mkdir -p "$(dirname "$BK/$rel")"; cp -a "$dst" "$BK/$rel"
  fi
  if [[ -e "$src" ]]; then
    rm -rf "$dst"; mkdir -p "$(dirname "$dst")"; cp -a "$src" "$dst"
  fi
done < "$REPO/manifest.txt"

echo "Previous files saved in: $BK"
echo "Log out and back in so KDE re-reads everything."
