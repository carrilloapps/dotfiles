#!/usr/bin/env bash
# Audio spectrum on the desktop, whatever the wallpaper: redrog-spectrum (a
# user service) draws whatever is playing (Spotify, browsers, any app, through
# CAVA) as a halo in the center of each screen or as bars along its bottom
# edge, in the RedRog palette, on a transparent layer of its own over the
# wallpaper and under every window and panel (clicks go through to the
# desktop). It fades out after a few seconds of silence. SPECTRUM_STYLE in
# config sets halo or bars. The wallpaper itself is a plain Plasma image,
# free to change. A tray switch (org.redrog.spectrumswitch, redrog-spectrum-ctl)
# turns it on or off altogether; it shows on the top bar only while it is on.
#
# CAVA runs through the process plugin of Kurve (plasma6-applets-kurve-git),
# whose Spanish translation is installed too.
# describe: audio spectrum on the desktop (halo or bars) | espectro de audio en el escritorio (halo o barras)

KURVE=luisbocanegra.audio.visualizer
OLD_WP=org.redrog.spectrum
if [ ! -d /usr/lib/qt6/qml/com/github/luisbocanegra/audiovisualizer/process ] || ! has cava; then
  warn "$(L "Kurve or cava is not installed: skipped (./install.sh --packages)" "Kurve o cava no están instalados: se omite (./install.sh --packages)")"
  return 0
fi

# Translations: Kurve
compile() {  # po directory, gettext domain
  for po in "$REDROG_ROOT/i18n/$1"/*.po; do
    [ -e "$po" ] || continue
    local lang; lang=$(basename "$po" .po)
    run mkdir -p "$DATA_HOME/locale/$lang/LC_MESSAGES"
    run msgfmt -o "$DATA_HOME/locale/$lang/LC_MESSAGES/$2.mo" "$po"
  done
}
compile kurve "plasma_applet_$KURVE"

# Earlier versions drew the spectrum inside a wallpaper plugin, so changing the
# wallpaper lost it: desktops on it go back to a plain image (the same one)
plasma_script "
desktops().forEach(function (d) {
    d.widgets('$KURVE').forEach(function (w) { w.remove(); });
    if (d.wallpaperPlugin != '$OLD_WP') return;
    d.currentConfigGroup = ['Wallpaper', '$OLD_WP', 'General'];
    var image = String(d.readConfig('Image', '')) || 'file://$WALLPAPER';
    d.wallpaperPlugin = 'org.kde.image';
    d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
    d.writeConfig('Image', image);
    d.reloadConfig();
});" >/dev/null
run rm -rf "$DATA_HOME/plasma/wallpapers/$OLD_WP" "$REAL_HOME/.local/state/redrog/spectrum-set"

# The spectrum layer: style and palette written in, the emblem in the accent
APP="$REAL_HOME/.local/lib/redrog/spectrum"
run rm -rf "$APP"
run mkdir -p "$(dirname "$APP")"
run cp -r "$REDROG_ROOT/modules/visualizer/spectrum" "$APP"
case "${SPECTRUM_STYLE:-halo}" in bars) style=bars ;; *) style=halo ;; esac
# The user's settings ("Espectro de audio" in the menu): created once with the
# RedRog defaults and never overwritten, so they survive updates and reinstalls
CFG="$CONFIG_HOME/redrog/spectrum.json"
if [ "$DRY_RUN" != 1 ]; then
  # the dark palette's colors in both variants: it is drawn over the
  # wallpaper, with a dark vignette of its own
  read -r s_accent s_alt s_fg < <(REDROG_VARIANT=dark HOME="$REAL_HOME" bash -c \
    'source "$REDROG_ROOT/lib/palette.sh"; echo "$ACCENT $ACCENT_ALT $FG"')
  sed -i -e "s|@CONFIG@|$CFG|" -e "s/@STYLE@/$style/" -e "s/@BASE@/#$s_accent/" -e "s/@MIDDLE@/#$s_alt/" \
         -e "s/@TIP@/#$s_fg/" "$APP/Spectrum.qml" "$APP/Settings.qml"
  sed -i "s/#ef3340/#$s_accent/g" "$APP/images/logo.svg"
  if [ ! -f "$CFG" ]; then
    mkdir -p "$(dirname "$CFG")"
    printf '{\n  "enabled": true,\n  "style": "%s",\n  "framerate": 60,\n  "smoothing": 77,\n  "autoSensitivity": true,\n  "sensitivity": 100,\n  "opacity": 100,\n  "fadeSeconds": 3\n}\n' "$style" > "$CFG"
  fi
  mkdir -p "$DATA_HOME/applications"
  cat > "$DATA_HOME/applications/redrog-spectrum-settings.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Audio spectrum
Name[es]=Espectro de audio
GenericName=Desktop music visualizer
GenericName[es]=Visualizador de música del escritorio
Comment=Style, smoothness and intensity of the desktop audio spectrum
Comment[es]=Estilo, fluidez e intensidad del espectro de audio del escritorio
Exec=env QML_XHR_ALLOW_FILE_READ=1 qml6 $APP/Settings.qml
Icon=spek
Terminal=false
Categories=Settings;AudioVideo;
Keywords=spectrum;visualizer;cava;music;espectro;visualizador;música;
StartupWMClass=qml6
DESKTOP
  mkdir -p "$CONFIG_HOME/systemd/user"
  cat > "$CONFIG_HOME/systemd/user/redrog-spectrum.service" <<UNIT
[Unit]
Description=RedRog audio spectrum on the desktop
PartOf=graphical-session.target
After=plasma-plasmashell.service pipewire.service

[Service]
Environment=QT_QPA_PLATFORM=wayland QT_WAYLAND_SHELL_INTEGRATION=layer-shell
# it reads its settings file while it runs
Environment=QML_XHR_ALLOW_FILE_READ=1
ExecStart=/usr/bin/qml6 $APP/Spectrum.qml
Restart=on-failure
RestartSec=3
Nice=10

[Install]
WantedBy=graphical-session.target
UNIT
fi
run systemctl --user daemon-reload
# on or off as it was left (redrog-spectrum-ctl): turned off, it stays off
run install -Dm755 "$REDROG_ROOT/modules/visualizer/redrog-spectrum-ctl" "$REAL_HOME/.local/lib/redrog/redrog-spectrum-ctl"
run mkdir -p "$REAL_HOME/.local/bin"
run ln -sfn "$REAL_HOME/.local/lib/redrog/redrog-spectrum-ctl" "$REAL_HOME/.local/bin/redrog-spectrum-ctl"
if [ -e "$REAL_HOME/.local/state/redrog/spectrum-off" ]; then
  run systemctl --user disable --now redrog-spectrum.service >/dev/null 2>&1 || true
else
  run systemctl --user enable redrog-spectrum.service >/dev/null 2>&1 || true
  run systemctl --user restart redrog-spectrum.service >/dev/null 2>&1 || true
fi

# Its switch in the system tray (org.redrog.spectrumswitch): on the top bar
# while the spectrum is on, among the tray's hidden items while it is off (so
# it is enabled in every tray, never pinned as always shown). Plasma finds a
# new tray item only when it starts: the panels restart once when it is new.
SW=org.redrog.spectrumswitch
new=0
[ -d "$DATA_HOME/plasma/plasmoids/$SW" ] && cmp -s "$REDROG_ROOT/modules/visualizer/$SW/metadata.json" \
  "$DATA_HOME/plasma/plasmoids/$SW/metadata.json" || new=1
run rm -rf "$DATA_HOME/plasma/plasmoids/$SW"
run mkdir -p "$DATA_HOME/plasma/plasmoids"
run cp -r "$REDROG_ROOT/modules/visualizer/$SW" "$DATA_HOME/plasma/plasmoids/$SW"
compile spectrumswitch "plasma_applet_$SW"
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
        if (extra.length && extra.indexOf('$SW') < 0) extra.push('$SW');
        if (extra.length) t.writeConfig('extraItems', extra);
        t.writeConfig('shownItems', shown.filter(function (x) { return x != '$SW'; }));
        t.writeConfig('hiddenItems', hidden.filter(function (x) { return x != '$SW'; }));
        t.reloadConfig();
    });
});" >/dev/null
run kbuildsycoca6 >/dev/null 2>&1 || true
info "$(L "audio spectrum on every screen, whatever the wallpaper:" "espectro de audio en todas las pantallas, sea cual sea el fondo:") $style"

# Every screen, however many: Plasma gives each new screen its stock
# wallpaper, so a small user service watches the connected screens and gives
# each new desktop the RedRog image, once: whatever is picked by hand on a
# screen afterwards, even a stock wallpaper, is kept.
SYNC_DIR="$REAL_HOME/.local/lib/redrog"
if [ "$DRY_RUN" != 1 ]; then
  mkdir -p "$SYNC_DIR" "$CONFIG_HOME/systemd/user"
  cat > "$SYNC_DIR/wallpaper-sync.js" <<EOF
// RedRog: the RedRog wallpaper on every screen (modules/visualizer)
function stock(d) {
    if (d.wallpaperPlugin != 'org.kde.image') return false;
    d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
    var image = String(d.readConfig('Image', ''));
    return image == '' || image.indexOf('/usr/share/wallpapers') >= 0;
}
// each desktop gets it once, when it first shows up: whatever is picked on
// it afterwards (even a stock wallpaper) stays
function seen(d) {
    d.currentConfigGroup = ['RedRog'];
    var done = String(d.readConfig('wallpaperSynced', 'false')) == 'true';
    d.writeConfig('wallpaperSynced', 'true');
    return done;
}
desktops().forEach(function (d) {
    if (seen(d) || !stock(d)) return;
    d.currentConfigGroup = ['Wallpaper', 'org.kde.image', 'General'];
    d.writeConfig('Image', 'file://$WALLPAPER_PKG');
    // what RedRog put here: only this image is ever replaced (modules/global-theme)
    d.currentConfigGroup = ['RedRog'];
    d.writeConfig('wallpaperApplied', '$WALLPAPER_PKG');
    d.reloadConfig();
});
EOF
  cat > "$SYNC_DIR/redrog-wallpaper-sync" <<'EOF'
#!/bin/bash
# RedRog: keeps every screen on the RedRog wallpaper (modules/visualizer).
# Checks the connected screens every few seconds (a few file reads) and syncs
# the wallpapers when they change. The lock and login screens follow the
# main screen's wallpaper, whatever the user picks.
js="$HOME/.local/lib/redrog/wallpaper-sync.js"
appletsrc="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
followed="$HOME/.local/state/redrog/followed-wallpaper"
login=/var/lib/redrog-login
screens() {
  local f s out=""
  for f in /sys/class/drm/card*-*/status; do read -r s < "$f" && out+="$f=$s "; done
  printf '%s' "$out"
}
sync_now() { qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(<"$js")" >/dev/null 2>&1; }
# Every screen gets the top bar of the main screen (the dock stays on the main
# screen only): Plasma can't place a panel from a script, so the bar is copied
# in its files while it is stopped (plasma-clone-panel.py), only when a screen
# has none yet
panels() {
  local n tops
  n=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript 'print(screenCount)' 2>/dev/null | tr -dc 0-9)
  [ -n "$n" ] && [ "$n" -gt 1 ] || return 0
  tops=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript \
    'var s=[]; panels().forEach(function(p){ if (p.location=="top" && s.indexOf(p.screen)<0) s.push(p.screen); }); print(s.length)' 2>/dev/null | tr -dc 0-9)
  [ -n "$tops" ] && [ "$tops" -lt "$n" ] || return 0
  systemctl --user stop plasma-plasmashell.service
  python3 -I "$HOME/.local/lib/redrog/plasma-clone-panel.py" \
    "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" "$HOME/.config/plasmashellrc" "$n" >/dev/null
  systemctl --user start plasma-plasmashell.service
  sleep 6
}
# The main screen's wallpaper (an image, or a wallpaper package's largest
# image) on the lock screen and, re-encoded (sized, metadata stripped), on the
# login screen. Slideshows, colors and other plugins leave both as they are.
follow() {
  local img
  img=$(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript '
var main = null;
desktops().forEach(function (d) { if (d.screen == 0) main = d; });
if (main && main.wallpaperPlugin == "org.kde.image") {
    main.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    print(String(main.readConfig("Image", "")));
}' 2>/dev/null)
  img=${img#file://}
  [ -d "$img" ] && img=$(ls -S "$img"/contents/images/* 2>/dev/null | head -1)
  [ -f "$img" ] || return 0
  [ "$img" = "$(cat "$followed" 2>/dev/null)" ] && return 0
  kwriteconfig6 --file kscreenlockerrc --group Greeter --group Wallpaper --group org.kde.image \
    --group General --key Image "file://$img"
  if [ -w "$login" ]; then
    magick "$img[0]" -auto-orient -strip -resize '2560x1440>' -quality 90 "$login/.wallpaper.jpg" \
      && mv -f "$login/.wallpaper.jpg" "$login/wallpaper.jpg"
  fi
  mkdir -p "$(dirname "$followed")"
  printf '%s\n' "$img" > "$followed"
}
veil() { [ -x "$HOME/.local/lib/redrog/redrog-panel-veil" ] && "$HOME/.local/lib/redrog/redrog-panel-veil" >/dev/null 2>&1; }
sleep 8; sync_now; panels; follow; veil
last=$(screens)
saved=$(stat -c %Y "$appletsrc" 2>/dev/null)
while sleep 3; do
  # Plasma saves its desktops when a wallpaper changes
  mtime=$(stat -c %Y "$appletsrc" 2>/dev/null)
  # (and the top bar's veil over the new wallpaper: modules/layout)
  [ "$mtime" != "$saved" ] && { saved=$mtime; follow; veil; }
  now=$(screens)
  [ "$now" = "$last" ] && continue
  last=$now
  sleep 4   # Plasma creates the new desktop first
  sync_now
  panels
  veil
done
EOF
  chmod +x "$SYNC_DIR/redrog-wallpaper-sync"
  install -m644 "$REDROG_ROOT/lib/plasma-clone-panel.py" "$SYNC_DIR/plasma-clone-panel.py"
  cat > "$CONFIG_HOME/systemd/user/redrog-wallpaper-sync.service" <<EOF
[Unit]
Description=RedRog wallpaper on every screen
PartOf=graphical-session.target
After=plasma-plasmashell.service

[Service]
ExecStart=$SYNC_DIR/redrog-wallpaper-sync
Restart=on-failure
Nice=19

[Install]
WantedBy=graphical-session.target
EOF
  systemctl --user daemon-reload
  systemctl --user enable --now redrog-wallpaper-sync.service >/dev/null 2>&1 || true
  systemctl --user restart redrog-wallpaper-sync.service >/dev/null 2>&1 || true
  # and right now
  qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$(<"$SYNC_DIR/wallpaper-sync.js")" >/dev/null 2>&1 || true
fi
info "$(L "RedRog wallpaper and top bar on every screen, also screens connected later; lock and login screens follow the main screen's wallpaper" \
          "fondo RedRog y barra superior en todas las pantallas, también las que conectes después; bloqueo e inicio de sesión siguen el fondo de la pantalla principal")"
