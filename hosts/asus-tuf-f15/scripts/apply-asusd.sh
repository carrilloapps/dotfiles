#!/usr/bin/env bash
# Installs the asusd configuration tuned for the ASUS TUF Gaming F15 FX507ZC4
# (power limits and fan curves per profile, charge limit, keyboard color) from
# system/etc/asusd. It refuses to run on another model. Needs root:
#   sudo hosts/asus-tuf-f15/scripts/apply-asusd.sh
# asusd writes its config back when it stops, so it is stopped first. The
# current files are saved in /var/backups/redrog/asusd-<date>/.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "Run with sudo" >&2; exit 1; }
# Power limits and fan curves are specific to this model
model="$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
case "$model" in
  *FX507ZC*) ;;
  *) echo "This profile is for the ASUS TUF Gaming F15 FX507ZC4, not \"$model\". Nothing changed." >&2; exit 1 ;;
esac
SRC="$(cd "$(dirname "$0")/.." && pwd)/system/etc/asusd"
BK="/var/backups/redrog/asusd-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BK"
cp -a /etc/asusd/. "$BK/"
systemctl stop asusd
install -m644 "$SRC"/*.ron /etc/asusd/
systemctl start asusd
echo "asusd configuration installed (backup: $BK)"
