#!/usr/bin/env bash
# Small fixes for individual applications.
#  - Octopi (package manager): its Spanish translation is only built in as
#    es_ES, and it picks the translation from the message locale (es_MX,
#    es_CO... fall back to English), so its launchers start it with Spanish
#    messages from Spain when the session is in another Spanish.
#  - Launchers that are not apps (plugin hosts, services) hidden from the menu.
#  - Images in Loupe and plain text in GNOME Text Editor by default.
#  - Quick Share on a fixed port (opened in the firewall by modules/system).
#  - "Sound Settings" in the menu (Plasma's Sound page).
#  - Video in Haruna (VLC with software decoding), mail/calendar/contacts in
#    Thunderbird; Ctrl+Esc opens
#    Mission Center and the Calculator key GNOME Calculator.
# describe: fixes for individual apps (Octopi in Spanish, menu cleanup) | ajustes de apps sueltas (Octopi en español, menú limpio)

if has octopi; then
  case "${LC_MESSAGES:-${LANG:-}}" in
    es_ES*|"") ;;
    es*)
      run mkdir -p "$DATA_HOME/applications"
      for d in /usr/share/applications/octopi*.desktop; do
        [ -f "$d" ] || continue
        [ "$DRY_RUN" = 1 ] || sed -E 's|^Exec=(env LC_MESSAGES=[^ ]+ )?|Exec=env LC_MESSAGES=es_ES.UTF-8 |' "$d" \
          > "$DATA_HOME/applications/$(basename "$d")"
      done
      for a in /etc/xdg/autostart/octopi*.desktop; do
        [ -f "$a" ] || continue
        run mkdir -p "$CONFIG_HOME/autostart"
        [ "$DRY_RUN" = 1 ] || sed -E 's|^Exec=(env LC_MESSAGES=[^ ]+ )?|Exec=env LC_MESSAGES=es_ES.UTF-8 |' "$a" \
          > "$CONFIG_HOME/autostart/$(basename "$a")"
      done
      run kbuildsycoca6 >/dev/null 2>&1 || true
      info "$(L "Octopi in Spanish" "Octopi en español")" ;;
  esac
fi

# Launchers that are not apps to open from the menu, hidden from it (a copy
# in ~/.local/share/applications with NoDisplay=true; the program stays):
#  - Dragonfly Reverb's standalone versions (JACK hosts with no icon): the
#    reverbs are used as plugins inside EasyEffects, OBS and Audacity
#  - Plasma's Foreground Booster: a background service with no icon
#  - developer and helper tools macOS keeps out of Launchpad (Qt and Java
#    tools, terminal editors, Octopi's helpers, setup and test utilities)
#  - apps replaced by the macOS-style ones below (System Monitor by Mission
#    Center) and duplicates (the second "System Settings", mpv next to
#    Haruna and VLC, KDE Connect's SMS and non-Plasma indicator; btop and nvtop,
#    terminal monitors Mission Center covers: nvtop stays as its GPU backend)
HIDE=(io.github.michaelwillis.DragonflyEarlyReflections io.github.michaelwillis.DragonflyHallReverb
      io.github.michaelwillis.DragonflyPlateReverb io.github.michaelwillis.DragonflyRoomReverb
      org.kde.foreground-booster
      assistant designer linguist qdbusviewer qv4l2 qvidcap lstopo cmake-gui
      jconsole-java-openjdk jshell-java-openjdk vim micro
      octopi-notifier octopi-cachecleaner octopi-repoeditor
      scrcpy-console blackmagicraw-speedtest DaVinciControlPanelsSetup
      winetricks protontricks nvidia-settings cachyos-hello
      kdesystemsettings mpv org.kde.kdeconnect.sms org.kde.kdeconnect.nonplasma
      btop nvtop)
[ -f /usr/share/applications/io.missioncenter.MissionCenter.desktop ] && HIDE+=(org.kde.plasma-systemmonitor)
hidden=0
for id in "${HIDE[@]}"; do
  src="/usr/share/applications/$id.desktop"
  dst="$DATA_HOME/applications/$id.desktop"
  [ -f "$src" ] || continue
  run mkdir -p "$DATA_HOME/applications"
  # a copy made earlier by this module (Octopi's Spanish launchers) keeps its changes
  [ -f "$dst" ] && grep -q '^Exec=env LC_MESSAGES=' "$dst" && src="$dst"
  [ "$DRY_RUN" = 1 ] || { grep -v '^NoDisplay=' "$src" | sed '/^\[Desktop Entry\]/a NoDisplay=true' > "$dst.new" \
                            && mv "$dst.new" "$dst"; }
  hidden=$((hidden + 1))
done
if [ "$hidden" -gt 0 ]; then
  run kbuildsycoca6 >/dev/null 2>&1 || true
  info "$(L "$hidden launchers that are not everyday apps hidden from the menu" \
            "$hidden lanzadores que no son apps de uso diario ocultos del menú")"
fi

# Images open in Loupe and plain text in GNOME Text Editor (like macOS
# Preview and TextEdit); code keeps VS Code if it is installed
setdefault() {  # desktop id, mime types...
  local app=$1; shift
  [ -f "/usr/share/applications/$app" ] || return 0
  run xdg-mime default "$app" "$@" 2>/dev/null
}
if [ -f /usr/share/applications/org.gnome.Loupe.desktop ]; then
  setdefault org.gnome.Loupe.desktop image/png image/jpeg image/gif image/webp image/bmp image/tiff \
    image/svg+xml image/avif image/heic image/heif image/jxl image/x-icon image/vnd.microsoft.icon image/x-tga
  info "$(L "images open in Loupe" "las imágenes se abren en Loupe")"
fi
if [ -f /usr/share/applications/org.gnome.TextEditor.desktop ]; then
  setdefault org.gnome.TextEditor.desktop text/plain text/x-log text/markdown text/csv text/x-readme
  setdefault com.microsoft.VSCode.desktop application/json application/xml application/x-shellscript \
    text/x-python text/x-csrc text/x-chdr text/x-c++src text/x-makefile application/toml text/x-script.python
  # follows the dark theme; each launch starts clean, like TextEdit without open documents
  run gsettings set org.gnome.TextEditor style-variant follow 2>/dev/null || true
  run gsettings set org.gnome.TextEditor restore-session false 2>/dev/null || true
  # proportional text font like TextEdit (code goes to VS Code)
  run gsettings set org.gnome.TextEditor use-system-font false 2>/dev/null || true
  run gsettings set org.gnome.TextEditor custom-font "Inter 12" 2>/dev/null || true
  info "$(L "plain text opens in GNOME Text Editor" "el texto se abre en el Editor de texto de GNOME")"
fi

# Video opens in Haruna (mpv: hardware decoding on the NVIDIA card, every
# format, the RedRog look). Showtime 50 never shows its window when given a
# file on this laptop, so it is not the default. VLC stays for discs and
# streams, with software decoding: its VA-API path on the NVIDIA driver failed
# with "thread_get_buffer() failed" and showed nothing.
VIDEO_MIME=(video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo video/mpeg video/ogg
            video/x-flv video/3gpp video/x-ms-wmv video/mp2t video/x-m4v video/mp2t video/vnd.avi)
if [ -f /usr/share/applications/org.kde.haruna.desktop ]; then
  setdefault org.kde.haruna.desktop "${VIDEO_MIME[@]}"
  # the RedRog colors and Qt style, the KDE window (traffic lights), hardware
  # decoding on the NVIDIA card
  H=(--file haruna/haruna.conf --group General)
  kw "${H[@]}" --key ColorScheme "$REDROG_NAME"
  kw "${H[@]}" --key GuiStyle Default
  kw --file haruna/haruna.conf --group Playback --key HWDecoding auto-safe
  info "$(L "video opens in Haruna (RedRog colors)" "los videos se abren en Haruna (colores RedRog)")"
fi
VLCRC="$CONFIG_HOME/vlc/vlcrc"
if has vlc && [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$(dirname "$VLCRC")"; touch "$VLCRC"
  if grep -q '^#\?avcodec-hw=' "$VLCRC"; then
    sed -i 's/^#\?avcodec-hw=.*/avcodec-hw=none/' "$VLCRC"
  else
    printf '[avcodec]\navcodec-hw=none\n' >> "$VLCRC"
  fi
fi
# Thunderbird is Mail, Calendar and Contacts
if [ -f /usr/share/applications/org.mozilla.Thunderbird.desktop ]; then
  setdefault org.mozilla.Thunderbird.desktop x-scheme-handler/mailto message/rfc822 text/calendar text/vcard text/x-vcard
  info "$(L "Thunderbird for mail, calendar and contacts" "Thunderbird para correo, calendario y contactos")"
fi
# Keys: Ctrl+Esc opens Mission Center (Activity Monitor) instead of System
# Monitor, and the Calculator key opens GNOME Calculator
shortcut() { run python3 -I "$REDROG_ROOT/lib/set-shortcut.py" "$@" >/dev/null 2>&1 || true; }
if [ -f /usr/share/applications/io.missioncenter.MissionCenter.desktop ]; then
  shortcut org.kde.plasma-systemmonitor.desktop _launch
  shortcut io.missioncenter.MissionCenter.desktop _launch Ctrl+Escape
  info "$(L "Ctrl+Esc opens Mission Center" "Ctrl+Esc abre Mission Center")"
fi
if [ -f /usr/share/applications/org.gnome.Calculator.desktop ]; then
  shortcut org.gnome.Calculator.desktop _launch Calculator
fi

# Quick Share (RQuickShare-X) on a fixed port, the one modules/system opens
# in the firewall (by default it picks a random port the firewall blocks)
QS="$DATA_HOME/dev.mandre.rquicksharex/.settings.json"
if has rquickshare-x && [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$(dirname "$QS")"
  python3 -I - "$QS" <<'PY2'
import json, os, sys
p = sys.argv[1]
d = json.load(open(p)) if os.path.exists(p) else {}
d["port"] = 45555
json.dump(d, open(p, "w"), indent=2)
PY2
  info "$(L "Quick Share on port 45555" "Quick Share en el puerto 45555")"
fi

# "Sound Settings" in the menu, like macOS: Plasma's own Sound page (outputs,
# inputs, per-app volume and profiles), in the user's language and the RedRog
# style; the page itself is hidden from the menu by Plasma
if [ -f /usr/share/applications/kcm_pulseaudio.desktop ] && [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$DATA_HOME/applications"
  cat > "$DATA_HOME/applications/redrog-sound-settings.desktop" <<'EOF2'
[Desktop Entry]
Type=Application
Name=Sound Settings
Name[es]=Ajustes de sonido
Comment=Outputs, inputs and volume of each app
Comment[es]=Salidas, entradas y volumen de cada app
Exec=systemsettings kcm_pulseaudio
Icon=preferences-desktop-sound
Categories=AudioVideo;Audio;Mixer;
Keywords=sound;audio;volume;speakers;microphone;sonido;volumen;altavoces;micrófono;
EOF2
  run kbuildsycoca6 >/dev/null 2>&1 || true
  info "$(L "Sound Settings in the menu" "Ajustes de sonido en el menú")"
fi

# Notion like the macOS app: traffic lights in its own tab bar instead of
# Windows-style buttons over the workspace name (notion/notion-run explains how)
if [ -f /usr/share/applications/notion.desktop ] && [ "$DRY_RUN" != 1 ]; then
  N="$REAL_HOME/.local/lib/redrog/notion"
  mkdir -p "$N" "$DATA_HOME/applications"
  install -m755 "$REDROG_ROOT/modules/apps/notion/notion-run" "$N/notion-run"
  install -m644 "$REDROG_ROOT/modules/apps/notion/notion-patch.py" "$REDROG_ROOT/modules/apps/notion/redrog-main.js" "$N/"
  rm -f "$N/app.asar" "$REAL_HOME/.local/lib/redrog/notion-run"   # rebuilt on the next start
  sed "s|^Exec=[^ ]*|Exec=$N/notion-run|" /usr/share/applications/notion.desktop > "$DATA_HOME/applications/notion.desktop"
  info "$(L "Notion with macOS traffic lights" "Notion con semáforos como en macOS")"
fi

# Claude desktop with macOS traffic lights instead of Chromium's grey window
# buttons (claude/claude-run explains how); takes effect on its next start
if [ -f /usr/share/applications/com.anthropic.Claude.desktop ] && [ "$DRY_RUN" != 1 ]; then
  C="$REAL_HOME/.local/lib/redrog/claude"
  mkdir -p "$C" "$DATA_HOME/applications"
  install -m755 "$REDROG_ROOT/modules/apps/claude/claude-run" "$C/claude-run"
  install -m644 "$REDROG_ROOT/modules/apps/claude/claude-patch.py" "$REDROG_ROOT/modules/apps/claude/redrog-main.js" "$C/"
  rm -f "$C/app/.redrog-version"   # rebuilt on the next start
  sed "s|^Exec=claude-desktop|Exec=$C/claude-run|" /usr/share/applications/com.anthropic.Claude.desktop \
    > "$DATA_HOME/applications/com.anthropic.Claude.desktop"
  info "$(L "Claude desktop with macOS traffic lights (next time it starts)" "Claude desktop con semáforos como en macOS (la próxima vez que se abra)")"
fi

# Antigravity with the RedRog traffic lights instead of the Windows-style
# caption buttons (antigravity/antigravity-run explains how); takes effect on
# its next start
if [ -f /usr/share/applications/antigravity.desktop ] && [ "$DRY_RUN" != 1 ]; then
  A="$REAL_HOME/.local/lib/redrog/antigravity"
  mkdir -p "$A" "$DATA_HOME/applications"
  install -m755 "$REDROG_ROOT/modules/apps/antigravity/antigravity-run" "$A/antigravity-run"
  install -m644 "$REDROG_ROOT/modules/apps/antigravity/antigravity-patch.py" \
                "$REDROG_ROOT/modules/apps/antigravity/redrog-main.js" "$A/"
  rm -f "$A/app/.redrog-version"   # rebuilt on the next start
  sed "s|^Exec=/usr/bin/antigravity|Exec=$A/antigravity-run|" /usr/share/applications/antigravity.desktop \
    > "$DATA_HOME/applications/antigravity.desktop"
  info "$(L "Antigravity with the RedRog traffic lights (next time it starts)" "Antigravity con el semáforo de RedRog (la próxima vez que se abra)")"
fi

# Android Studio: the SDK in ~/Android/Sdk (where Studio installs it) for
# every program of the session, its tools in PATH ahead of the system's adb
# (one adb server version for the terminal and Studio), and Studio's own JDK
# for Gradle builds (the system Java is newer than Gradle supports; only
# Gradle uses it, other Java programs keep the system's)
if [ -x /opt/android-studio/bin/studio ] && [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$CONFIG_HOME/environment.d" "$REAL_HOME/.gradle"
  cat > "$CONFIG_HOME/environment.d/60-android.conf" <<'ENVD'
# RedRog (modules/apps): the Android SDK that Android Studio uses
ANDROID_HOME=${HOME}/Android/Sdk
ANDROID_SDK_ROOT=${HOME}/Android/Sdk
PATH=${HOME}/Android/Sdk/platform-tools:${HOME}/Android/Sdk/emulator:${HOME}/Android/Sdk/cmdline-tools/latest/bin:${PATH}
ENVD
  gp="$REAL_HOME/.gradle/gradle.properties"
  grep -qs '^org.gradle.java.home=' "$gp" || echo "org.gradle.java.home=/opt/android-studio/jbr" >> "$gp"
fi

# Launchers named "CachyOS ..." lose the prefix ("CachyOS Kernel Manager" is
# "Kernel Manager"): their own copy if this module already made one (hidden
# ones stay hidden), a new copy otherwise
if [ "$DRY_RUN" != 1 ]; then
  renamed=0
  for src in /usr/share/applications/*.desktop; do
    grep -qE '^Name(\[[a-zA-Z_@]+\])?=CachyOS ' "$src" || continue
    dst="$DATA_HOME/applications/$(basename "$src")"
    [ -f "$dst" ] || cp "$src" "$dst"
    sed -i -E 's/^(Name(\[[a-zA-Z_@]+\])?)=CachyOS /\1=/' "$dst"
    renamed=$((renamed + 1))
  done
  [ "$renamed" = 0 ] || { run kbuildsycoca6 >/dev/null 2>&1 || true
    info "$(L "$renamed launchers without the \"CachyOS\" prefix" "$renamed lanzadores sin el prefijo «CachyOS»")"; }
fi

# CachyOS' update notifier as "Actualizaciones" (Updates) with the Arch logo
for d in arch-update arch-update-tray; do
  src=/usr/share/applications/$d.desktop
  [ -f "$src" ] && [ "$DRY_RUN" != 1 ] || continue
  dst="$DATA_HOME/applications/$d.desktop"
  [ -f "$dst" ] || cp "$src" "$dst"
  name="Updates"; name_es="Actualizaciones"
  [ "$d" = arch-update-tray ] && { name="Updates (tray)"; name_es="Actualizaciones (bandeja)"; }
  sed -i -E -e "/^Name\[/d" -e "s/^Name=.*/Name=$name\nName[es]=$name_es/" "$dst"
  sed -i -E "s/^Icon=.*/Icon=redrog-updates/" "$dst"
done

# Menu names in Spanish and short, from menu-names.tsv: written into the
# launcher's own copy (made here if no other step made one), so they survive
# package updates. Spanish dialect variants are dropped so these apply.
if [ "$DRY_RUN" != 1 ]; then
  named=0
  while IFS= read -r line; do
    case "$line" in ''|\#*) continue ;; esac
    # split by hand: read with IFS=tab would merge empty columns
    id=${line%%$'\t'*}; rest=${line#*$'\t'}; name=${rest%%$'\t'*}; generic=${rest#*$'\t'}
    src=""
    for d in "$DATA_HOME/applications" /usr/share/applications; do
      [ -f "$d/$id" ] && { src="$d/$id"; break; }
    done
    [ -n "$src" ] || continue
    dst="$DATA_HOME/applications/$id"
    [ "$src" = "$dst" ] || cp "$src" "$dst"
    python3 -I - "$dst" "$name" "$generic" <<'PY2'
import re, sys
path, name, generic = sys.argv[1:]
lines = open(path, encoding="utf-8").read().split("\n")
out, in_entry = [], False
for line in lines:
    if line.startswith("["):
        in_entry = line.strip() == "[Desktop Entry]"
    if in_entry and (name and re.match(r"^Name\[es(_[A-Z]{2})?\]=", line)
                     or generic and re.match(r"^GenericName\[es(_[A-Z]{2})?\]=", line)):
        continue
    out.append(line)
    if line.strip() == "[Desktop Entry]":
        if name:
            out.append("Name[es]=" + name)
        if generic:
            out.append("GenericName[es]=" + generic)
open(path, "w", encoding="utf-8").write("\n".join(out))
PY2
    named=$((named + 1))
  done < "$REDROG_ROOT/modules/apps/menu-names.tsv"
  run kbuildsycoca6 >/dev/null 2>&1 || true
  info "$(L "$named menu names in Spanish and short" "$named nombres del menú en español y cortos")"
fi
