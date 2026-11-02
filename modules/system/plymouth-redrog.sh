#!/usr/bin/env bash
# RedRog boot splash: the animated Arch logo of arch-charge-big (AUR
# plymouth-theme-arch-charge-big) on absolute black, with the logo and its glow
# in the RedRog accent instead of Arch blue. Built into
# /usr/share/plymouth/themes/redrog-arch by modules/system (root).
# Usage: plymouth-redrog.sh ACCENT_HEX
set -euo pipefail
ACCENT="${1:?accent color}"
SRC=/usr/share/plymouth/themes/arch-charge-big
DST=/usr/share/plymouth/themes/redrog-arch
[ -d "$SRC" ] || { echo "arch-charge-big is not installed" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cp "$SRC"/*.png "$tmp/"
# the logo frames: their brightness mapped from black to the accent, keeping
# the transparency (the password prompt pieces stay as they are)
for f in "$tmp"/progress-*.png "$tmp"/throbber-*.png; do
  magick "$f" \( +clone -alpha extract \) \
    \( -clone 0 -alpha off -colorspace gray +level-colors "#000000","#$ACCENT" \) \
    -delete 0 +swap -compose CopyOpacity -composite "$f"
done
cat > "$tmp/redrog-arch.plymouth" <<EOP
[Plymouth Theme]
Name=RedRog Arch
Description=The animated Arch logo (Arch Charge Big) in the RedRog colors, on black
ModuleName=two-step

[two-step]
ImageDir=$DST
HorizontalAlignment=.5
VerticalAlignment=.5
Transition=none
TransitionDuration=0.0
BackgroundStartColor=0x000000
BackgroundEndColor=0x000000
EOP
rm -rf "$DST"
install -d "$DST"
install -m644 "$tmp"/* "$DST/"
