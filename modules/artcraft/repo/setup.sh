#!/usr/bin/env bash
# Root part of the artcraft module: the local repository [redrog-artcraft]
# (sync script, its 6-hourly timer and the pacman.conf section), filled once
# right away. Run through sudo by modules/artcraft/install.sh.
set -euo pipefail
[ "$(id -u)" = 0 ] || { echo "setup.sh: needs root" >&2; exit 1; }
here=$(dirname "$(readlink -f "$0")")
REPO=/var/lib/redrog-artcraft-repo
install -D -m 755 "$here/artcraft-repo-sync" /usr/local/lib/redrog/artcraft-repo-sync
install -m 644 "$here/redrog-artcraft-repo.service" "$here/redrog-artcraft-repo.timer" /etc/systemd/system/
install -D -m 644 "$here/redrog-sysusers.conf" /etc/sysusers.d/redrog-artcraft.conf
# the GPU at 76 % while ArtCraft runs (only with an NVIDIA card)
if command -v nvidia-smi >/dev/null; then
  install -D -m 755 "$here/craft-gpu-cap" /usr/local/lib/redrog/craft-gpu-cap
  install -m 644 "$here/redrog-craft-gpu.service" /etc/systemd/system/
fi
systemd-sysusers /etc/sysusers.d/redrog-artcraft.conf

# the section of the first versions (folder written by root) is replaced
if grep -q '^Server = file:///var/lib/redrog/artcraft-repo$' /etc/pacman.conf; then
  sed -i 's|^Server = file:///var/lib/redrog/artcraft-repo$|Server = file://'"$REPO"'|' /etc/pacman.conf
fi
# its packages move to the service's own folder (systemd hands it to the
# service's user at start) instead of being downloaded again
if [ -d /var/lib/redrog/artcraft-repo ] && [ ! -e "$REPO" ]; then
  mv /var/lib/redrog/artcraft-repo "$REPO"
fi
rm -rf /var/lib/redrog/artcraft-repo
rmdir /var/lib/redrog 2>/dev/null || true

if ! grep -q '^\[redrog-artcraft\]' /etc/pacman.conf; then
  install -d /var/backups/redrog
  cp -a /etc/pacman.conf "/var/backups/redrog/pacman.conf.$(date +%Y%m%d-%H%M%S)"
  # the upstream packages are not signed: artcraft-repo-sync checks each one
  # against its release's SHA256SUMS.txt (over HTTPS) and its package name
  cat >> /etc/pacman.conf <<EOF

# ArtCraft suite, mirrored from its official GitHub releases (RedRog,
# modules/artcraft): /usr/local/lib/redrog/artcraft-repo-sync
[redrog-artcraft]
SigLevel = Optional TrustAll
Server = file://$REPO
EOF
fi

systemctl daemon-reload
systemctl enable --now redrog-artcraft-repo.timer >/dev/null 2>&1
if [ -f /etc/systemd/system/redrog-craft-gpu.service ]; then
  systemctl enable redrog-craft-gpu.service >/dev/null 2>&1
  systemctl restart redrog-craft-gpu.service
fi
# a oneshot: returns when the sync has finished
systemctl start redrog-artcraft-repo.service || echo "setup.sh: some projects could not be checked (journalctl -u redrog-artcraft-repo)" >&2
# what pacman -Sy would fetch for this repository alone (a full -Sy without
# -u would leave the system half-updated), so pacman knows it from now on
install -m 644 "$REPO/redrog-artcraft.db.tar.gz" /var/lib/pacman/sync/redrog-artcraft.db
