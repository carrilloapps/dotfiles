#!/usr/bin/env bash
# Mantenimiento (redrog-mantenimiento): the terminal tool to free space
# (package and AUR caches, thumbnails, shaders, journal, crash dumps, orphans,
# trash, ~/.cache folders, old snapshots; Claude Code and Antigravity sessions
# and caches; Steam and games; developer caches), update every tool, and
# check performance (ASUS power profile, memory, heaviest processes, failed
# services, temperatures, boot), in the menu as "Mantenimiento" (in kitty).
# describe: Maintenance tool: caches, space, performance | Herramienta de mantenimiento: cachés, espacio, rendimiento

has gum || warn "$(L "gum is missing: sudo pacman -S gum" "falta gum: sudo pacman -S gum")"
# in the active variant's colors (both kept for the light/dark switch)
repaint_variants "$REDROG_ROOT/modules/maintenance/redrog-mantenimiento" "$REAL_HOME/.local/bin/redrog-mantenimiento"
run mkdir -p "$DATA_HOME/applications"
[ "$DRY_RUN" = 1 ] || cat > "$DATA_HOME/applications/redrog-mantenimiento.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Maintenance
Name[es]=Mantenimiento
GenericName=Caches, space and performance
GenericName[es]=Cachés, espacio y rendimiento
Comment=Free disk space and check performance
Comment[es]=Libera espacio en disco y revisa el rendimiento
Exec=kitty --class redrog-mantenimiento --title Mantenimiento $REAL_HOME/.local/bin/redrog-mantenimiento
Icon=appimagekit-stacer
Terminal=false
Categories=System;Utility;
Keywords=cache;clean;disk;space;performance;caché;limpiar;espacio;rendimiento;
DESKTOP
run kbuildsycoca6 >/dev/null 2>&1 || true
info "$(L "Maintenance tool in the menu" "herramienta de Mantenimiento en el menú")"
