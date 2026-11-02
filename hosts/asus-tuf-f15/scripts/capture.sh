#!/usr/bin/env bash
# Copies the current state of every path in manifest.txt into this folder.
# Usage: scripts/capture.sh   (then: git diff / git commit)
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"

while IFS= read -r line; do
  [[ -z "$line" || "$line" == \#* ]] && continue
  if [[ "$line" == /* ]]; then
    src="$line"; dst="$REPO/system${line}"
  else
    src="$HOME/$line"; dst="$REPO/home/$line"
  fi
  src="${src%/}"; dst="${dst%/}"
  rm -rf "$dst"
  [[ -e "$src" ]] || continue
  mkdir -p "$(dirname "$dst")"
  if [[ -d "$src" ]]; then
    cp -a --no-preserve=ownership "$src" "$dst" 2>/dev/null || cp -r "$src" "$dst"
  else
    cp --no-preserve=ownership "$src" "$dst" 2>/dev/null || true
  fi
done < "$REPO/manifest.txt"

git -C "$REPO" status --short
