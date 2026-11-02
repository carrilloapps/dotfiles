# Installation Guide

RedRog is applied through `install.sh`, a modular installer that configures and styles your desktop environment. The installation is non-destructive and follows a clean copy-and-generation architecture: configuration files and assets are generated or copied directly into your user environment (`~/.config`, `~/.local`), without fragile symlinks back to the source tree. Consequently, the repository can reside anywhere on your filesystem (`~/.dotfiles` is recommended).

> [!IMPORTANT]
> **Never run `install.sh` with `sudo`.**
> The installer executes as your unprivileged user. Any specific operations that require root privileges (such as package installation with `--packages` or system-level theming with `--system`) will explicitly prompt for `sudo` authentication only when necessary.

---

## 0. Prerequisites and System Requirements

| Requirement | Specification & Notes |
|---|---|
| **Display Server & Desktop** | KDE Plasma 6 on Wayland (tested on Plasma 6.8, KWin 6.8, and Qt 6.12) |
| **Operating System** | Arch Linux or Arch-based distributions (tested and tuned on CachyOS; for other distributions, install equivalent packages manually) |
| **Version Control** | `git` (to clone and update the repository) |
| **AUR Helper** | `paru` or `yay` (required for automated dependency resolution via `./install.sh --packages`) |
| **Hardware (Optional)** | ASUS TUF / ROG laptops: `asusd`/`asusctl`, `supergfxctl`, and ROG Control Center unlock dedicated power profiles, fan curves, and telemetry |
| **Bootloader (Optional)** | Limine (enables themed, high-contrast, black-background bootloader menus via `--system`) |
| **Display Manager (Optional)** | Plasma Login Manager / SDDM (enables cohesive lock screen and greeter styling via `--system`) |

### Automated Bootstrap (One-Liner)

To automatically verify prerequisites, clone the repository into `~/.dotfiles`, and run the complete installation in a single step:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/carrilloapps/dotfiles/main/bootstrap.sh)"
```

### Manual Installation

Alternatively, clone the repository manually with `git`:

```bash
git clone https://github.com/carrilloapps/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

*(If you maintain your own fork, substitute your GitHub repository URL above).*

To execute a complete installation with all dependencies, desktop layouts, and system configurations:

```bash
./install.sh --all
```

For controlled, modular deployments, follow the step-by-step instructions below.

---

## 1. Package Dependencies

Install the required software stack:

```bash
./install.sh --packages
```

The dependency resolution pipeline executes in four sequential stages:

1. **Official Repositories:** Installs packages listed in `packages/pacman.txt` using `pacman`.
2. **Arch User Repository (AUR):** Installs packages listed in `packages/aur.txt` using `paru` or `yay` (skipped with a warning if neither helper is detected).
3. **Local PKGBUILDs:** Builds and installs patched packages located in `packages/local.txt` using `makepkg -si`. These packages address upstream bugs or provide customized features (see their respective `README.md` files in `packages/`).
4. **Folder Icon Coloring:** Applies the RedRog accent color to Papirus folder icons using `papirus-folders`.

### Core Package Breakdown

| Package | Source | Role and Integration |
|---|---|---|
| `kvantum`, `darkly` | Official / AUR | Qt application styling engine with frosted glass, rounded controls, and live light/dark switching |
| `papirus-icon-theme`, `papirus-folders` | Official / AUR | Base icon theme and script to apply the crimson folder accent |
| `inter-font` | Official | Primary user interface typeface across Plasma, GTK, and web browsers |
| `ttf-jetbrains-mono-nerd` | Official | Monospace typeface for kitty, Neovim, terminal glyphs, and tab indicators |
| `kitty` | Official | Primary GPU-accelerated terminal emulator with custom tab bars and agent integrations |
| `wl-clipboard` | Official | Wayland clipboard integration for terminal utilities and AI agent CLIs (Claude Code, Antigravity) |
| `imagemagick`, `python-pillow` | Official | Dynamic wallpaper generation, blur processing, and icon synthesis |
| `python-gobject` | Official | D-Bus integration for the ASUS notification daemon and global shortcut helpers |
| `xdg-user-dirs` | Official | Standardized user directory integration (e.g., Downloads folder pinned to the dock) |
| `gettext` | Official | Runtime compilation of internationalization catalogs across all RedRog components |
| `cava`, `plasma6-applets-kurve-git` | Official / AUR | Desktop audio visualizer engine and plasmoid (*RedRog Spectrum*) |
| `easyeffects`, `calf`, `lsp-plugins-lv2`, `deepfilternet-ladspa` | Official | System-wide PipeWire audio DSP pipeline (speaker tuning, calibrated JBL headphone EQ, AI microphone noise suppression) |
| `apple_cursor` | AUR | High-DPI macOS cursor theme |
| `plasma6-applets-panel-colorizer` | AUR | Adaptive top menubar transparency/frosting and translucent floating dock |
| `kwin-effect-rounded-corners-git` | Local / AUR | Native GPU-accelerated rounded window corners under KWin Wayland |
| `kwin-effects-better-blur-dx` | Local / AUR | High-performance dual-cavity blur for Plasma QML windows, System Settings, and ROG Control Center |
| `supergfxctl`, `plasma6-applets-supergfxctl` | AUR / Local | Dynamic GPU mode switching (Integrated, Hybrid, Dedicated) with tray integration |
| `arc-gtk-theme` | Local PKGBUILD | Base GTK 2/3/4 theme recolored to match the RedRog palette |
| `appgrid` | Local PKGBUILD | Fullscreen macOS Launchpad-style application grid triggered by `Alt+Space` (patched for Plasma 6.8) |
| `rog-control-center-redrog` | Local PKGBUILD | ROG Control Center with translucent glass styling, macOS-inspired sidebar, and multi-language support |
| `obs-studio-browser`, `obs-vkcapture` | Official | OBS Studio with hardware-accelerated Vulkan/OpenGL game capture and NVENC streaming profiles |
| `audacity4-bin` | Local PKGBUILD | Qt 6-based Audacity 4 styled in the RedRog palette with studio LV2 plugins |

### Optional Enhancements

| Package | Functionality |
|---|---|
| `asusctl`, `rog-control-center` | ROG power profiles, battery charge thresholds, and Aura RGB keyboard lighting management |
| `limine`, `limine-mkinitcpio-hook` | Themed bootloader menu with high-contrast palette and kernel verification hooks (`--system`) |
| `plymouth-theme-arch-charge-big` | Animated boot splash screen integrated into the boot sequence (`--system`) |
| `plasma-login-manager` | System-wide unified login screen matching user wallpaper and color scheme (`--system`) |

---

## 2. Desktop Theming and Modules

Apply the desktop theme and user configurations:

```bash
./install.sh            # Applies desktop theming while preserving existing panel layouts
./install.sh --layout   # Applies desktop theming AND reconstructs the macOS-style top bar and dock
```

> [!WARNING]
> Using `--layout` **replaces all panels** in the current Plasma session with RedRog's unified macOS-style top bar and floating dock. Any custom widgets previously placed on panels will be removed. Take a screenshot or note your widget layout before running `--layout` if you intend to recreate custom applets.

### Module Execution Order

Modules execute in a deterministic pipeline defined in `MODULES`. Each module is self-contained and idempotent:

| Order | Module | Scope and Functionality |
|---|---|---|
| 01 | `colors` | Generates and applies `RedRog.colors` scheme, setting primary window backgrounds, surfaces, and accent colors |
| 02 | `plasma-style` | Configures Plasma desktop styling (translucent dialogs, popups, tooltips, and macOS-style dock indicators) |
| 03 | `kvantum` | Builds and applies the Kvantum Qt style: rounded buttons, translucent windows, and refined list selections |
| 04 | `window-decoration` | Configures Aurorae window decorations with traffic-light control buttons and rounded corner geometry |
| 05 | `gtk` | Generates GTK 2/3/4 themes and Firefox menu styling matching the active palette |
| 06 | `appearance` | Sets Papirus icons, Inter interface font, JetBrains Mono font, Apple cursor, and enables NumLock on login |
| 07 | `terminal` | Configures kitty: GPU acceleration, macOS-style tabs, custom tab bar wrapper, and contextual right-click menu |
| 08 | `firefox` | Installs custom `user.js`, `userChrome.css`, and `userContent.css` (existing files backed up with `.before-redrog`) |
| 09 | `chrome` | Applies the RedRog dark/light color palette and styling to Google Chrome |
| 10 | `spotify` | Deploys Spicetify theme matching the RedRog palette |
| 11 | `notifications` | Configures top-right notification banners and integrates notification history with the top bar bell widget |
| 12 | `rog-notify` | Background D-Bus service displaying native, localized ASUS hardware state notifications (requires `asusd`) |
| 13 | `asus-laptop` | Configures hybrid graphics Xwayland power wrapper to ensure the NVIDIA dGPU sleeps when idle; maps Armoury key |
| 14 | `global-theme` | Registers the RedRog global theme package, sets desktop and lock screen wallpapers, and disables splash lag |
| 15 | `visualizer` | Deploys *RedRog Spectrum*: desktop audio visualizer (halo or bottom bars) via Kurve and cava |
| 16 | `audio` | Configures EasyEffects 8 audio DSP: speaker psychoacoustic compensation, headphone preset memory, and mic filters |
| 17 | `audacity` | Configures Audacity 4 with RedRog palette themes (dark and light variants) and audio studio plugins |
| 18 | `obs` | Configures OBS Studio: RedRog theme, NVENC hardware encoding profiles, and Hybrid MP4 crash-resilient output |
| 19 | `steam` | Optimizes Steam for hybrid graphics laptops: offloading games to dGPU, 12 GB shader cache, and NVAPI/DLSS |
| 20 | `dolphin` | Finder-style file manager: clean sidebar spacing, full-width tabs, and macOS-style scrollbars and status bars |
| 21 | `hud` | Places the desktop telemetry hologram (CPU, GPU, RAM, fan RPM readings) |
| 22 | `apps` | Applies application fixes: Octopi Spanish localization fallback, hiding non-app launchers, setting default apps |
| 23 | `artcraft` | Installs ArtCraft creative suite, registers MCP servers in Claude Code and Antigravity, sets resource limits |
| 24 | `thunderbird` | Styles Mozilla Thunderbird to mirror the clean layout of macOS Mail |
| 25 | `touchpad` | Configures Mac-like gestures (natural scrolling, multi-finger desktop switching, dynamic desktop spaces) |
| 26 | `keyboard` | Configures dual keyboard layouts (LatAm Spanish & US English) with dynamic auto-switching per connected device |
| 27 | `theme-switch` | Deploys the instant Light/Dark theme switcher in the system tray (`redrog-theme-switch`) and APCA menubar veil |
| 28 | `maintenance` | Installs the "Maintenance" system cleanup and diagnostics utility in the application menu (`redrog-mantenimiento`) |
| 29 | `layout` | Rebuilds the desktop layout: top menubar, clock, battery telemetry panel, floating dock, and AppGrid (`--layout`) |
| 30 | `system` | Root-level configurations: Limine boot menu, SDDM greeter sync, network performance, ROG translations (`--system`) |

To execute specific modules without running the full suite:

```bash
./install.sh --only gtk,terminal,audio
```

---

### Key Feature Highlights

#### ArtCraft Suite and AI Agent MCP Integration

Every application in the ArtCraft suite features a dedicated Model Context Protocol (MCP) server registered in both **Claude Code** and **Antigravity** (`agy`) via `~/.local/bin/artcraft-mcp`:

- **Dual Operating Modes:** When an application is running with an open window, the MCP server connects live to its local control port (`127.0.0.1`, configured in `~/.config/environment.d/60-redrog-artcraft.conf`) authenticated by a secure session token generated at login in `$XDG_RUNTIME_DIR`. When the application is closed, the server runs the application's headless engine with sandbox access restricted to your home directory.
- **Resource Containment:** ArtCraft apps and their MCP engines execute inside a dedicated systemd slice (`redrog-artcraft.slice`) constrained to at most 75% CPU and 75–80% RAM. An automated GPU service (`redrog-craft-gpu.service`) caps GPU power draw to 76% during heavy processing to ensure system responsiveness.
- **Automated Local Repository:** Official Arch packages for the 12 Craft applications and SolidCraft (3D parametric CAD) are served from a local pacman repository at `/var/lib/redrog-artcraft-repo`, synchronized via `redrog-artcraft-repo.timer` every 6 hours with cryptographic verification against `SHA256SUMS.txt`.

#### The RedRog Telemetry Dashboard

Clicking the battery percentage widget in the top menubar opens the RedRog telemetry dashboard:

- **Hardware Sensors:** Live per-core CPU equalizer (distinguishing Intel P-cores and E-cores via sysfs), GPU clock and power telemetry, battery discharge rate and estimated runtime, fan speeds, RAM and swap utilization, storage space, and network throughput.
- **Hardware Controls:** Instant switching of ASUS ROG power profiles (Quiet, Balanced, Performance), GPU operation modes (via `supergfxctl`), and battery charge thresholds (e.g., 80% battery care limit) with visual busy indicators.
- **Zero-Wakeup Optimization:** The panel executes `nvidia-smi` only when the discrete NVIDIA GPU is already awake, preventing power drain from unnecessary dGPU wakeups.
- **Minimal View:** A header toggle collapses the dashboard into compact telemetry rings, power profile buttons, and essential metrics.

#### Advanced Terminal Architecture

The kitty terminal is configured as the default desktop terminal emulator:

- **Custom macOS-Style Tabs:** Styled tab bar displaying title, close buttons, and activity status dots.
- **Contextual Right-Click Menu:** Right-clicking inside kitty launches the RedRog Qt menu (`redrog-kitty-menu`), offering clipboard operations, window splits (horizontal/vertical), zoom, layout rotations, directory navigation in Dolphin, and one-click launching of installed AI agent CLIs (Claude Code, Antigravity, Codex, Gemini CLI, OpenCode, Aider). Hold `Shift` while right-clicking when inside mouse-capturing TUI applications (Vim, htop).
- **Extensible Configuration:** Personal overrides can be placed directly at the bottom of `~/.config/kitty/kitty.conf` without being overwritten by future updates.

#### Calibrated Audio and Psychoacoustic DSP

The audio pipeline utilizes EasyEffects 8 to significantly enhance sound quality:

- **Laptop Speakers:** The "RedRog Laptop Speakers" preset uses psychoacoustic bass harmonics, low-mid resonance enhancement, and multiband limiting to deliver rich audio from compact laptop drivers.
- **Per-Device Memory:** Output presets are managed by `redrog-audio-memory`. Connecting headphones or external DACs automatically loads their respective presets (or "RedRog Neutral"), returning to the speaker preset when disconnected.
- **Headphone EQ:** Pre-configured profiles (such as calibrated Harman-target bass shelves for the JBL Quantum 350) are installed in `config/audio/`. See [docs/research/jbl-bass-eq.md](research/jbl-bass-eq.md).
- **Microphone Filtering:** Integrates DeepFilterNet deep-learning neural noise suppression for studio-grade voice clarity without background fan noise.

---

## 3. System Configuration (Root Privileges)

To apply system-wide optimizations and bootloader styling:

```bash
./install.sh --system
```

This runs `modules/system` as root and performs the following tasks:

1. **Limine Bootloader Theming:** Installs a high-contrast theme on pure black (`#000000`) with accent branding. Configurations are placed cleanly between `# >>> REDROG` and `# <<< REDROG` markers in `/etc/limine.conf`. Boot entry counts are validated before and after modification, and hashes are automatically re-enrolled using `limine-enroll-config` when available. A dedicated pacman hook (`zz-redrog-limine.hook`) re-applies configurations after kernel or bootloader updates.
2. **Plasma Login Manager (SDDM):** Deploys the RedRog color scheme, Kvantum style, cursor theme, and user wallpaper to `/usr/share/wallpapers/RedRog` and configures `/etc/plasmalogin.conf` so the login greeter seamlessly matches the desktop aesthetic.
3. **Boot Performance:** Disables `NetworkManager-wait-online.service` to reduce boot times by eliminating unnecessary network blocking during early startup.
4. **ROG Control Center Translations:** Installs multi-language gettext catalogs into system locales.

System configuration backups are automatically archived in `/var/backups/redrog/<timestamp>/`.

---

## 4. Post-Installation Verification

Log out of your desktop session and log back in to reload KWin, Kvantum, and system services. Restart web browsers to apply custom user interface styles.

Verify the installation using the following checklist:

| Verification Item | Test Action | Expected Result |
|---|---|---|
| **Top Menubar** | Inspect top edge of screen | Clear transparency over wallpaper; frosted background when a window is maximized |
| **Menubar Legibility** | Switch wallpaper or light/dark mode | Menubar text and icons dynamically adjust contrast (white with drop shadow or black) |
| **AppGrid** | Press `Alt+Space` | Fullscreen macOS-style application launcher opens |
| **Telemetry Dashboard** | Click battery percentage in top bar | RedRog dashboard opens showing live CPU, GPU, memory, and power telemetry |
| **Terminal Integration** | Press `Ctrl+Alt+T` | kitty terminal opens with macOS-style tabs; right-click opens the RedRog action menu |
| **Audio Processing** | Run `easyeffects -a output` | Active preset shows `RedRog Laptop Speakers` on internal speakers, neutral on headphones |
| **Desktop Visualizer** | Play music or video | Audio visualizer halo or spectrum bars animate smoothly on the desktop background |
| **Dynamic Gestures** | Swipe 3 fingers left/right on touchpad | Smoothly transitions between virtual desktops |

---

## 5. Hardware Tuning and Reference Hosts

The `hosts/<model>/` directory contains specialized hardware tuning scripts and configurations for specific laptop platforms.

For the **ASUS TUF Gaming F15 (FX507ZC4)** (Intel Core i5-12500H, NVIDIA RTX 3050 Laptop):

```bash
sudo hosts/asus-tuf-f15/scripts/apply-asusd.sh
```

This applies optimized firmware power limits (Quiet: 30W/45W, Balanced: 55W/95W, Performance: 80W/115W), calibrated fan curves, and an 80% battery charge lifespan limit.

> [!CAUTION]
> Hardware-specific scripts in `hosts/` strictly verify the machine's DMI product name before execution and will refuse to run on different laptop models to prevent hardware damage. For technical architecture details and thermal research, refer to [hosts/asus-tuf-f15/README.md](../hosts/asus-tuf-f15/README.md) and [docs/research/asus-tuf-f15-thermals.md](research/asus-tuf-f15-thermals.md).

---

## 6. Uninstallation and Rollback

To revert desktop theming back to default KDE Breeze Dark while preserving your existing panel layouts:

```bash
./uninstall.sh
```

To revert desktop theming and reset panels back to the default Plasma desktop layout:

```bash
./uninstall.sh --reset-layout
```

Installed packages, personal user files in `~/.dotfiles`, and `/boot` configurations remain intact.
