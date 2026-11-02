#!/usr/bin/env bash
# Spotify in the RedRog colors with Spicetify (AUR: spicetify-cli): a
# "RedRog" theme made from the palette, applied to the Spotify that
# spotify-launcher installs in your home. Spotify updates overwrite the
# patch, so a user path unit re-applies it whenever the app files change.
# describe: Spotify in the RedRog colors (Spicetify) | Spotify con los colores de RedRog (Spicetify)

if ! has spicetify; then
  info "$(L "Spicetify is not installed (AUR: spicetify-cli): skipped" "Spicetify no está instalado (AUR: spicetify-cli): se omite")"
  return 0
fi
SPOTIFY=""
for d in "$DATA_HOME/spotify-launcher/install/usr/share/spotify" /opt/spotify; do
  [ -f "$d/Apps/xpui.spa" ] || [ -d "$d/Apps/xpui" ] && { SPOTIFY="$d"; break; }
done
if [ -z "$SPOTIFY" ] || [ ! -w "$SPOTIFY/Apps" ]; then
  warn "$(L "no writable Spotify install found (open Spotify once first)" "no se encontró una instalación de Spotify con permisos de escritura (abre Spotify una vez)")"
  return 0
fi

TH="$CONFIG_HOME/spicetify/Themes/RedRog"
run mkdir -p "$TH"
if [ "$DRY_RUN" != 1 ]; then
  # both schemes, [RedRog] and [RedRog-Light]: the light/dark switch picks one
  scheme() {
    sed -e "s/^\[RedRog\]$/[$THEME_ID]/" \
        -e "s/@FG_DIM@/$FG_DIM/g; s/@FG@/$FG/g; s/@BG@/$BG/g; s/@DEEP@/$DEEP/g" \
        -e "s/@SURFACE_HI@/$SURFACE_HI/g; s/@SURFACE@/$SURFACE/g; s/@ACCENT_ALT@/$ACCENT_ALT/g; s/@ACCENT@/$ACCENT/g" \
        "$REDROG_ROOT/modules/spotify/theme/color.ini"
    echo
  }
  for_each_variant scheme > "$TH/color.ini"
  cp "$REDROG_ROOT/modules/spotify/theme/user.css" "$TH/user.css"
fi
run spicetify config spotify_path "$SPOTIFY" prefs_path "$CONFIG_HOME/spotify/prefs" >/dev/null
run spicetify config current_theme RedRog color_scheme "$THEME_ID" inject_css 1 replace_colors 1 >/dev/null
run spicetify backup apply -n >/dev/null 2>&1 || run spicetify apply -n >/dev/null 2>&1 || true

# Re-apply after Spotify updates (spotify-launcher rewrites the app files)
UNIT="$CONFIG_HOME/systemd/user"
run mkdir -p "$UNIT"
if [ "$DRY_RUN" != 1 ]; then
  cat > "$UNIT/redrog-spicetify.path" <<EOF2
[Unit]
Description=Re-apply the RedRog Spotify theme after Spotify updates

[Path]
# an update brings back the unpatched xpui.spa (Spicetify unpacks it when
# patching), so this fires once per update and never on its own changes
PathExists=$SPOTIFY/Apps/xpui.spa
Unit=redrog-spicetify.service

[Install]
WantedBy=default.target
EOF2
  cat > "$UNIT/redrog-spicetify.service" <<EOF2
[Unit]
Description=Re-apply the RedRog Spotify theme (Spicetify)

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 5
ExecStart=/bin/sh -c 'spicetify backup apply -n || spicetify apply -n'
EOF2
fi
run systemctl --user daemon-reload
run systemctl --user enable --now redrog-spicetify.path >/dev/null 2>&1 || true
info "$(L "Spotify themed (restart Spotify)" "Spotify con el tema (reinicia Spotify)")"
