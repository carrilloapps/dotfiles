#!/usr/bin/env bash
# Fuller sound from small laptop speakers with EasyEffects: a psychoacoustic
# bass enhancer (harmonics make the bass the drivers cannot play audible), an
# equalizer with more body in the low mids and a softer tinny edge, loudness
# compensation, a gentle compressor for level and a limiter that only catches
# the rare peak.
#
# The "RedRog Laptop Speakers" preset belongs to the built-in speakers and is
# always loaded there (EasyEffects' autoload). Every other output and every
# microphone keeps the preset last used on it (redrog-audio-memory): moving
# the sound to the speakers and back to a headset brings back what it had,
# bass, streaming or none. A device met for the first time gets the preset
# AUDIO_AUTOLOAD / AUDIO_INPUT_AUTOLOAD name for it ("RedRog Laptop Mic" on
# the built-in microphone), else "RedRog Neutral" / "RedRog Neutral Mic" (no
# effects). The speaker preset is installed read-only so a stray save cannot
# change it, and "Restore speaker sound" in the menu puts it back as shipped.
# Personal presets in config/audio/ and config/audio/input/ are installed too.
# describe: speaker, headphone and microphone sound (EasyEffects) | sonido de parlantes, auriculares y micrófono (EasyEffects)

PRESET="RedRog Laptop Speakers"
NEUTRAL="RedRog Neutral"
if ! has easyeffects; then
  warn "$(L "EasyEffects is not installed: skipped (./install.sh --packages)" "EasyEffects no está instalado: se omite (./install.sh --packages)")"
  return 0
fi

# EasyEffects 8 keeps its data in ~/.local/share/easyeffects (7 used ~/.config)
EE="$DATA_HOME/easyeffects"
[ -d "$CONFIG_HOME/easyeffects/output" ] && [ ! -d "$EE/output" ] && EE="$CONFIG_HOME/easyeffects"
RC="$CONFIG_HOME/easyeffects/db/easyeffectsrc"
LIB="$REAL_HOME/.local/lib/redrog/audio"
run mkdir -p "$EE/output" "$EE/autoload/output" "$LIB/presets" "$LIB/autoload"

# EasyEffects keeps its settings in memory and writes them back: stop it while
# they change, start it again at the end
running=0
pgrep -x easyeffects >/dev/null && running=1
[ "$running" = 1 ] && { run easyeffects -q >/dev/null 2>&1 || true; sleep 2; }

# Presets: a pristine copy in ~/.local/lib/redrog/audio for the restore
# launcher, and the working copies (read-only) where EasyEffects reads them
for p in "$PRESET" "$NEUTRAL"; do
  run install -m 644 "$REDROG_ROOT/modules/audio/$p.json" "$LIB/presets/$p.json"
  run install -m 444 "$REDROG_ROOT/modules/audio/$p.json" "$EE/output/$p.json"
done

# Microphone. PipeWire's stock mixer path raises the internal mic's hardware
# gain (capture +30 dB and boost +30 dB) as the volume goes up, so 100 %
# clipped. A user copy of that path (PipeWire reads ~/.config first, so
# updates keep it) fixes the hardware gain (capture 0 dB, boost +10 dB) and
# leaves the volume digital: 100 % is clean. The built-in microphone then goes
# through "RedRog Laptop Mic": a 100 Hz high-pass (fans, rumble), RNNoise,
# Autogain to a steady speech level and a limiter. Every other microphone,
# unless it has a preset of its own (below), gets "RedRog Neutral Mic"
MIC="RedRog Laptop Mic"
MIC_NEUTRAL="RedRog Neutral Mic"
run mkdir -p "$CONFIG_HOME/alsa-card-profile/mixer/paths" "$EE/input" "$EE/autoload/input"
run install -m 644 "$REDROG_ROOT/modules/audio/mixer/analog-input-internal-mic.conf" \
    "$CONFIG_HOME/alsa-card-profile/mixer/paths/analog-input-internal-mic.conf"
# the single preset of earlier versions, for every microphone
run rm -f "$EE/input/RedRog Microphone.json" "$EE/output/RedRog Microphone.json" "$LIB/presets/RedRog Microphone.json"
# microphone presets apart from the output ones, in the pristine copy too
run mkdir -p "$LIB/presets/input"
for p in "$MIC" "$MIC_NEUTRAL"; do
  run rm -f "$LIB/presets/$p.json" "$EE/output/$p.json"
  run install -m 644 "$REDROG_ROOT/modules/audio/$p.json" "$LIB/presets/input/$p.json"
  run install -m 444 "$REDROG_ROOT/modules/audio/$p.json" "$EE/input/$p.json"
done
# microphones keep their last preset (redrog-audio-memory), not a fixed one
kw --file "$RC" --group Window --key inputAutoloadingUsesFallback false
kw --file "$RC" --group EffectsPipelines --key processAllInputs true
run rm -f "$EE"/autoload/input/*.json
# Volumes are the user's: WirePlumber keeps whatever is set by hand. Only the
# first time is the internal mic set to 100 % (clean with the path above)
MIC_STATE="$REAL_HOME/.local/state/redrog/mic-volume-set"
if [ "$DRY_RUN" != 1 ] && [ ! -e "$MIC_STATE" ]; then
  src=$(pactl list short sources 2>/dev/null | awk '/alsa_input\.pci.*analog/ {print $2; exit}')
  if [ -n "$src" ]; then
    systemctl --user restart wireplumber >/dev/null 2>&1; sleep 3   # load the new path
    pactl set-source-volume "$src" 100% && { mkdir -p "$(dirname "$MIC_STATE")"; touch "$MIC_STATE"; }
  fi
fi
info "$(L "microphone: clean gain, noise suppression and steady level ($MIC)" \
          "micrófono: ganancia limpia, reducción de ruido y nivel estable ($MIC)")"

# Autoload on the built-in speakers. EasyEffects matches the output by device
# and route, and the route is the port's description as PipeWire reports it
# ("Speakers", "Altavoces"...), not the port's name
if [ "$DRY_RUN" != 1 ]; then
  # only the speakers have a fixed preset: other outputs keep their last one
  rm -f "$EE"/autoload/output/*.json "$LIB"/autoload/*.json
  pactl -f json list sinks 2>/dev/null | python3 -Ic '
import json, sys
for s in json.load(sys.stdin):
    for p in s.get("ports", []):
        if p.get("type") == "Speaker" or p["name"].endswith("-speaker"):
            route = p.get("description") or p["name"]
            desc = s.get("properties", {}).get("device.description") or s.get("description") or s["name"]
            desc = s["name"] if desc in ("", "(null)") else desc
            print(s["name"], route, desc, sep="\t")
' | while IFS=$'\t' read -r sink route desc; do
    f="$sink:$route.json"
    python3 -Ic 'import json, sys; print(json.dumps({"device": sys.argv[1], "device-description": sys.argv[2],
                 "device-profile": sys.argv[3], "preset-name": sys.argv[4]}, indent=4))' \
      "$sink" "$desc" "$route" "$PRESET" > "$LIB/autoload/$f"
    install -m 444 "$LIB/autoload/$f" "$EE/autoload/output/$f"
    info "$(L "speaker preset loads on" "el preset de parlantes se carga en") $desc ($route)"
  done
fi

# Personal presets: every EasyEffects preset in config/audio/ (outputs) and
# config/audio/input/ (microphones) is installed to use whenever you want
for f in "$REDROG_ROOT"/config/audio/*.json; do
  [ -f "$f" ] || continue
  # shown as "RedRog <name>", like the presets RedRog ships
  name=$(basename "$f" .json); name="RedRog ${name#RedRog }"
  run rm -f "$EE/output/${name#RedRog }.json"   # unprefixed copy from older versions
  run install -m 644 "$f" "$EE/output/$name.json"
  info "$(L "personal preset" "preset personal"): $name"
done
for f in "$REDROG_ROOT"/config/audio/input/*.json; do
  [ -f "$f" ] || continue
  name=$(basename "$f" .json); name="RedRog ${name#RedRog }"
  run install -m 644 "$f" "$EE/input/$name.json"
  info "$(L "personal microphone preset" "preset personal de micrófono"): $name"
done

# Each device keeps its last preset (redrog-audio-memory). Its rules: the
# speakers' fixed preset, the preset a device gets the first time it is used
# (AUDIO_AUTOLOAD / AUDIO_INPUT_AUTOLOAD: "part of the device name|preset",
# and the built-in microphone's), and the neutral ones for the rest
kw --file "$RC" --group Window --key outputAutoloadingUsesFallback false
if [ "$DRY_RUN" != 1 ]; then
  # the built-in microphone by its port (any language), not the headset jack's
  internal_mics=$(pactl -f json list sources 2>/dev/null | python3 -Ic '
import json, sys
for s in json.load(sys.stdin):
    if s["name"].startswith("alsa_input"):
        for p in s.get("ports", []):
            if p["name"].endswith("internal-mic"):
                print(s["name"] + ":" + (p.get("description") or p["name"]))
')
  rules=()
  while IFS= read -r key; do [ -n "$key" ] && rules+=("input=$key|$MIC"); done <<< "$internal_mics"
  python3 -I - "$LIB/defaults.json" "$PRESET" "$NEUTRAL" "$MIC_NEUTRAL" "$EE/autoload/output" \
      "${rules[@]}" "${AUDIO_INPUT_AUTOLOAD[@]/#/input=}" "${AUDIO_AUTOLOAD[@]/#/output=}" <<'PY'
import glob, json, os, sys
dest, speakers, neutral, mic_neutral, autoload, *rules = sys.argv[1:]
forced = {}
for f in glob.glob(os.path.join(autoload, "*.json")):
    a = json.load(open(f))
    forced[f"{a['device']}:{a['device-profile']}"] = a["preset-name"]
first = {"output": [], "input": []}
for rule in rules:
    kind, _, rule = rule.partition("=")
    match, _, preset = rule.partition("|")
    if match and preset:
        first[kind].append({"match": match, "preset": "RedRog " + preset.removeprefix("RedRog ")})
json.dump({"forced": {"output": forced}, "first": first,
           "neutral": {"output": neutral, "input": mic_neutral}}, open(dest, "w"), indent=2, ensure_ascii=False)
PY
fi
run install -m 755 "$REDROG_ROOT/modules/audio/redrog-audio-memory" "$LIB/redrog-audio-memory"
run mkdir -p "$CONFIG_HOME/systemd/user"
if [ "$DRY_RUN" != 1 ]; then
  cat > "$CONFIG_HOME/systemd/user/redrog-audio-memory.service" <<EOF2
[Unit]
Description=EasyEffects remembers the preset of each device (RedRog)
After=pipewire.service wireplumber.service
PartOf=graphical-session.target

[Service]
ExecStart=$LIB/redrog-audio-memory
Restart=on-failure
RestartSec=5
Nice=10

[Install]
WantedBy=graphical-session.target
EOF2
fi
run systemctl --user daemon-reload
run systemctl --user enable redrog-audio-memory.service >/dev/null 2>&1 || true
info "$(L "every other device keeps its last preset (new ones:" "cada otro dispositivo conserva su último preset (los nuevos:") $NEUTRAL / $MIC_NEUTRAL)"

# Resampling at a higher quality: with EasyEffects always in the chain the
# graph runs at 48 kHz, so music mastered at 44.1 kHz (most streaming,
# Spotify) is resampled, and this keeps it transparent. The card's other
# rates (44.1, 96 kHz) are allowed too, for when no effects run.
# The card profile stays "Analog Stereo Duplex" (speakers/headphones and the
# microphone, with automatic jack switching); "Pro Audio" drops the volume
# controls and jack detection, it is for music production software.
run mkdir -p "$CONFIG_HOME/pipewire/pipewire.conf.d" "$CONFIG_HOME/pipewire/client.conf.d" \
             "$CONFIG_HOME/pipewire/pipewire-pulse.conf.d"
if [ "$DRY_RUN" != 1 ]; then
  cat > "$CONFIG_HOME/pipewire/pipewire.conf.d/90-redrog-audio.conf" <<'EOF2'
# RedRog (modules/audio): the card's native rates, no needless resampling
context.properties = {
    default.clock.rate          = 48000
    default.clock.allowed-rates = [ 44100 48000 96000 ]
}
EOF2
  for d in client pipewire-pulse; do
    cat > "$CONFIG_HOME/pipewire/$d.conf.d/90-redrog-resample.conf" <<'EOF2'
# RedRog (modules/audio): higher resampling quality when it is needed
stream.properties = {
    resample.quality = 10
}
EOF2
  done
fi
info "$(L "PipeWire with high-quality resampling" "PipeWire con remuestreo de alta calidad")"

# Spectrum in the RedRog look, the way macOS draws audio: one smooth area in
# the accent red, a translucent fill over the window's glass (no plot box of
# its own), a fine bright edge, quiet labels, no grid, and a gentle fall
G=(--file "$CONFIG_HOME/easyeffects/db/graphrc" --group Graph)
kw "${G[@]}" --key colorScheme 2              # dark
kw "${G[@]}" --key colorTheme 8               # userDefined: the colors below
kw "${G[@]}" --key backgroundColor "0,0,0,0"
kw "${G[@]}" --key plotAreaBackgroundColor "0,0,0,0"
kw "${G[@]}" --key seriesColors "$(rgb "$ACCENT"),70"
kw "${G[@]}" --key borderColors "$(rgb "$ACCENT_ALT"),255"
kw "${G[@]}" --key labelTextColor "$(rgb "$FG_DIM"),255"
kw "${G[@]}" --key labelBackgroundColor "0,0,0,0"
kw "${G[@]}" --key lineWidth 1.5
kw "${G[@]}" --key gridVisible false
S=(--file "$RC" --group Spectrum)
kw "${S[@]}" --key state true
kw "${S[@]}" --key spectrumShape 3            # area
kw "${S[@]}" --key nPoints 64                # fewer points: one smooth curve
kw "${S[@]}" --key logarithmicHorizontalAxis true
kw "${S[@]}" --key dynamicYScale false        # steady scale, no jumping
kw "${S[@]}" --key minimumLevel -80
kw "${S[@]}" --key maximumLevel 0
kw "${S[@]}" --key slope 3                    # pink-noise tilt: highs not buried
kw "${S[@]}" --key attackTime 0
kw "${S[@]}" --key decayTime 350              # peaks settle, macOS-like
kw "${S[@]}" --key spectrumFpsCap 60
info "$(L "spectrum in the RedRog colors" "espectro con los colores de RedRog")"

# "Restore speaker sound" in the menu
run install -m 755 "$REDROG_ROOT/modules/audio/redrog-audio-reset" "$LIB/redrog-audio-reset"
APPS="$DATA_HOME/applications"
run mkdir -p "$APPS"
if [ "$DRY_RUN" != 1 ]; then
  cat > "$APPS/redrog-audio-reset.desktop" <<EOF2
[Desktop Entry]
Type=Application
Name=Restore speaker sound
Name[es]=Restaurar sonido de los altavoces
Name[de]=Lautsprecherklang wiederherstellen
Name[fr]=Restaurer le son des haut-parleurs
Name[it]=Ripristina il suono degli altoparlanti
Name[pt]=Repor o som dos altifalantes
Name[pt_BR]=Restaurar o som dos alto-falantes
Name[ru]=Восстановить звук динамиков
Name[uk]=Відновити звук динаміків
Name[pl]=Przywróć dźwięk głośników
Name[nl]=Luidsprekergeluid herstellen
Name[tr]=Hoparlör sesini geri yükle
Name[cs]=Obnovit zvuk reproduktorů
Name[sv]=Återställ högtalarljudet
Name[zh_CN]=恢复扬声器音效
Name[zh_TW]=還原喇叭音效
Name[ja]=スピーカーの音を元に戻す
Name[ko]=스피커 사운드 복원
Name[ar]=استعادة صوت مكبرات الصوت
Name[hi]=स्पीकर की ध्वनि बहाल करें
Name[id]=Pulihkan suara speaker
Name[vi]=Khôi phục âm thanh loa
Comment=Put the built-in speaker tuning back as RedRog ships it
Comment[es]=Vuelve al ajuste original de RedRog para los altavoces integrados
Exec=$LIB/redrog-audio-reset
Icon=audio-speakers
Categories=AudioVideo;Audio;Settings;
Keywords=EasyEffects;speakers;sound;equalizer;altavoces;sonido;ecualizador;
EOF2
fi

# No icon of its own in the tray (Plasma would keep it with the application
# icons): the RedRog "Ecualizador" item below stands for it, among the
# hardware items, between the keyboard layout and the graphics mode
kw --file "$RC" --group Window --key showTrayIcon false

# Its launcher keeps "EasyEffects" among its search words: the menu calls it
# Ecualizador (modules/apps, menu-names.tsv). Written into the user copy, so
# package updates keep it (and without the Breeze override of earlier
# versions: the application style follows the light/dark switch live,
# modules/kvantum)
EE_DESKTOP=com.github.wwmm.easyeffects.desktop
if [ "$DRY_RUN" != 1 ] && [ -f "/usr/share/applications/$EE_DESKTOP" ]; then
  dst="$DATA_HOME/applications/$EE_DESKTOP"
  mkdir -p "$DATA_HOME/applications"
  [ -f "$dst" ] || cp "/usr/share/applications/$EE_DESKTOP" "$dst"
  sed -i -E 's/^Exec=env QT_STYLE_OVERRIDE=Breeze /Exec=/' "$dst"
  grep -q '^Keywords=.*easyeffects' "$dst" ||
    sed -i -E 's/^Keywords=(.*)$/Keywords=\1easyeffects;easy effects;/' "$dst"
  grep -q '^Keywords\[es\]=' "$dst" && ! grep -q '^Keywords\[es\]=.*easyeffects' "$dst" &&
    sed -i -E 's/^Keywords\[es\]=(.*)$/Keywords[es]=\1easyeffects;easy effects;ecualizador;/' "$dst"
fi

# Start in the background with the session
run mkdir -p "$CONFIG_HOME/autostart"
if [ "$DRY_RUN" != 1 ]; then
  cat > "$CONFIG_HOME/autostart/easyeffects-service.desktop" <<EOF2
[Desktop Entry]
Type=Application
Name=Equalizer
Name[es]=Ecualizador
Exec=easyeffects --service-mode --hide-window
Icon=com.github.wwmm.easyeffects
X-KDE-autostart-phase=2
NoDisplay=true
EOF2
  # and once it runs, the preset of the output playing at login
  cat > "$CONFIG_HOME/autostart/redrog-audio-login.desktop" <<EOF2
[Desktop Entry]
Type=Application
Name=RedRog sound
Exec=$LIB/redrog-audio-reset --login
X-KDE-autostart-phase=2
NoDisplay=true
EOF2
  (setsid easyeffects --service-mode --hide-window >/dev/null 2>&1 &)
  sleep 3
  # the preset of the output playing now
  "$LIB/redrog-audio-reset" --quiet >/dev/null 2>&1 || true
  # and each device's own preset again
  systemctl --user restart redrog-audio-memory.service >/dev/null 2>&1 || true
fi
# The tray item (org.redrog.equalizer): shown while EasyEffects runs. Plasma
# finds a new tray item only when it starts: the panels restart once when it
# is new.
EQ=org.redrog.equalizer
new=0
[ -d "$DATA_HOME/plasma/plasmoids/$EQ" ] && cmp -s "$REDROG_ROOT/modules/audio/$EQ/metadata.json" \
  "$DATA_HOME/plasma/plasmoids/$EQ/metadata.json" || new=1
run rm -rf "$DATA_HOME/plasma/plasmoids/$EQ"
run mkdir -p "$DATA_HOME/plasma/plasmoids"
run cp -r "$REDROG_ROOT/modules/audio/$EQ" "$DATA_HOME/plasma/plasmoids/$EQ"
for po in "$REDROG_ROOT"/i18n/equalizer/*.po; do
  [ -e "$po" ] || continue
  run mkdir -p "$DATA_HOME/locale/$(basename "$po" .po)/LC_MESSAGES"
  run msgfmt -o "$DATA_HOME/locale/$(basename "$po" .po)/LC_MESSAGES/plasma_applet_$EQ.mo" "$po"
done
if [ "$DRY_RUN" != 1 ] && [ "$new" = 1 ]; then
  systemctl --user reset-failed plasma-plasmashell.service 2>/dev/null
  systemctl --user restart plasma-plasmashell.service
  for _ in $(seq 30); do
    qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'print(1)' >/dev/null 2>&1 && break
    sleep 1
  done
  sleep 2
fi
plasma_script "
function list(t, key) {
    var v = t.readConfig(key, []);
    return typeof v == 'string' ? (v ? v.split(',') : []) : v;
}
panels().forEach(function (p) {
    p.widgetIds.forEach(function (id) {
        var t = p.widgetById(id);
        if (t.type != 'org.kde.plasma.systemtray') return;
        t.currentConfigGroup = ['General'];
        var extra = list(t, 'extraItems'), shown = list(t, 'shownItems'), hidden = list(t, 'hiddenItems');
        if (extra.length && extra.indexOf('$EQ') < 0) extra.push('$EQ');
        if (extra.length) t.writeConfig('extraItems', extra);
        t.writeConfig('shownItems', shown.filter(function (x) { return x != '$EQ'; }));
        t.writeConfig('hiddenItems', hidden.filter(function (x) { return x != '$EQ'; }));
        t.reloadConfig();
    });
});" >/dev/null

info "$(L "speaker preset active only on the speakers" "preset de parlantes activo solo en los parlantes"): $PRESET"
