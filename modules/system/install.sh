#!/usr/bin/env bash
# Root steps (./install.sh --system, which re-runs itself through sudo):
#  1. Limine: plain dark menu in the theme colors, no wallpaper (global options
#     only, with a backup, a boot-entry count check and config-hash
#     re-enrollment).
#  2. Login screen (Plasma Login Manager): the RedRog look system-wide and for
#     the greeter's own user (colors, Plasma style, Qt style, icons, fonts,
#     cursor), with the clock (as "9:10 PM", also when locked) and the wallpaper
#     of the user's main screen (kept current by their session).
#  3. ROG Control Center translations from i18n/rog-control-center (if installed).
#  4. Network and Bluetooth without power saving (Wi-Fi, Ethernet EEE, runtime
#     PM, Bluetooth autosuspend) and BBR congestion control.
#  5. On the FX507ZC4: the captured asusd profiles (the gaming mode), once; on
#     any asusd machine: power limits applied at every start and the profile
#     picked by hand kept (asusd-profile-keeper.sh).
#  6. Background maintenance (updatedb, man-db, scrub...) at idle priority.
#  7. AUR builds with the system's tools only (no Homebrew in makepkg's PATH).
#  8. The user in the gamemode and adbusers groups (GameMode's CPU governor,
#     adb with phones on USB).
#  9. Virtual cameras (v4l2loopback): the phone as a webcam with scrcpy, OBS.
# 10. Keyboard layouts in the system keymap (KEYBOARD_LAYOUTS), for KWin and
#     the login screen, whose layout follows the keyboard in use too
#     (KEYBOARD_AUTO_DEVICES).
# Backups of what changes are kept in /var/backups/redrog/<date>/.
# describe: Limine, login screen, ROG translation, network at full power | Limine, inicio de sesión, traducción de ROG, red a máxima potencia

[ "$(id -u)" = 0 ] || die "$(L "this module needs root: ./install.sh --system" "este módulo necesita root: ./install.sh --system")"
BK=/var/backups/redrog/$(date +%Y%m%d-%H%M%S)
run mkdir -p "$BK"

# ── 1. Limine ────────────────────────────────────────────────────────────────
# A broken limine.conf leaves the machine unbootable: back up, touch only global
# keys between markers, and verify that the boot entries did not change.
LC=/boot/limine.conf
# The boot menu and the boot splash are always RedRog's dark look, whatever
# the light/dark variant: absolute black, white text, the RedRog red
read -r BOOT_FG BOOT_FG_DIM BOOT_ACCENT BOOT_ACCENT_ALT < <(REDROG_VARIANT=dark HOME="$REAL_HOME" bash -c \
  'source "$REDROG_ROOT/lib/palette.sh"; echo "$FG $FG_DIM $ACCENT $ACCENT_ALT"')
if [ -f "$LC" ]; then
  step "Limine"
  run cp -a "$LC" "$BK/limine.conf"
  # Plain dark menu in the theme colors, no wallpaper image (nothing for
  # Limine to decode or blend, so it is also the fastest)
  run rm -f /boot/redrog-wallpaper.jpg
  # The Limine step is a standalone script with the palette baked in, so the
  # pacman hook below can re-apply it after kernel, Limine or theme updates
  # (CachyOS rewrites limine.conf then)
  LT=/usr/local/lib/redrog/limine-theme.sh
  if [ "$DRY_RUN" != 1 ]; then
    install -d /usr/local/lib/redrog
    sed -e "s/@BG@/000000/g; s/@FG@/$BOOT_FG/g; s/@FG_DIM@/$BOOT_FG_DIM/g; s/@ACCENT@/$BOOT_ACCENT/g" \
        -e "s/@ACCENT_ALT@/$BOOT_ACCENT_ALT/g; s|@BRANDING@|$LIMINE_BRANDING|g" \
        "$REDROG_ROOT/modules/system/limine-theme.sh" > "$LT"
    chmod 755 "$LT"
    install -Dm644 "$REDROG_ROOT/modules/system/zz-redrog-limine.hook" /etc/pacman.d/hooks/zz-redrog-limine.hook
    "$LT" "$BK" || die "$(L "Limine step failed (backup restored)" "falló el paso de Limine (copia restaurada)")"
    info "$(L "boot entries intact; re-applied after updates by a pacman hook" "entradas intactas; se vuelve a aplicar tras las actualizaciones con un hook de pacman")"
  fi
else
  info "$(L "no /boot/limine.conf: Limine skipped" "no hay /boot/limine.conf: se omite Limine")"
fi

# ── Boot speed ───────────────────────────────────────────────────────────────
# Nothing on a desktop needs the network to be fully up before the login
# screen; waiting for it added ~5 s to every boot
if systemctl is-enabled NetworkManager-wait-online.service >/dev/null 2>&1; then
  run systemctl disable NetworkManager-wait-online.service >/dev/null 2>&1 || true
  info "$(L "boot no longer waits for the network" "el arranque ya no espera a la red")"
fi

# ── 2. Login screen ──────────────────────────────────────────────────────────
step "$(L "Login screen" "Pantalla de inicio de sesión")"
# Only RedRog's own wallpapers (RedRog and RedRog Light, in the user's
# wallpapers) in the wallpaper picker: copies left in the system by earlier
# versions go (when no package owns them), pacman no longer installs the
# wallpapers that themes and Plasma packages bring (NoExtract, kept across
# updates; pacman.conf backed up), and the ones already there are removed
# (a reinstall would not: their files are still the package's)
for old in /usr/share/wallpapers/RedRog /usr/share/wallpapers/ROG-Lluvia; do
  [ -e "$old" ] && ! pacman -Qqo "$old" >/dev/null 2>&1 && run rm -rf "$old"
done
if ! grep -q '^NoExtract *=.*usr/share/wallpapers/\*' /etc/pacman.conf; then
  run cp -a /etc/pacman.conf "$BK/pacman.conf"
  if [ "$DRY_RUN" != 1 ]; then
    # under [options], before the first repository
    sed -i '0,/^\[options\]/s//[options]\n# RedRog (modules\/system): only the theme'"'"'s own wallpapers\nNoExtract = usr\/share\/wallpapers\/*/' /etc/pacman.conf
  fi
fi
if grep -q '^NoExtract *=.*usr/share/wallpapers/\*' /etc/pacman.conf; then
  removed=0
  for d in /usr/share/wallpapers/*/; do
    [ -d "$d" ] || continue
    # only what a package brought (anything else there is left alone)
    pacman -Qqo "$d" >/dev/null 2>&1 || continue
    run rm -rf "$d"; removed=$((removed + 1))
  done
  [ "$removed" = 0 ] || info "$(L "only RedRog's wallpapers in the picker ($removed package wallpapers removed)" "solo los fondos de RedRog en el selector ($removed fondos de paquetes quitados)")"
fi

# IgnorePkg para paquetes AUR problemáticos (bucle de pkgver en -git)
if ! grep -q '^IgnorePkg *=.*obs-plugin-waveform-git' /etc/pacman.conf; then
  [ -e "$BK/pacman.conf" ] || run cp -a /etc/pacman.conf "$BK/pacman.conf"
  if [ "$DRY_RUN" != 1 ]; then
    if grep -q '^IgnorePkg *=' /etc/pacman.conf; then
      sed -i '/^IgnorePkg *=/ s/$/ obs-plugin-waveform-git/' /etc/pacman.conf
    else
      sed -i '/^\[options\]/a IgnorePkg = obs-plugin-waveform-git' /etc/pacman.conf
    fi
  fi
fi

# The greeter runs as its own user and cannot read the user's home: install the
# generated RedRog theme pieces system-wide
U_DATA="$DATA_HOME" U_CONF="$CONFIG_HOME"
run install -Dm644 "$U_DATA/color-schemes/$REDROG_NAME.colors" "/usr/share/color-schemes/$REDROG_NAME.colors"
run rm -rf "/usr/share/plasma/desktoptheme/$REDROG_NAME" "/usr/share/Kvantum/$REDROG_NAME"
run cp -r "$U_DATA/plasma/desktoptheme/$REDROG_NAME" "/usr/share/plasma/desktoptheme/$REDROG_NAME"
run cp -r "$U_CONF/Kvantum/$REDROG_NAME" "/usr/share/Kvantum/$REDROG_NAME"
for icon in redrog redrog-badge; do
  run install -Dm644 "$U_DATA/icons/hicolor/scalable/apps/$icon.svg" "/usr/share/icons/hicolor/scalable/apps/$icon.svg"
done
run chmod -R a+rX "/usr/share/plasma/desktoptheme/$REDROG_NAME" "/usr/share/Kvantum/$REDROG_NAME"

# Greeter user settings: same colors, style, icons, fonts and cursor
GH=$(getent passwd plasmalogin | cut -d: -f6)
if [ -n "$GH" ]; then
  GC="$GH/.config"
  run mkdir -p "$GC/Kvantum"
  # Only the color groups and fonts of the user's kdeglobals (no personal data
  # such as recent file dialog paths)
  if [ "$DRY_RUN" != 1 ]; then
    python3 -I - "$U_CONF/kdeglobals" "$GC/kdeglobals" <<'PY'
import re, sys
src, dst = sys.argv[1:]
keep = re.compile(r"^\[(Colors:[^\]]+|ColorEffects:[^\]]+|WM)\]$")
fonts = ("font", "fixed", "menuFont", "smallestReadableFont", "toolBarFont", "activeFont")
out, group = [], None
for line in open(src, encoding="utf-8"):
    line = line.rstrip("\n")
    if line.startswith("["):
        group = line
        if keep.match(line):
            out.append("\n" + line)
        continue
    key = line.split("=", 1)[0]
    if group and keep.match(group):
        out.append(line)
    elif group == "[General]" and key in fonts:
        out.append(("\n[General]\n" if "[General]" not in "\n".join(out) else "") + line)
open(dst, "w", encoding="utf-8").write("\n".join(out).lstrip() + "\n")
PY
  fi
  gkw() { run kwriteconfig6 --file "$GC/$1" "${@:2}"; }
  gkw kdeglobals --group KDE --key LookAndFeelPackage "$([ "$THEME_VARIANT" = light ] && echo org.kde.breeze.desktop || echo org.kde.breezedark.desktop)"
  gkw kdeglobals --group KDE --key widgetStyle "$([ -e /usr/lib/qt6/plugins/styles/darkly6.so ] && echo Darkly || echo kvantum)"
  gkw kdeglobals --group General --key ColorScheme "$REDROG_NAME"
  gkw kdeglobals --group Icons --key Theme "$ICON_THEME"
  gkw plasmarc --group Theme --key name "$REDROG_NAME"
  gkw kcminputrc --group Mouse --key cursorTheme "$CURSOR_THEME"
  gkw Kvantum/kvantum.kvconfig --group General --key theme "$REDROG_NAME"
  # Num Lock on from the login screen, the first place anything is typed
  gkw kcminputrc --group Keyboard --key NumLock 0
  run chown -R plasmalogin:plasmalogin "$GC"
fi

# Wallpaper and clock (Plasma Login Manager configuration). The login screen
# shows the wallpaper of the user's main screen: their session
# (redrog-wallpaper-sync, modules/visualizer) re-encodes it into a folder of
# theirs that the greeter reads, so a wallpaper changed by hand is there at
# the next login. Until then it is RedRog's.
LOGIN_WP=/var/lib/redrog-login
run install -d -m 755 -o "$REAL_USER" -g "$(id -gn "$REAL_USER")" "$LOGIN_WP"
if [ "$DRY_RUN" != 1 ] && [ ! -s "$LOGIN_WP/wallpaper.jpg" ] && [ -f "$WALLPAPER" ]; then
  magick "$WALLPAPER[0]" -auto-orient -strip -resize '2560x1440>' -quality 90 "$LOGIN_WP/wallpaper.jpg" &&
    chown "$REAL_USER" "$LOGIN_WP/wallpaper.jpg"
fi
LCONF=/etc/plasmalogin.conf
run cp -a "$LCONF" "$BK/plasmalogin.conf" 2>/dev/null || true
run kwriteconfig6 --file "$LCONF" --group Greeter --key WallpaperPluginId org.kde.image
run kwriteconfig6 --file "$LCONF" --group Greeter --key ShowClock true
run kwriteconfig6 --file "$LCONF" --group Greeter --group Wallpaper --group org.kde.image --group General \
    --key Image "file://$LOGIN_WP/wallpaper.jpg"
info "$(L "login screen with the RedRog look and wallpaper" "inicio de sesión con el aspecto y el fondo de RedRog")"

# Login and lock screen clock as "9:10 PM", like the top bar (breeze-clock.sh
# explains how); rebuilt after every plasma-workspace update
if [ "$DRY_RUN" != 1 ]; then
  install -Dm755 "$REDROG_ROOT/modules/system/breeze-clock.sh" /usr/local/lib/redrog/breeze-clock.sh
  install -Dm644 "$REDROG_ROOT/modules/system/zz-redrog-clock.hook" /etc/pacman.d/hooks/zz-redrog-clock.hook
  /usr/local/lib/redrog/breeze-clock.sh
  # every user's session, the login screen's own user included
  mkdir -p /etc/environment.d
  echo "QML_IMPORT_PATH=/usr/local/share/redrog/qml" > /etc/environment.d/60-redrog-qml.conf
  mkdir -p /etc/systemd/user/plasma-login.service.d
  printf '[Service]\nEnvironment=QML_IMPORT_PATH=/usr/local/share/redrog/qml\n' \
    > /etc/systemd/user/plasma-login.service.d/redrog-clock.conf
fi
info "$(L "login and lock screen clock as 9:10 PM" "reloj de inicio de sesión y bloqueo como 9:10 PM")"

# ── 3. ROG Control Center translations ───────────────────────────────────────
# (only for the official package: the RedRog edition ships its translation,
# and a copy here would block installing or updating it)
if has rog-control-center && ! pacman -Q rog-control-center-redrog >/dev/null 2>&1; then
  step "$(L "ROG Control Center translations" "Traducciones de ROG Control Center")"
  for po in "$REDROG_ROOT"/i18n/rog-control-center/*.po; do
    lang=$(basename "$po" .po)
    run mkdir -p "/usr/share/locale/$lang/LC_MESSAGES"
    run msgfmt -o "/usr/share/locale/$lang/LC_MESSAGES/rog-control-center.mo" "$po"
    info "$lang"
  done
fi
# ── 4. Network and Bluetooth at full power ───────────────────────────────────
# No power saving on any link: Wi-Fi power save made pings to the router jump
# to 300-800 ms (it naps between beacons), Ethernet's EEE and runtime PM add
# wake-up delays, and Bluetooth autosuspend makes mice and headsets lag on
# wake. Plus BBR with fq, which gets more out of Wi-Fi and lossy links than
# CUBIC. Files in /etc, so updates never undo them.
step "$(L "Network and Bluetooth without power saving" "Red y Bluetooth sin ahorro de energía")"
if [ "$DRY_RUN" != 1 ]; then
  mkdir -p /etc/NetworkManager/conf.d /etc/modprobe.d /etc/udev/rules.d /etc/sysctl.d
  # every Wi-Fi connection (2 = off), unless one sets its own
  cat > /etc/NetworkManager/conf.d/90-redrog-no-powersave.conf <<'EOF'
# RedRog: no Wi-Fi power saving (modules/system)
[connection]
wifi.powersave=2
EOF
  # Intel Wi-Fi in its "active" power scheme, Bluetooth USB never suspended
  cat > /etc/modprobe.d/90-redrog-network.conf <<'EOF'
# RedRog: network and Bluetooth without power saving (modules/system)
options iwlmvm power_scheme=1
options iwlwifi power_save=0
options btusb enable_autosuspend=0
EOF
  cat > /etc/udev/rules.d/90-redrog-network-power.rules <<'EOF'
# RedRog: network and Bluetooth without power saving (modules/system)
# Wi-Fi (0x0280) and Ethernet (0x0200) controllers always powered
ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x028000", ATTR{power/control}="on"
ACTION=="add|change", SUBSYSTEM=="pci", ATTR{class}=="0x020000", ATTR{power/control}="on"
# Bluetooth adapters (USB class e0) never autosuspended
ACTION=="add|change", SUBSYSTEM=="usb", ATTR{bDeviceClass}=="e0", ATTR{power/control}="on"
# no Energy-Efficient Ethernet, no Wi-Fi power save on any interface
ACTION=="add", SUBSYSTEM=="net", KERNEL=="en*", RUN+="/usr/bin/ethtool --set-eee $name eee off"
ACTION=="add", SUBSYSTEM=="net", KERNEL=="wl*", RUN+="/usr/bin/iw dev $name set power_save off"
EOF
  # after CachyOS's 70-cachyos-settings.conf (fq_codel), so this one wins
  cat > /etc/sysctl.d/99-redrog-network.conf <<'EOF'
# RedRog: BBR congestion control with the fq scheduler it is designed for
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
# find the path MTU when a link drops large packets
net.ipv4.tcp_mtu_probing = 1
EOF
  # now, without a reboot
  sysctl -q --system
  udevadm control --reload
  udevadm trigger --subsystem-match=pci --attr-match=class=0x028000
  udevadm trigger --subsystem-match=pci --attr-match=class=0x020000
  udevadm trigger --subsystem-match=usb --attr-match=bDeviceClass=e0
  for i in /sys/class/net/en*; do [ -e "$i" ] && ethtool --set-eee "${i##*/}" eee off 2>/dev/null; done
  for i in /sys/class/net/wl*; do [ -e "$i" ] && iw dev "${i##*/}" set power_save off 2>/dev/null; done
  echo N > /sys/module/btusb/parameters/enable_autosuspend 2>/dev/null || true
  nmcli general reload conf 2>/dev/null || true
fi
info "$(L "no power saving on Wi-Fi, Ethernet and Bluetooth; BBR (Intel Wi-Fi scheme after a reboot)" \
          "sin ahorro de energía en Wi-Fi, Ethernet y Bluetooth; BBR (esquema de Wi-Fi Intel tras reiniciar)")"

# Firewall (ufw, on in CachyOS): Quick Share from Android phones needs its
# fixed port (45555, set by modules/apps) and mDNS to find the laptop
if has ufw && ufw status 2>/dev/null | grep -q "Status: active"; then
  run ufw allow 45555/tcp comment "Quick Share (RQuickShare-X)" >/dev/null
  run ufw allow 5353/udp comment "mDNS (Quick Share, impresoras)" >/dev/null
  info "$(L "firewall open for Quick Share (45555/tcp) and mDNS" "firewall abierto para Quick Share (45555/tcp) y mDNS")"
fi

# ── 4b. Lighter boot image ──────────────────────────────────────────────────
# Limine reads (through the slow firmware disk access) and verifies the whole
# boot image on every boot. chwd puts the NVIDIA driver in it (its modules and
# GSP firmware: the image grew to ~240 MB) and the "kms" hook the other GPU
# drivers with their firmware (nouveau, nova, i915, xe: over 100 MB). None is
# needed to boot: the splash draws on the kernel's generic framebuffer and the
# laptop's panel is driven by the Intel GPU. So the image carries no GPU driver
# (some 40-60 MB), and the NVIDIA modules load as soon as the system starts
# (modules-load.d, alongside everything else, holding nothing up), from the
# disk instead of through the firmware. The images are rebuilt (with their
# Limine hashes) when that changes anything.
MK=/etc/mkinitcpio.conf.d/90-redrog.conf
if [ -d /etc/mkinitcpio.conf.d ] && grep -qs "nvidia" /etc/mkinitcpio.conf.d/10-chwd.conf; then
  NEW='# RedRog (modules/system): no GPU driver in the boot image (the splash uses the
# generic framebuffer); NVIDIA loads at system start (modules-load.d)
HOOKS=(${HOOKS[@]/kms})
_redrog=(); for _m in "${MODULES[@]}"; do [[ $_m == nvidia* ]] || _redrog+=("$_m"); done
MODULES=("${_redrog[@]}"); unset _redrog _m'
  if [ "$DRY_RUN" = 1 ]; then info "[dry-run] $MK + /etc/modules-load.d/redrog-nvidia.conf + rebuild boot images"
  else
    printf '# RedRog (modules/system): the NVIDIA driver, as soon as the system starts\nnvidia\nnvidia_modeset\nnvidia_uvm\nnvidia_drm\n' \
      > /etc/modules-load.d/redrog-nvidia.conf
    if [ "$(cat "$MK" 2>/dev/null)" != "$NEW" ]; then
      printf '%s\n' "$NEW" > "$MK"
      if has limine-mkinitcpio; then limine-mkinitcpio >/dev/null 2>&1 || warn "limine-mkinitcpio"
      else mkinitcpio -P >/dev/null 2>&1 || warn "mkinitcpio -P"; fi
    fi
  fi
  info "$(L "light boot image (no GPU drivers); NVIDIA loads at system start" "imagen de arranque liviana (sin controladores de GPU); NVIDIA carga al iniciar el sistema")"
fi

# ── 4c. Boot splash ─────────────────────────────────────────────────────────
# The animated Arch logo after Limine, in the RedRog accent on absolute black
# (built from AUR plymouth-theme-arch-charge-big by plymouth-redrog.sh); the
# system stays CachyOS. Rebuilt on every run so it follows the accent color;
# the boot images are rebuilt with their Limine hashes when anything changes.
SPLASH=redrog-arch
if has plymouth-set-default-theme && [ -d /usr/share/plymouth/themes/arch-charge-big ]; then
  if [ "$DRY_RUN" = 1 ]; then info "[dry-run] plymouth $SPLASH"
  else
    # kept up to date after updates by a pacman hook (zz-redrog-plymouth.hook)
    install -Dm755 "$REDROG_ROOT/modules/system/plymouth-redrog.sh" /usr/local/lib/redrog/plymouth-redrog.sh
    cat > /usr/local/lib/redrog/plymouth-redrog-update <<EOU
#!/bin/sh
# RedRog (modules/system): run by zz-redrog-plymouth.hook
/usr/local/lib/redrog/plymouth-redrog.sh $BOOT_ACCENT || exit 0
[ "\$(plymouth-set-default-theme)" = $SPLASH ] || exit 0
if command -v limine-mkinitcpio >/dev/null; then limine-mkinitcpio >/dev/null 2>&1; else mkinitcpio -P >/dev/null 2>&1; fi
exit 0
EOU
    chmod 755 /usr/local/lib/redrog/plymouth-redrog-update
    install -Dm644 "$REDROG_ROOT/modules/system/zz-redrog-plymouth.hook" /etc/pacman.d/hooks/zz-redrog-plymouth.hook
    before=$(cat /usr/share/plymouth/themes/$SPLASH/*.png 2>/dev/null | md5sum)
    bash "$REDROG_ROOT/modules/system/plymouth-redrog.sh" "$BOOT_ACCENT"
    after=$(cat /usr/share/plymouth/themes/$SPLASH/*.png | md5sum)
    if [ "$(plymouth-set-default-theme)" != "$SPLASH" ] || [ "$before" != "$after" ]; then
      plymouth-set-default-theme "$SPLASH"
      if has limine-mkinitcpio; then limine-mkinitcpio >/dev/null 2>&1 || warn "limine-mkinitcpio"
      else mkinitcpio -P >/dev/null 2>&1 || warn "mkinitcpio -P"; fi
    fi
  fi
  info "$(L "boot splash: the Arch logo in RedRog red" "animación de arranque: el logo de Arch en rojo RedRog")"
fi

# ── 4f. Password dialog ─────────────────────────────────────────────────────
# PAM's messages in the dialog in the system language, and a gentler lock
# after wrong passwords (polkit/ explains both)
if [ "$DRY_RUN" = 1 ]; then info "[dry-run] polkit locale, faillock"
else
  install -Dm644 "$REDROG_ROOT/modules/system/polkit/locale.conf" /etc/systemd/system/polkit-agent-helper@.service.d/redrog-locale.conf
  systemctl daemon-reload
  if [ -f /etc/security/faillock.conf ] && ! grep -q "RedRog" /etc/security/faillock.conf; then
    cp -a /etc/security/faillock.conf "$BK/faillock.conf" 2>/dev/null || true
    cat "$REDROG_ROOT/modules/system/polkit/faillock.conf" >> /etc/security/faillock.conf
  fi
  faillock --user "${SUDO_USER:-$REAL_USER}" --reset 2>/dev/null || true
fi
info "$(L "password dialog in Spanish, gentler lock after wrong passwords" "diálogo de contraseña en español y bloqueo más suave tras contraseñas erróneas")"

# ── 5. ASUS profiles (the gaming mode) on this laptop model ──────────────────
# The gaming mode lives in asusd, the one daemon in charge of the platform
# profile: Performance on AC (CPU 80/95 W, GPU Dynamic Boost 15 W, its fan
# curve), Quiet on battery, switched with Fn+F5, the Armoury key or ROG
# Control Center. The captured configuration is only for the FX507ZC4, and it
# is installed once: after that asusd's files hold what the user changes, and
# a reinstall must not put the captured values back over them.
APPLY="$REDROG_ROOT/hosts/asus-tuf-f15/scripts/apply-asusd.sh"
SEEDED=/etc/asusd/.redrog-seeded
case "$(cat /sys/class/dmi/id/product_name 2>/dev/null)" in
  *FX507ZC*)
    if [ -x "$APPLY" ] && [ -d /etc/asusd ] && [ ! -e "$SEEDED" ]; then
      step "$(L "ASUS profiles (gaming mode)" "Perfiles de ASUS (modo gamer)")"
      run "$APPLY"
      run touch "$SEEDED"
    fi ;;
esac
# Any asusd machine: the profile's power limits applied at every start (Linux
# 7.3+ refused them while asusd started) and the profile picked by hand kept
# across restarts and charger changes (asusd-profile-keeper.sh explains both)
if [ -f /usr/lib/systemd/system/asusd.service ]; then
  step "$(L "ASUS power profile kept" "Perfil de energía de ASUS persistente")"
  run install -Dm755 "$REDROG_ROOT/modules/system/asusd-profile-keeper.sh" /usr/local/lib/redrog/asusd-profile-keeper
  run install -m644 "$REDROG_ROOT/modules/system/redrog-asusd-profile.service" /etc/systemd/system/
  run systemctl daemon-reload
  run systemctl enable redrog-asusd-profile.service >/dev/null 2>&1
  run systemctl restart redrog-asusd-profile.service
  info "$(L "power limits applied at every start; the chosen profile survives restarts" \
            "límites de potencia aplicados en cada arranque; el perfil elegido sobrevive a reinicios")"
fi

# ── 6. Background maintenance never slows the desktop ───────────────────────
# Timers that missed their slot run right after boot: plocate's updatedb took
# 7 min of CPU and 3 GB of memory while the user was working. Nice 19 alone
# still competes; with CPUWeight=idle these jobs only get CPU time nobody else
# wants, the idle I/O class only idle disk time, and MemoryHigh keeps them
# from pushing apps' memory out. Drop-ins, so package updates keep them.
step "$(L "Background maintenance at idle priority" "Mantenimiento de fondo con prioridad mínima")"
idle=0
for s in plocate-updatedb man-db shadow logrotate fstrim systemd-tmpfiles-clean \
         archlinux-keyring-wkd-sync cachyos-rate-mirrors snapper-cleanup snapper-timeline \
         btrfs-scrub@ pkgfile-update; do
  systemctl cat "$s.service" >/dev/null 2>&1 || continue
  if [ "$DRY_RUN" = 1 ]; then info "/etc/systemd/system/$s.service.d/90-redrog-idle.conf"; continue; fi
  mkdir -p "/etc/systemd/system/$s.service.d"
  cat > "/etc/systemd/system/$s.service.d/90-redrog-idle.conf" <<'EOF'
# RedRog: background maintenance at idle priority (modules/system)
[Service]
Nice=19
CPUWeight=idle
IOSchedulingClass=idle
IOWeight=1
MemoryHigh=1G
EOF
  idle=$((idle + 1))
done
run systemctl daemon-reload
info "$(L "$idle background jobs only use what the desktop leaves free" \
          "$idle tareas de fondo solo usan lo que el escritorio deja libre")"

# ── 7. AUR builds with the system's tools only ──────────────────────────────
# makepkg inherits the PATH of whoever runs paru: from an interactive fish
# shell that includes Homebrew, whose node, pnpm and python then build the
# package (Pillow and dbus once broke that way), and from "Actualizaciones"
# it does not, so a build could work in one and fail in the other (pnpm 12
# runs postinstall scripts with a node that only Homebrew had). makepkg
# sources this drop-in, so every build sees the same system PATH.
step "$(L "AUR builds with the system's tools" "Compilaciones del AUR con las herramientas del sistema")"
if [ "$DRY_RUN" = 1 ]; then info /etc/makepkg.conf.d/90-redrog-path.conf; else
  cat > /etc/makepkg.conf.d/90-redrog-path.conf <<'EOF'
# RedRog (modules/system): builds never use Homebrew's tools (node, pnpm,
# python, pkg-config...), only the system's, whatever shell started them
PATH=$(printf '%s' "$PATH" | tr ':' '\n' | grep -v -e '^/home/linuxbrew/' -e '/\.linuxbrew/' | paste -sd: -)
unset HOMEBREW_PREFIX HOMEBREW_CELLAR HOMEBREW_REPOSITORY
case "${PKG_CONFIG_PATH:-}" in *linuxbrew*) unset PKG_CONFIG_PATH ;; esac
EOF
fi

# ── 8. Groups for GameMode and adb ──────────────────────────────────────────
# Feral GameMode's polkit rule lets the "gamemode" group switch the CPU to
# the performance governor while a game runs (without it gamemoded -t
# fails); android-udev gives the "adbusers" group the phones on USB
if [ -n "${SUDO_USER:-}" ]; then
  for g in gamemode adbusers; do
    getent group "$g" >/dev/null || continue
    run usermod -aG "$g" "$SUDO_USER"
    info "$(L "$SUDO_USER in the $g group" "$SUDO_USER en el grupo $g")"
  done
fi

# ── 9. Virtual cameras ──────────────────────────────────────────────────────
# v4l2loopback at boot with two devices: /dev/video20 "scrcpy" (the phone as
# a webcam: scrcpy --v4l2-sink=/dev/video20) and /dev/video21 for OBS's
# virtual camera; exclusive_caps so browsers and video-call apps list them
if modinfo v4l2loopback >/dev/null 2>&1; then
  if [ "$DRY_RUN" = 1 ]; then info /etc/modprobe.d/redrog-v4l2loopback.conf; else
    printf '%s\n' "# RedRog (modules/system): virtual cameras for scrcpy (--v4l2-sink=/dev/video20)" \
      "# and OBS's virtual camera" v4l2loopback > /etc/modules-load.d/redrog-v4l2loopback.conf
    printf '%s\n' "# RedRog (modules/system): /dev/video20 for scrcpy, /dev/video21 for OBS;" \
      "# exclusive_caps so browsers and video-call apps list them as cameras" \
      'options v4l2loopback devices=2 video_nr=20,21 card_label="scrcpy,OBS Virtual Camera" exclusive_caps=1,1' \
      > /etc/modprobe.d/redrog-v4l2loopback.conf
    lsmod | grep -q '^v4l2loopback' || modprobe v4l2loopback 2>/dev/null || true
  fi
  info "$(L "virtual cameras: /dev/video20 (scrcpy), /dev/video21 (OBS)" "cámaras virtuales: /dev/video20 (scrcpy), /dev/video21 (OBS)")"
fi


# ── 10. Keyboard layouts ────────────────────────────────────────────────────
# The system keymap (systemd-localed) holds every layout of KEYBOARD_LAYOUTS:
# KWin takes its layouts from it, as do the login screen and the consoles;
# the user's own selection, labels and automatic switching are in
# modules/keyboard
if [ ${#KEYBOARD_LAYOUTS[@]} -gt 0 ] && command -v localectl >/dev/null; then
  kl=() kv=()
  for entry in "${KEYBOARD_LAYOUTS[@]}"; do
    spec=${entry%%|*}; kl+=("${spec%%(*}")
    v=""; [[ $spec == *"("* ]] && { v=${spec#*(}; v=${v%)}; }; kv+=("$v")
  done
  layouts=$(IFS=,; echo "${kl[*]}"); variants=$(IFS=,; echo "${kv[*]}")
  run localectl set-x11-keymap "$layouts" pc105 "$variants"
  info "$(L "system keyboard layouts:" "distribuciones de teclado del sistema:") $layouts"

  # The login screen follows the keyboard in use too: with one of
  # KEYBOARD_AUTO_DEVICES connected, KEYBOARD_AUTO_LAYOUT (also when it is
  # connected or disconnected while the login screen is up). A user service
  # that only runs in the login screen's own session (plasmalogin), started
  # with it; the layouts' order is the system's, untouched
  auto=${KEYBOARD_AUTO_LAYOUT:-us}; auto=${auto%%(*}; idx=""
  for i in "${!kl[@]}"; do [ "${kl[$i]}" = "$auto" ] && { idx=$i; break; }; done
  if [ ${#KEYBOARD_AUTO_DEVICES[@]} -gt 0 ] && [ -n "$idx" ]; then
    if [ "$DRY_RUN" != 1 ]; then
      install -d /etc/redrog
      { echo "# RedRog (modules/system): the login screen's layout follows these keyboards"
        printf "AUTO_DEVICES='%s'\n" "$(printf '%s\n' "${KEYBOARD_AUTO_DEVICES[@]}" | sed '/^$/d')"
        echo "AUTO_INDEX=$idx"
        echo "DEFAULT_INDEX=0"; } > /etc/redrog/login-keyboard.conf
      install -Dm755 "$REDROG_ROOT/modules/system/redrog-login-keyboard" /usr/local/lib/redrog/redrog-login-keyboard
      cat > /etc/systemd/user/redrog-login-keyboard.service <<'UNIT'
[Unit]
Description=RedRog: the login screen's keyboard layout follows the keyboard in use
ConditionUser=plasmalogin
After=plasma-login-kwin_wayland.service
PartOf=plasma-login.service

[Service]
ExecStart=/usr/local/lib/redrog/redrog-login-keyboard

[Install]
WantedBy=plasma-login.service
UNIT
      systemctl --global enable redrog-login-keyboard.service >/dev/null 2>&1
    fi
    info "$(L "login screen layout follows the keyboard:" "el inicio de sesión sigue al teclado:") ${KEYBOARD_AUTO_DEVICES[*]} → $auto"
  fi
fi

info "$(L "backups in" "copias en") $BK"
