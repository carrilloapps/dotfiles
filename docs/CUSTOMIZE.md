# Customization Guide

RedRog is designed to be fully customizable without modifying tracked repository files. All personal preferences, hardware overrides, palette changes, and application lists belong in `config/user.conf`, which takes precedence over `config/redrog.conf` and is ignored by git:

```bash
cp config/user.conf.example config/user.conf
```

After modifying `config/user.conf`, re-run the installer to apply changes:

```bash
./install.sh            # Re-applies configuration overrides
./install.sh --layout   # Include --layout if you modified DOCK_APPS or panel structures
```

---

## 1. Wallpapers

Define custom wallpapers for the dark and light desktop variants:

```bash
WALLPAPER="$HOME/Pictures/Wallpapers/my-wallpaper.jpg"
LIGHT_WALLPAPER="$HOME/Pictures/Wallpapers/my-light-wallpaper.jpg"   # Optional light variant image
```

### Installation and Synchronization
Each specified image is processed and installed into `~/.local/share/wallpapers` under dedicated package names ("RedRog" and "RedRog Light"). These wallpapers are automatically assigned to:
- Primary and secondary desktop screens
- The lock screen
- The Plasma Login Manager (SDDM) greeter (via `./install.sh --system`)
- The blurred background canvas of the Limine bootloader menu

When switching between Dark and Light variants, RedRog dynamically updates the active wallpaper across all connected displays and synchronizes the lock screen with your primary monitor. Any display where you manually selected a different wallpaper through Plasma's native settings dialog is respected and left untouched.

If `WALLPAPER` is left empty, the installer falls back to the clean, recolored Arc Dark baseline wallpaper.

---

## 2. Light and Dark Desktop Variants

RedRog provides two parallel themes engineered from identical geometric specifications:

- **RedRog (Dark):** Built on deep neutral grays (`#1c1c1c` window backgrounds, `#252524` surfaces) with high-visibility crimson accents (`#ef3340`).
- **RedRog Light:** Built on calibrated Pantone Cloud Dancer whites (`#ffffff` window backgrounds, `#f6f4f0` surfaces) with Pantone 1795 C crimson accents (`#d62828`) and Pantone Red 032 C hover highlights.

Both variants are installed side-by-side during setup, complete with dedicated color schemes, Plasma styles, Kvantum themes, Aurorae window decorations, and GTK themes ("RedRog" and "RedRog Light" in *System Settings → Colors / Global Theme*).

### Instant Switching
Switch themes on the fly from the sun/moon widget in the system tray, or via the command line:

```bash
redrog-theme-switch light      # Instantly switch to the light theme variant
redrog-theme-switch dark       # Instantly switch to the dark theme variant
redrog-theme-switch toggle     # Toggle between dark and light variants
redrog-theme-switch auto       # Automatically follow Plasma's Night Light sunrise/sunset schedule
redrog-theme-switch status     # Display currently active variant and scheduling mode
```

Theme switching executes in under a second without requiring asset recompilation:
- Plasma global theme, accent colors, and widget styles update instantly.
- Kvantum and Darkly Qt styles switch active palettes live.
- GTK 2/3/4 applications, kitty, Spotify (via Spicetify), and OBS Studio update immediately.
- Web browsers (Firefox, Chrome), Thunderbird, and Audacity 4 adhere to the desktop light/dark signal automatically.
- Any open Qt widgets update their frame palettes; internal Kvantum styling reloads seamlessly upon restarting the application.

### Dynamic Menubar Contrast and the APCA Veil
Under Wayland, the top menubar adopts macOS-style adaptive transparency over your desktop wallpaper. When no window is maximized, the bar is completely clear. Rather than relying on a static text color, `redrog-panel-veil` continuously measures the linear relative luminance ($Y$) of the wallpaper strip directly beneath the menubar:

- **Over dark wallpaper areas:** Menubar text and tray icons render in crisp white with a subtle dark drop shadow.
- **Over bright wallpaper areas:** Menubar text and tray icons render in solid black without halos.
- **Over mid-range or busy wallpaper backgrounds:** A calibrated, translucent dark veil is applied beneath the bar, calculated to guarantee an APCA (Advanced Perceptual Contrast Algorithm) rating of at least **Lc 60**, ensuring continuous legibility across complex wallpapers.

When any window is maximized, the menubar seamlessly transitions to a frosted, blurred glass texture in the active variant's surface tone. For complete mathematical models and empirical legibility studies, refer to [docs/research/macos-menubar-legibility.md](research/macos-menubar-legibility.md).

---

## 3. Color Palettes

Palette definitions are expressed as six-digit hex codes without the `#` prefix.

### Master Dark Palette Variables

| Variable | Default Hex | Semantic Usage |
|---|---|---|
| `ACCENT` | `ef3340` | Primary accent: selections, focus rings, links, slider tracks, active folder icons |
| `ACCENT_ALT` | `f8485e` | Hover highlights, active control states, and bright visual indicators |
| `BG` | `1c1c1c` | Window backgrounds, modal dialog backdrops, and viewport surfaces |
| `SURFACE` | `252524` | Container elements, sidebars, text inputs, card backgrounds, and docks |
| `SURFACE_HI` | `313131` | Interactive buttons, section headers, hovering list items, and tab tracks |
| `SELECTION` | `2b2b2a` | Highlighted list items, active menu rows, and table selections |
| `FG` | `efeeeb` | Primary typography and high-contrast icon foregrounds |
| `FG_DIM` | `888680` | Secondary typography, metadata labels, placeholders, and inactive controls |
| `KEYBOARD_COLOR` | `da291c` | ASUS Aura RGB keyboard backlight LED target color |
| `ICON_FOLDER_COLOR`| `red` | Papirus folder icon color (must match a valid `papirus-folders -l` value) |

### Master Light Palette Variables
To customize the light variant, override corresponding variables with the `LIGHT_` prefix in `config/user.conf` (e.g., `LIGHT_BG`, `LIGHT_SURFACE`, `LIGHT_ACCENT`, `LIGHT_FG`).

---

## 4. Dock and App Launcher Configuration

Specify pinned applications on the macOS-style floating dock using the `DOCK_APPS` array:

```bash
DOCK_APPS=(
  org.kde.dolphin
  firefox
  kitty
  steam
  org.kde.systemsettings
)
```

Values must match the base filename of desktop entries (excluding the `.desktop` extension) found in `/usr/share/applications` or `~/.local/share/applications`.

The Downloads folder and the Trash can are automatically appended to the trailing edge of the dock. `DOCK_APPS` initializes the dock during the first `--layout` run; subsequent installer executions preserve your manual rearrangements and pins.

---

## 5. Audio Spectrum Visualizer (*RedRog Spectrum*)

The `visualizer` module renders an animated audio visualizer on the desktop canvas, situated beneath application windows and above the wallpaper.

Configure the visualizer style in `config/user.conf`:

```bash
SPECTRUM_STYLE="halo"   # Displays an audio spectrum halo centered on each screen
# SPECTRUM_STYLE="bars" # Displays classic audio visualizer bars along the bottom screen edge
```

Apply changes:

```bash
./install.sh --only visualizer
```

The visualizer dynamically inherits colors from the active palette (`ACCENT`, `ACCENT_ALT`, and `FG`).

---

## 6. Terminal Customization (kitty)

User configuration overrides belong at the end of `~/.config/kitty/kitty.conf`, following the auto-generated `include` directives. These overrides persist across theme reinstalls:

```conf
# Personal kitty overrides
font_size 12.0
background_opacity 0.95
confirm_os_window_close 0
map ctrl+t new_tab_with_cwd
```

Reload kitty configuration on the fly using `Ctrl+Shift+F5`.

### Adding AI Agent CLIs to the Contextual Menu
The right-click menu (`redrog-kitty-menu`) automatically scans `$PATH` for recognized AI development tools:
- Claude Code (`claude`)
- Antigravity (`agy`)
- OpenAI Codex (`codex`)
- Gemini CLI (`gemini`)
- OpenCode (`opencode`)
- Aider (`aider`)

To register additional custom CLI agents, add their executable names to the agent scanning list in `modules/terminal/redrog-kitty-menu`.

---

## 7. Audio DSP and Device Autoloading

RedRog routes all desktop audio through EasyEffects 8 to maximize audio clarity and dynamic range.

### Custom Headphone and Speaker Presets
Place custom EasyEffects output presets in `config/audio/` and microphone input presets in `config/audio/input/`:
- `config/audio/JBL Quantum 350.json`: Calibrated Harman bass shelf and high-frequency resonance compensation.
- `config/audio/input/JBL Quantum 350 Mic Streaming.json`: Equalized voice response paired with DeepFilterNet noise suppression.

Install and link presets:

```bash
./install.sh --only audio
```

To load presets manually from the terminal:

```bash
easyeffects -l "RedRog JBL Quantum 350"   # Load calibrated preset
easyeffects -l "RedRog Neutral"           # Revert to uncolored, bit-perfect bypass
```

### Automatic Hardware Association (`AUDIO_AUTOLOAD`)
Configure automatic preset switching in `config/user.conf` by mapping device name substrings to preset names:

```bash
AUDIO_AUTOLOAD=(
  "JBL_Quantum350|RedRog JBL Quantum 350"
  "USB_Audio_Device|RedRog Studio DAC"
)

AUDIO_INPUT_AUTOLOAD=(
  "JBL_Quantum350|RedRog JBL Quantum 350 Mic Streaming"
)
```

Whenever a matching device connects via USB or Bluetooth, `redrog-audio-memory` automatically applies the designated preset. When disconnected, output seamlessly transitions back to `RedRog Laptop Speakers`. For complete acoustic curves and measurement methodologies, refer to [docs/research/jbl-bass-eq.md](research/jbl-bass-eq.md).

---

## 8. Touchpad and Navigation Gestures

RedRog configures touchpad behavior to match macOS Precision Touchpads:
- **Natural Scrolling:** Content scrolls in the direction of finger movement (`NaturalScroll=true`).
- **Touch Gestures:** Tap-to-click, two-finger tap for secondary click, and tap-and-drag.
- **KWin Wayland Gestures:**
  - 3 or 4 fingers left/right: Switch virtual desktops.
  - 4 fingers up: Open Mission Control (all windows and desktops overview).
  - 4 fingers down: Toggle desktop grid.
  - Pinch / 2 fingers: Zoom and navigate history in supported applications.
- **Dynamic Virtual Desktops (`redrog-dynamic-desktops`):** Maintains at least 3 active desktop spaces. When windows are placed on the final empty space, a new desktop space is dynamically appended. Unused empty desktops are automatically reaped.

Tweak touchpad options directly in `config/user.conf` or through *System Settings → Input & Output → Touchpad*.

---

## 9. Dynamic Keyboard Layout Auto-Switching

RedRog supports dual keyboard layouts: **Latin American Spanish (`es`)** and **US English (`en`)**.

### Hardware Auto-Switching (`KEYBOARD_AUTO_DEVICES`)
Specify external keyboards that should automatically trigger an English layout when connected:

```bash
KEYBOARD_AUTO_DEVICES=("Keychron" "Apple Magic Keyboard" "Ergodox")
```

When a matching USB or Bluetooth device connects, `redrog-keyboard-layout` automatically switches the active layout to English. Disconnecting the device automatically restores the default Spanish layout.

### Manual Layout Switching
- Click the keyboard indicator in the system tray.
- Press the global keyboard shortcut: `Meta+Alt+K`.

The selected layout is preserved across desktop logins and system reboots.

---

## 10. Typography, Icons, and Cursors

Override interface fonts and icon packages in `config/user.conf`:

```bash
FONT_UI="Inter"                 # System interface typography
FONT_MONO="JetBrains Mono Nerd" # Monospace terminal and code font
FONT_SIZE=10                    # Baseline font size points
ICON_THEME="Papirus-Dark"       # System icon theme
CURSOR_THEME="macOS"            # System cursor theme
```

---

## 11. Bootloader and Boot Splash Customization

### Limine Bootloader
Customize the title displayed in the Limine bootloader menu:

```bash
LIMINE_BRANDING="RedRog OS // Linux"
```

Apply the updated branding to `/etc/limine.conf`:

```bash
./install.sh --system
```

### Plymouth Boot Splash
The `--system` stage installs and activates the animated Arch charging splash (`plymouth-theme-arch-charge-big`), ensuring a smooth visual transition from firmware initialization to the SDDM login screen.

---

## 12. ArtCraft Creative Suite and Slice Allocation

Configure resource quotas for ArtCraft creative applications and MCP server engines in `config/user.conf`:

```bash
# ArtCraft systemd cgroup resource slice limits
ARTCRAFT_CPU_QUOTA="75%"    # Maximum aggregate CPU time allocated to ArtCraft apps
ARTCRAFT_MEMORY_MAX="80%"   # Maximum aggregate RAM consumption before throttling
```

---

## 13. Internationalization and Translations

RedRog provides native desktop internationalization across **21 languages**: English, Spanish, German, French, Italian, Portuguese (Brazil and Portugal), Russian, Ukrainian, Polish, Dutch, Turkish, Czech, Swedish, Simplified Chinese, Traditional Chinese, Japanese, Korean, Arabic, Hindi, Indonesian, and Vietnamese.

Text rendering follows the active system locale (`LANG` / `LC_MESSAGES`).

### Translation Architecture
Translations are organized across three distinct layers:
1. **Installer CLI Messages:** Dual English and Spanish strings managed via `L "English" "Español"` helpers and `# describe:` module headers.
2. **Desktop File Metadata:** Standard `Name[xx]` and `Comment[xx]` localized keys in `.desktop` entries.
3. **Gettext Translation Catalogs (`i18n/`):**
   - `i18n/redrog/`: Core desktop daemons, ASUS notifications, and helper utilities.
   - `i18n/batterypercent/`: RedRog telemetry dashboard and menubar battery applet.
   - `i18n/hud/`: Desktop telemetry hologram.
   - `i18n/kurve/`: Desktop audio visualizer widget.
   - `i18n/rog-control-center/`: ROG Control Center interface strings.

### Adding or Updating a Language Catalog
To introduce a new language catalog (e.g., French `fr_FR`):

```bash
# 1. Initialize translation catalog from template
msginit -i i18n/redrog/redrog.pot -o i18n/redrog/fr.po -l fr_FR.UTF-8

# 2. Edit strings in i18n/redrog/fr.po, then compile and apply:
./install.sh --only rog-notify
```

For ROG Control Center translations, update `i18n/rog-control-center/fr.po` and compile system-wide with `./install.sh --system`.

---

## 14. Related Documentation

- **Installation Guide:** [docs/INSTALL.md](INSTALL.md)
- **Architecture Specification:** [docs/ARCHITECTURE.md](ARCHITECTURE.md)
- **Maintenance Procedures:** [docs/MAINTENANCE.md](MAINTENANCE.md)
- **Troubleshooting Manual:** [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- **Research: Menubar Legibility:** [docs/research/macos-menubar-legibility.md](research/macos-menubar-legibility.md)
- **Research: JBL Acoustic Calibration:** [docs/research/jbl-bass-eq.md](research/jbl-bass-eq.md)
- **Research: Hardware Thermals:** [docs/research/asus-tuf-f15-thermals.md](research/asus-tuf-f15-thermals.md)
