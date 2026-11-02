#!/usr/bin/env bash
# The ArtCraft suite (storytold.ai): the ArtCraft launcher and the Craft apps,
# and SolidCraft (3D parametric CAD, tangency-labs), as their official Arch packages, from the local repository
# [redrog-artcraft] that redrog-artcraft-repo.timer refreshes from the
# GitHub releases every 6 hours (each package checked against its release's
# SHA256SUMS.txt), so their updates arrive with the system's in pacman and
# arch-update ("Actualizaciones"). The AUR builds lag behind and compile with
# cargo; the AppImages of earlier RedRog versions are replaced.
# Every app also gets its MCP server in Claude Code and agy (artcraft-mcp:
# the open window when there is one, the headless engine otherwise), its
# control port in the session (environment.d) and the "artcraft" skill.
# FilmCraft opens an empty project instead of its demo. Every app starts on
# the discrete GPU with memory budgets sized for this machine (tune.py), and
# no Craft window opens larger than its screen (KWin script redrog-craft-fit).
# describe: ArtCraft suite (Craft apps) and its MCP servers | suite ArtCraft (apps Craft) y sus servidores MCP

CRAFT_APPS=(photocraft vectorcraft filmcraft lightcraft pdfcraft effectcraft designcraft
            figcraft soundcraft wordcraft gridcraft deckcraft solidcraft)
# the desktop id (and package name) of each app
appid() { case $1 in solidcraft) echo io.tangencylabs.solidcraft ;; *) echo "ai.storyteller.$1" ;; esac; }
[ "$(uname -m)" = x86_64 ] || { info "$(L "ArtCraft suite: x86_64 only here, skipped" "suite ArtCraft: aquí solo x86_64, se omite")"; return 0; }
HERE="$REDROG_ROOT/modules/artcraft"
if [ "$DRY_RUN" = 1 ]; then
  info "$(L "would set up [redrog-artcraft] and install" "configuraría [redrog-artcraft] e instalaría"): artcraft-launcher ${CRAFT_APPS[*]}"
  return 0
fi

# ── Packages ─────────────────────────────────────────────────────────────────
info "$(L "refreshing the local ArtCraft repository (the first time downloads ~800 MB)" \
          "actualizando el repositorio local de ArtCraft (la primera vez descarga ~800 MB)")"
run sudo bash "$HERE/repo/setup.sh"
# straight from the repository's folder: pacman -Sy alone would leave the rest
# of the system half-updated. Later updates come through the repository.
# --ask=4: replace the AUR artcraft-launcher, which the official one conflicts with
pkgs=()
for app in artcraft-launcher "${CRAFT_APPS[@]}"; do
  f=$(ls /var/lib/redrog-artcraft-repo/"$app"-[0-9]*-linux-x86_64.pkg.tar.zst 2>/dev/null | sort -V | tail -1)
  if [ -n "$f" ]; then pkgs+=("$f"); else warn "$(L "no package for $app in the repository" "no hay paquete de $app en el repositorio")"; fi
done
[ ${#pkgs[@]} -eq 0 ] || run sudo pacman -U --needed --noconfirm --ask=4 "${pkgs[@]}"

# AppImages of earlier versions, and their menu entries and icons (the
# packages bring their own under /usr/share)
removed=0
for app in "${CRAFT_APPS[@]}"; do
  for f in "$REAL_HOME/Applications/$app-"*-linux-*.AppImage "$REAL_HOME/Applications/$app-"*-linux-*.AppImage.zsync; do
    [ -e "$f" ] && { rm -f "$f"; removed=$((removed + 1)); }
  done
  d="$DATA_HOME/applications/ai.storyteller.$app.desktop"
  [ -f "$d" ] && grep -q '\.AppImage' "$d" && rm -f "$d"
  find "$DATA_HOME/icons/hicolor" -path '*/apps/*' -name "ai.storyteller.$app.*" -delete 2>/dev/null || true
done
[ "$removed" = 0 ] || info "$(L "$removed old AppImages removed" "$removed AppImages antiguas eliminadas")"
rmdir "$REAL_HOME/Applications" 2>/dev/null || true

# One updater: the launcher's own automatic updates would download every
# release a second time and install it with pacman -U behind pacman's back;
# it still shows new versions and installs new apps. Its settings are saved
# when it quits, so they change only while it is closed.
ron="$DATA_HOME/ai.storyteller.artcraft-launcher/app.ron"
if [ -f "$ron" ] && grep -q 'auto_update:true' "$ron"; then
  if pgrep -x artcraft-launch >/dev/null; then
    info "$(L "close the ArtCraft launcher and run this module again to leave its updates to pacman" \
              "cierra el lanzador de ArtCraft y vuelve a ejecutar este módulo para dejar sus actualizaciones a pacman")"
  else
    sed -i 's/auto_update:true/auto_update:false/' "$ron"
  fi
fi

# ── Control ports for the MCP servers ────────────────────────────────────────
# One port per app on 127.0.0.1, opened by the app itself when it starts.
# Every connection must prove it knows the app's secret: PhotoCraft and
# FilmCraft take theirs from the session (made at each login, kept only in
# the runtime folder: plasma-env.sh), the others make their own and write it
# to a file only the user can read.
envd="$CONFIG_HOME/environment.d"
conf="$envd/60-redrog-artcraft.conf"
mkdir -p "$envd"
port=7971
{
  echo "# RedRog (modules/artcraft): control port of each Craft app, for artcraft-mcp"
  for app in "${CRAFT_APPS[@]}"; do
    [ "$app" = pdfcraft ] && continue   # it has no live mode
    echo "${app^^}_CONTROL_PORT=$port"; port=$((port + 1))
  done
} > "$conf"
install -D -m 644 "$HERE/plasma-env.sh" "$CONFIG_HOME/plasma-workspace/env/redrog-artcraft.sh"
# for apps started before the next login too
# shellcheck disable=SC2046
run systemctl --user set-environment $(grep -v '^#' "$conf") >/dev/null 2>&1 || true
# the fixed token of the first versions is no longer in the session
run systemctl --user unset-environment PHOTOCRAFT_CONTROL_TOKEN FILMCRAFT_CONTROL_TOKEN >/dev/null 2>&1 || true

# ── Full power ───────────────────────────────────────────────────────────────
# The menu entries start each app on the discrete GPU (wgpu's high-performance
# adapter; on hybrid graphics other programs still leave it asleep), and
# FilmCraft with an empty project instead of its demo. Memory budgets and
# GPU paths sized for this machine (tune.py), and a KWin script so no Craft
# window opens larger than its screen.
for app in artcraft-launcher "${CRAFT_APPS[@]}"; do
  src=/usr/share/applications/$(appid "$app").desktop
  dst="$DATA_HOME/applications/$(appid "$app").desktop"
  [ -f "$src" ] || continue
  [ -f "$dst" ] || cp "$src" "$dst"
  sed -i -E '/^Exec=/{/WGPU_POWER_PREF/!s/^Exec=/Exec=env WGPU_POWER_PREF=high /}' "$dst"
  # inside redrog-artcraft.slice (with what the launcher opens from it)
  sed -i -E '/^Exec=/{/redrog-artcraft\.slice/!s/^Exec=/Exec=systemd-run --user --scope --quiet --collect --slice=redrog-artcraft.slice /}' "$dst"
  [ "$app" = filmcraft ] && sed -i -E '/^Exec=/{/--empty/!s/(filmcraft)( |$)/\1 --empty\2/}' "$dst"
  # SolidCraft takes its control port only as an option, not from the session
  [ "$app" = solidcraft ] && sed -i -E -e 's/ --control [0-9]+//' -e '/^Exec=/s/(solidcraft)( |$)/\1 --control '"$(sed -n 's/^SOLIDCRAFT_CONTROL_PORT=//p' "$conf")"'\2/' "$dst"
done
python3 -I "$HERE/tune.py" | sed 's/^/  /'
# The suite together: at most 75 % of the CPU threads and 75-80 % of the
# memory (redrog-artcraft.slice), and the GPU at 76 % while it runs
# (craft-gpu-cap, installed by repo/setup.sh), so the laptop stays usable
mkdir -p "$CONFIG_HOME/systemd/user"
sed "s/@CPUQUOTA@/$(( $(nproc) * 75 ))%/" "$HERE/redrog-artcraft.slice" > "$CONFIG_HOME/systemd/user/redrog-artcraft.slice"
run systemctl --user daemon-reload
S="$DATA_HOME/kwin/scripts/redrog-craft-fit"
rm -rf "$S"; mkdir -p "$(dirname "$S")"
cp -r "$HERE/redrog-craft-fit" "$S"
kw --file kwinrc --group Plugins --key redrog-craft-fitEnabled true
qdbus6 org.kde.KWin /Scripting org.kde.kwin.Scripting.unloadScript redrog-craft-fit >/dev/null 2>&1 || true
qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true

# ── MCP servers and skill ────────────────────────────────────────────────────
install -D -m 755 "$HERE/artcraft-mcp" "$REAL_HOME/.local/bin/artcraft-mcp"
for d in "$REAL_HOME/.claude/skills/artcraft" "$REAL_HOME/.gemini/config/skills/artcraft"; do
  install -D -m 644 "$HERE/skill/SKILL.md" "$d/SKILL.md"
done
mcp=0
for app in "${CRAFT_APPS[@]}"; do
  if has claude; then
    claude mcp remove -s user "$app" >/dev/null 2>&1 || true
    claude mcp add -s user "$app" -- "$REAL_HOME/.local/bin/artcraft-mcp" "$app" >/dev/null && mcp=$((mcp + 1))
  fi
  if has agy; then
    agy mcp add "$app" "$REAL_HOME/.local/bin/artcraft-mcp" "$app" >/dev/null && mcp=$((mcp + 1))
  fi
done
run kbuildsycoca6 >/dev/null 2>&1 || true
info "$(L "ArtCraft suite: ${#CRAFT_APPS[@]} apps, $mcp MCP registrations (Claude Code, agy)" \
          "suite ArtCraft: ${#CRAFT_APPS[@]} apps, $mcp registros MCP (Claude Code, agy)")"
