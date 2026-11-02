#!/usr/bin/env bash
# OBS Studio in RedRog: the RedRog theme (Yami in the RedRog palette, rounded
# corners) and output settings that use this machine's hardware: NVIDIA
# NVENC when present (H.264 for streaming, HEVC for recordings), otherwise
# Intel Quick Sync, and Hybrid MP4 recordings (playable even if OBS or the
# machine stops mid-recording) in ~/Vídeos/OBS. Only applied while OBS is
# closed (it writes its settings when it quits); a profile the user has
# already set up (non-default encoder) is left alone.
# describe: OBS Studio theme and hardware recording | tema de OBS Studio y grabación por hardware

if ! has obs; then
  info "$(L "OBS Studio is not installed: skipped" "OBS Studio no está instalado: se omite")"
  return 0
fi
OBS="$CONFIG_HOME/obs-studio"
run mkdir -p "$OBS/themes"
run install -m 644 "$REDROG_ROOT/modules/obs/RedRog.ovt" "$OBS/themes/RedRog.ovt"
# and "RedRog Light": on Yami's light base, with a warm light ramp of grays
# that mirrors the dark one (window, then the lighter fields and lists on it)
if [ "$DRY_RUN" != 1 ]; then
  read -r l_surface l_bg l_hi < <(REDROG_VARIANT=light HOME="$REAL_HOME" bash -c \
    'source "$REDROG_ROOT/lib/palette.sh"; echo "$SURFACE $BG $SURFACE_HI"')
  sed -e "s/name: 'RedRog';/name: 'RedRog Light';/; s/id: 'com.redrog.obs';/id: 'com.redrog.obs.light';/" \
      -e "s/extends: 'com.obsproject.Yami';/extends: 'com.obsproject.Yami.Light';/" \
      -e "s/dark: 'true';/dark: 'false';/" \
      -e "s/--grey1: #5a5a58;/--grey1: #8a857e;/; s/--grey2: #4a4a48;/--grey2: #ffffff;/" \
      -e "s/--grey3: #3a3a39;/--grey3: #fdfcfa;/; s/--grey4: #313131;/--grey4: #f6f4f0;/" \
      -e "s/--grey5: #2a2a29;/--grey5: #f3f1ec;/; s/--grey6: #252524;/--grey6: #$l_surface;/" \
      -e "s/--grey7: #1c1c1c;/--grey7: #$l_bg;/; s/--grey8: #141414;/--grey8: #$l_hi;/" \
      "$REDROG_ROOT/modules/obs/RedRog.ovt" > "$OBS/themes/RedRog-Light.ovt"
fi
if pgrep -x obs >/dev/null; then
  warn "$(L "close OBS and run: ./install.sh --only obs" "cierra OBS y ejecuta: ./install.sh --only obs")"
  return 0
fi
[ -f "$OBS/user.ini" ] || { [ "$DRY_RUN" = 1 ] || : > "$OBS/user.ini"; }

# Plugins that cannot load are switched off in OBS's plugin manager (not
# deleted: the package would put them back), so OBS does not warn at every
# start. AJA (professional SDI capture cards) is built against a libajantv2
# older than the one in the repositories.
if [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$OBS/plugin_manager"
  python3 -I - "$OBS/plugin_manager/modules.json" <<'PY'
import json, os, sys
path = sys.argv[1]
mods = json.load(open(path)) if os.path.exists(path) else []
off = []
for so in ("aja", "aja-output-ui"):
    lib = f"/usr/lib/obs-plugins/{so}.so"
    if not os.path.exists(lib):
        continue
    # the plugin is broken when one of its libraries is missing
    if os.popen(f"ldd {lib} 2>/dev/null").read().find("not found") < 0:
        continue
    entry = next((m for m in mods if m.get("module_name") == so), None)
    if entry is None:
        entry = {"display_name": "", "enabled": True, "encoders": [], "id": "", "module_name": so,
                 "outputs": [], "services": [], "sources": [], "version": ""}
        mods.append(entry)
    if entry["enabled"]:
        entry["enabled"] = False
        off.append(so)
json.dump(mods, open(path, "w"), indent=4)
if off:
    print("plugins de OBS desactivados (no pueden cargar):", ", ".join(off))
PY
fi
kw --file "$OBS/user.ini" --group Appearance --key Theme "com.redrog.obs$([ "$THEME_VARIANT" = light ] && echo .light)"

# Hardware encoders this machine really has (the same probes OBS needs)
if nvidia-smi -L >/dev/null 2>&1; then
  stream_enc=nvenc; rec_enc=nvenc_hevc
elif [ -e /usr/lib/obs-plugins/obs-qsv11.so ] && pacman -Q vpl-gpu-rt >/dev/null 2>&1; then
  stream_enc=qsv; rec_enc=qsv
else
  stream_enc=x264; rec_enc=x264
fi
dir=$(kreadconfig6 --file "$OBS/user.ini" --group Basic --key ProfileDir 2>/dev/null)
[ -n "$dir" ] || dir=Sin_Título
P="$OBS/basic/profiles/$dir/basic.ini"
if [ -f "$P" ]; then
  current=$(kreadconfig6 --file "$P" --group SimpleOutput --key RecEncoder 2>/dev/null)
  if [ -z "$current" ] || [ "$current" = x264 ]; then
    rec_dir="$(xdg-user-dir VIDEOS 2>/dev/null || echo "$REAL_HOME/Videos")/OBS"
    run mkdir -p "$rec_dir"
    S=(--file "$P" --group SimpleOutput)
    kw "${S[@]}" --key StreamEncoder "$stream_enc"
    kw "${S[@]}" --key RecEncoder "$rec_enc"
    kw "${S[@]}" --key RecQuality HQ
    kw "${S[@]}" --key RecFormat2 hybrid_mp4
    kw "${S[@]}" --key FilePath "$rec_dir"
    kw "${S[@]}" --key ABitrate 320
    info "$(L "OBS records with $rec_enc (Hybrid MP4) in $rec_dir" "OBS graba con $rec_enc (MP4 híbrido) en $rec_dir")"
  else
    info "$(L "OBS profile already set up ($current): kept" "perfil de OBS ya configurado ($current): se conserva")"
  fi
fi
info "$(L "OBS uses the RedRog theme" "OBS usa el tema RedRog")"
