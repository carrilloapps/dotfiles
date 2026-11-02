# Maintenance Guide

This document details routine system maintenance procedures, cache management, dependency updates, local package builds, and release workflows for RedRog.

---

## 1. System Maintenance Utility (`redrog-mantenimiento`)

RedRog provides an integrated maintenance tool accessible from application launchers as **"Maintenance"** (or **"Mantenimiento"** in Spanish), and executable directly from the terminal:

```bash
redrog-mantenimiento
```

The utility runs within a dedicated kitty terminal session styled in the active theme palette and provides interactive routines for disk cleanup, performance diagnostics, and software updates.

### Disk Space Reclamation
The utility systematically purges accumulated caches without impacting system stability:

- **Package Manager Caches:** Prunes pacman and AUR build caches, retaining only the two most recent package versions (`paccache -rk2`) and completely purging uninstalled package archives (`paccache -ruk0`).
- **Shader and Graphical Caches:** Reclaims disk space from obsolete OpenGL, Vulkan, Mesa, and NVIDIA shader caches, as well as desktop thumbnails (`~/.cache/thumbnails`).
- **Systemd Journal and Core Dumps:** Vacuums systemd journal logs to a maximum footprint of 200 MB (`journalctl --vacuum-size=200M`) and removes expired coredump crash archives (`coredumpctl`).
- **Orphaned Packages:** Detects and removes unneeded packages installed as dependencies that are no longer required (`pacman -Qtdq`).
- **Developer and Toolchain Caches:** Reclaims disk space from Rust (`cargo/registry`), Node.js (`npm`, `pnpm`, `yarn`), Python (`pip`, `uv`), Go build caches, and Gradle artifacts.
- **AI Agent Artifacts:** Cleans up orphaned context files, ephemeral session dumps, and prompt caches across Claude Code (`~/.claude/`) and Antigravity (`~/.gemini/antigravity-cli/`).
- **Btrfs Snapshots:** Inspects and trims aging system snapshots managed by Snapper on CachyOS / Arch installations.
- **Deep Cleaning Integration:** Provides seamless launching of BleachBit and Czkawka GUI for deduplication and deep file analysis.

### Performance and Hardware Health Diagnostics
- **ASUS Firmware State:** Audits the active `asusd` power profile, battery charge threshold, and fan curves (`asusctl profile -p`, `asusctl status`).
- **Thermal and Acoustic Readings:** Inspects real-time CPU core temperatures, NVIDIA dGPU temperature, and fan tachometer speeds.
- **Resource Consumers:** Identifies the top CPU- and RAM-consuming processes across user and system scopes.
- **Systemd Service Health:** Audits system and user systemd units for failed services (`systemctl --failed`, `systemctl --user --failed`).
- **Boot Optimization Analysis:** Measures startup duration and displays the critical boot chain (`systemd-analyze`, `systemd-analyze blame`, `systemd-analyze critical-chain`).

---

## 2. Upstream Subtree Maintenance (Arc KDE)

The base styling assets in `vendor/arc-kde` are tracked as a Git subtree from the upstream Papirus Development Team repository.

To pull upstream updates into the subtree:

```bash
git subtree pull --prefix vendor/arc-kde \
    https://github.com/PapirusDevelopmentTeam/arc-kde.git master --squash
```

### Post-Pull Verification
Because RedRog's tweak scripts (`modules/kvantum/tweaks.py`, `modules/plasma-style/translucent.py`, and `lib/recolor.py`) rely on exact asset filenames and directory structures within Arc KDE, verify compatibility immediately after pulling updates:

```bash
# 1. Run dry-run verification
./install.sh --dry-run

# 2. Recompile and inspect the theme
./install.sh --only colors,plasma-style,kvantum,window-decoration
```

Examine the color scheme, Kvantum widget borders, and Aurorae traffic light buttons to confirm that upstream file renaming has not broken asset transformations.

---

## 3. Maintaining Patched Local Packages (`packages/`)

RedRog maintains dedicated PKGBUILDs in `packages/` to address upstream bugs, Plasma 6.8 compatibility issues, and custom UI enhancements. All packages are tracked in `packages/local.txt`:

| Package Directory | Upstream Base / Purpose | Patch Details & Maintenance Notes |
|---|---|---|
| `packages/arc-gtk-theme` | `arc-gtk-theme` | Repackages the GTK 2/3/4 theme, injects RedRog palette variables, and rebuilds `gtk.gresource`. |
| `packages/appgrid` | `appgrid` | Resolves Plasma 6.8 breakages by eliminating the deprecated `Applet::globalConfig()` API. |
| `packages/rog-control-center` | `asusctl` / `rog-control-center` | Implements RedRog glass styling, redesigned navigation sidebar, and multi-language gettext support. |
| `packages/kwin-effect-redrog-glass` | Custom KWin shader | Native frosted glass shader compiled against current KWin Wayland headers. |
| `packages/obs-move-transition` | `obs-move-transition` | Patched to compile against the latest OBS Studio API headers. |
| `packages/plasma6-applets-supergfxctl`| `supergfxctl-plasmoid` | Modernized for Qt 6.12 and Plasma 6.8 Plasmoid APIs. |
| `packages/kwin-effects-better-blur-dx`| `better-blur-dx` | High-efficiency dual-cavity blur shader compiled against current KWin headers. |
| `packages/kwin-effect-rounded-corners-git` | `kwin-effect-rounded-corners` | Client window corner rounding shader compiled against current KWin headers. |
| `packages/qm-vamp-plugins` | Queen Mary Vamp Plugins | Audio analysis plugins built for Audacity 4 integration. |
| `packages/audacity4-bin` | Audacity 4 (Qt 6) | Desktop launcher integration, RedRog palette theming, and system command wrappers. |

### PKGBUILD Update Workflow
When an upstream package issues a new release:

1. Navigate to the package directory:
   ```bash
   cd packages/<package-name>
   ```
2. Update `pkgver` and reset `pkgrel=1` in `PKGBUILD`.
3. Update source checksums:
   ```bash
   updpkgsums
   ```
4. Verify whether local patch files (`*.patch`) still apply cleanly. If upstream has merged the fix, remove the patch file and drop it from the `prepare()` function.
5. Build and install the updated package:
   ```bash
   makepkg -si
   ```
6. Commit changes to git and update `CHANGELOG.md`.

---

## 4. ArtCraft Local Repository Maintenance

The 12 ArtCraft creative applications and SolidCraft are distributed via a local pacman repository hosted at `/var/lib/redrog-artcraft-repo`.

### Architecture and Security
- **Synchronization Service:** Managed by the systemd unit `redrog-artcraft-repo.service` and triggered automatically every 6 hours by `redrog-artcraft-repo.timer`.
- **Privilege Isolation:** The synchronization service runs under the unprivileged dedicated system user `redrog-artcraft`.
- **Cryptographic Verification:** Upstream packages downloaded from GitHub releases are validated against `SHA256SUMS.txt` over HTTPS before they are admitted into the repository database.
- **Repository Database:** Packages are indexed using `repo-add -s /var/lib/redrog-artcraft-repo/redrog-artcraft.db.tar.zst`.

### Manual Synchronization and Verification
To trigger an immediate repository update and verify package ingress:

```bash
# Trigger manual sync
sudo systemctl start redrog-artcraft-repo.service

# Inspect service logs
journalctl -u redrog-artcraft-repo.service -n 50 --no-pager

# Refresh pacman database
sudo pacman -Sy
```

---

## 5. Plasma 6 and KWin Upgrade Lifecycle

KWin effects that operate as C++ plugins (`kwin-effect-rounded-corners-git` and `kwin-effects-better-blur-dx`) bind directly to internal KWin symbols. When Arch Linux or CachyOS upgrades the `kwin` package across minor or major versions, these plugins must be recompiled.

### Rebuilding KWin Effects
If window corners appear squared or frosted blur disables following a system update:

```bash
# Rebuild rounded corners shader
paru -S --rebuild kwin-effect-rounded-corners-git

# Rebuild Better Blur DX shader
paru -S --rebuild kwin-effects-better-blur-dx
```

### Invalidation of QML Cache
Plasma caches compiled QML files in user cache directories. Whenever plasmoids are updated or modified:

```bash
rm -rf ~/.cache/plasmashell/qmlcache
systemctl --user restart plasma-plasmashell
```

---

## 6. EasyEffects Presets and Audio Calibration

Acoustic presets for laptop speakers, headsets, and microphones are maintained in `modules/audio/` and `config/audio/`.

### Restoring Factory Presets
Working presets installed in `~/.local/share/easyeffects/output/` are marked read-only to prevent accidental parameter alterations. Pristine reference copies are stored in `~/.local/lib/redrog/audio/`.

If an audio profile is inadvertently modified or corrupted:

```bash
# Re-apply factory presets
./install.sh --only audio
```

Alternatively, select **"Restore speaker sound"** from the desktop application menu. For background acoustic measurements and calibrated target curves, see [docs/research/jbl-bass-eq.md](research/jbl-bass-eq.md).

---

## 7. Hardware Tuning Management (`hosts/asus-tuf-f15/`)

Machine-specific firmware calibrations are isolated in `hosts/asus-tuf-f15/`.

### Configuration Capture Workflow
To synchronize working hardware settings, power limits, and system overrides back into the host snapshot:

```bash
hosts/asus-tuf-f15/scripts/capture.sh
```

This updates:
- `hosts/asus-tuf-f15/system/etc/asusd/asusd.ron` (custom power profiles and fan curves)
- `hosts/asus-tuf-f15/manifest.txt` (inventory of tracked machine configuration paths)

### Configuration Restoration Workflow
To restore hardware settings on the target machine:

```bash
hosts/asus-tuf-f15/scripts/restore.sh
sudo hosts/asus-tuf-f15/scripts/apply-asusd.sh
```

For detailed thermal benchmarks and firmware power limits, refer to [hosts/asus-tuf-f15/README.md](../hosts/asus-tuf-f15/README.md) and [docs/research/asus-tuf-f15-thermals.md](research/asus-tuf-f15-thermals.md).

---

## 8. Internationalization and Catalog Maintenance

When new translatable strings are introduced to RedRog shell scripts, Python daemons, or QML applets:

### 1. Update Template Catalogs (`.pot`)
Regenerate portable object templates:

```bash
# Core RedRog notifications and daemons
xgettext -L Python -d redrog -o i18n/redrog/redrog.pot \
    modules/rog-notify/redrog-rog-notify.py

# Telemetry dashboard plasmoid
xgettext -L QML -o i18n/batterypercent/plasma_applet_org.redrog.batterypercent.pot \
    modules/layout/org.redrog.batterypercent/contents/ui/*.qml
```

### 2. Merge Existing Translations (`.po`)
Merge updated template catalogs into localized `.po` files:

```bash
msgmerge -U i18n/redrog/es.po i18n/redrog/redrog.pot
msgmerge -U i18n/batterypercent/es.po i18n/batterypercent/plasma_applet_org.redrog.batterypercent.pot
```

### 3. Compile Binary Catalogs (`.mo`)
Compile `.po` files into binary `.mo` catalogs and deploy them:

```bash
./install.sh --only rog-notify,layout
```

---

## 9. Release Workflow

Follow these steps when tagging a new release:

1. **Review and Update Documentation:** Ensure all new modules, configuration variables, and options are documented in [docs/INSTALL.md](INSTALL.md), [docs/ARCHITECTURE.md](ARCHITECTURE.md), and [docs/CUSTOMIZE.md](CUSTOMIZE.md).
2. **Update Changelog:** Move items from `[Unreleased]` into the target version section in `CHANGELOG.md` along with the release date.
3. **Verify Dry-Run Execution:**
   ```bash
   ./install.sh --dry-run --layout
   ```
4. **Clean Session Verification:** Test the deployment on a clean user account to verify automated package resolution, panel layout building, and theming.
5. **Git Tagging:**
   ```bash
   git add -A
   git commit -m "Release vX.Y.Z"
   git tag -a vX.Y.Z -m "RedRog vX.Y.Z"
   git push origin main --tags
   ```

---

## 10. Related Documentation

- **Installation Guide:** [docs/INSTALL.md](INSTALL.md)
- **Architecture Specification:** [docs/ARCHITECTURE.md](ARCHITECTURE.md)
- **Customization Guide:** [docs/CUSTOMIZE.md](CUSTOMIZE.md)
- **Troubleshooting Manual:** [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Hardware Thermals Research:** [docs/research/asus-tuf-f15-thermals.md](research/asus-tuf-f15-thermals.md)
- **Acoustic Calibration Research:** [docs/research/jbl-bass-eq.md](research/jbl-bass-eq.md)
