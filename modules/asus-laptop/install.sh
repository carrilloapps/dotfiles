#!/usr/bin/env bash
# ASUS ROG/TUF laptop extras, each applied only when it fits the machine:
#
# - Hybrid graphics (an Intel or AMD iGPU plus an NVIDIA card): an Xwayland
#   wrapper in ~/.local/bin that loads only the iGPU's (Mesa) EGL driver.
#   Without it Xwayland opens the NVIDIA card at startup and keeps it awake
#   for the whole session; with it the card sleeps until a game or an app asks
#   for it. KWin still drives the outputs wired to the NVIDIA card (HDMI). In
#   NVIDIA-only mode (MUX) there is no iGPU and nothing is restricted.
# - With ROG Control Center: the Armoury Crate key opens it.
# describe: ASUS laptop extras: NVIDIA sleeps until needed, Armoury key | extras ASUS: la NVIDIA duerme hasta que se necesite, tecla Armoury

APPS="$DATA_HOME/applications"
BIN="$REAL_HOME/.local/bin"
run mkdir -p "$APPS" "$BIN"

# PCI address of the NVIDIA card (vendor 0x10de, display class), if any
nvidia=""
igpu=0
for d in /sys/bus/pci/devices/*; do
  case "$(cat "$d/class" 2>/dev/null)" in 0x03*) ;; *) continue ;; esac
  case "$(cat "$d/vendor")" in
    0x10de) nvidia="${d##*/}" ;;
    0x8086|0x1002) igpu=1 ;;
  esac
done

if [ -n "$nvidia" ] && [ "$igpu" = 1 ]; then
  if [ "$DRY_RUN" = 1 ]; then
    info "write $BIN/Xwayland"
  else
    cat > "$BIN/Xwayland" <<'EOF'
#!/bin/sh
# RedRog (modules/asus-laptop): on hybrid graphics Xwayland loads only the
# integrated GPU's (Mesa) EGL driver, so the NVIDIA card can sleep until a
# game or app asks for it. Only when the integrated GPU drives the built-in
# screen: in MUX / dGPU mode the NVIDIA card does, Mesa EGL fails there and
# every X11 app (Steam, games, Resolve) fell back to llvmpipe, drawn by the
# CPU. KWin finds Xwayland through PATH (~/.local/bin first).
for c in /sys/class/drm/card*-eDP-*; do
    [ "$(cat "$c/status" 2>/dev/null)" = connected ] || continue
    case "$(basename "$(readlink -f "$c/device/device/driver")")" in
        i915|xe|amdgpu) export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json ;;
    esac
    break
done
exec /usr/bin/Xwayland "$@"
EOF
    chmod 755 "$BIN/Xwayland"
  fi
  info "$(L "hybrid graphics: the NVIDIA GPU sleeps until something needs it (after logging in again)" \
            "gráficos híbridos: la NVIDIA duerme hasta que algo la necesite (al volver a iniciar sesión)")"
fi

# Armoury Crate key -> ROG Control Center
if has rog-control-center; then
  if [ "$DRY_RUN" != 1 ]; then
    cat > "$APPS/redrog-rog-control-center.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Open ROG Control Center
Name[es]=Abrir ROG Control Center
Comment=Opens ROG Control Center with the Armoury Crate key
Comment[es]=Abre ROG Control Center con la tecla Armoury Crate
Exec=rog-control-center
Icon=org.opengamingcollective.rog-control-center
NoDisplay=true
X-KDE-GlobalAccel-CommandShortcut=true
EOF
  fi
  kw --file kglobalshortcutsrc --group services --group redrog-rog-control-center.desktop --key _launch "Launch (3)	Launch (5)"
  run python3 -I "$REDROG_ROOT/lib/set-shortcut.py" redrog-rog-control-center.desktop _launch Launch3 Launch5 2>/dev/null || true
  info "$(L "Armoury Crate key opens ROG Control Center" "la tecla Armoury Crate abre ROG Control Center")"
fi
run kbuildsycoca6 >/dev/null 2>&1 || true

# WebKitGTK apps (Tauri apps such as the ArtCraft launcher and its Craft apps)
# crash at start on Wayland when the NVIDIA GPU draws the screen ("Error 71
# (Protocol error)", WebKit's DMA-BUF renderer); its fallback renderer works.
# Only WebKitGTK reads this variable.
if lspci -d 10de: 2>/dev/null | grep -qiE "VGA|3D"; then
  run mkdir -p "$CONFIG_HOME/environment.d"
  [ "$DRY_RUN" = 1 ] || printf '%s\n' "# RedRog (modules/asus-laptop): WebKitGTK apps on Wayland with NVIDIA" \
    "WEBKIT_DISABLE_DMABUF_RENDERER=1" > "$CONFIG_HOME/environment.d/60-redrog-webkit.conf"
  info "$(L "WebKitGTK apps (Tauri) start on Wayland with NVIDIA" "las apps WebKitGTK (Tauri) arrancan en Wayland con NVIDIA")"
fi
