#!/usr/bin/env bash
# Steam on this hybrid (Intel + NVIDIA) laptop:
#  - every game runs on the NVIDIA GPU: a Steam launcher gives each
#    installed game without launch options of its own
#    "__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only
#    __GLX_VENDOR_LIBRARY_NAME=nvidia %command%" (Steam's own window stays
#    on the Intel GPU: no heat or battery drain when idle). The gaming mode
#    itself is asusd's Performance profile (on AC), not game-performance,
#    whose power-profiles-daemon set the profile back to Balanced when a game
#    closed;
#  - Mesa's anti-lag layer off (made Need for Speed Unbound hang) and NVAPI
#    on (DLSS, Reflex) for every game;
#  - the NVIDIA shader cache raised from 1 GB to 12 GB and never trimmed, so
#    big games stop recompiling shaders on every start;
#  - Steam processes shaders with 14 of the 16 threads and downloads over
#    HTTP/1.1, faster on Linux.
# describe: Steam tuned for gaming on this laptop | Steam ajustado para jugar en este portátil

if ! has steam; then
  info "$(L "Steam is not installed: skipped" "Steam no está instalado: se omite")"
  return 0
fi
STEAM_DIR="$REAL_HOME/.local/share/Steam"
LIBDIR="$REAL_HOME/.local/lib/redrog/steam"
run mkdir -p "$LIBDIR" "$CONFIG_HOME/environment.d" "$DATA_HOME/applications"

if [ "$DRY_RUN" != 1 ]; then
  # Whole session (read at login; the launcher below also sets them)
  cat > "$CONFIG_HOME/environment.d/60-redrog-gaming.conf" <<'EOF2'
# RedRog (modules/steam): gaming on the NVIDIA GPU
DISABLE_LAYER_MESA_ANTI_LAG=1
PROTON_ENABLE_NVAPI=1
__GL_SHADER_DISK_CACHE_SIZE=12884901888
__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
EOF2
  # Shader processing threads: all but two
  threads=$(( $(nproc) > 4 ? $(nproc) - 2 : 2 ))
  [ -d "$STEAM_DIR" ] && cat > "$STEAM_DIR/steam_dev.cfg" <<EOF2
unShaderBackgroundProcessingThreads $threads
@nClientDownloadEnableHTTP2PlatformLinux 0
EOF2
  install -m 644 "$REDROG_ROOT/modules/steam/launch-options.py" "$LIBDIR/launch-options.py"
  cat > "$LIBDIR/redrog-steam" <<'EOF2'
#!/bin/bash
# RedRog: starts Steam after giving new games the RedRog launch options
# (only while Steam is closed: it writes its settings when it quits)
lib="$HOME/.local/lib/redrog/steam"
pgrep -x steam >/dev/null || python3 -I "$lib/launch-options.py" >/dev/null 2>&1
export DISABLE_LAYER_MESA_ANTI_LAG=1 PROTON_ENABLE_NVAPI=1
export __GL_SHADER_DISK_CACHE_SIZE=12884901888 __GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1
exec /usr/bin/steam "$@"
EOF2
  chmod +x "$LIBDIR/redrog-steam"
  # Steam's menu entries (and its autostart) through the launcher
  sed "s|^Exec=/usr/bin/steam|Exec=$LIBDIR/redrog-steam|" /usr/share/applications/steam.desktop \
    > "$DATA_HOME/applications/steam.desktop"
  [ -f "$CONFIG_HOME/autostart/steam.desktop" ] && \
    sed -i "s|^Exec=/usr/bin/steam|Exec=$LIBDIR/redrog-steam|" "$CONFIG_HOME/autostart/steam.desktop"
  if pgrep -x steam >/dev/null; then
    warn "$(L "close Steam and open it again for the launch options" "cierra Steam y ábrelo de nuevo para las opciones de lanzamiento")"
  else
    python3 -I "$LIBDIR/launch-options.py"
  fi
fi
info "$(L "Steam tuned: NVIDIA for games, 12 GB shader cache, $threads shader threads" \
          "Steam ajustado: NVIDIA para los juegos, caché de shaders de 12 GB, $threads hilos para shaders")"
