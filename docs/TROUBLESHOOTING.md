# Troubleshooting Guide

This guide provides diagnostic procedures and step-by-step solutions for common issues across the desktop environment, compositing pipeline, audio DSP, hybrid graphics, and AI agent infrastructure.

---

## 1. Compositor, Window Decorations, and Visual Blur

### Windows lose rounded corners after a Plasma or KWin update
**Symptom:** Window corners revert to square 90-degree edges following a system upgrade.  
**Cause:** `kwin-effect-rounded-corners` is a native C++ KWin plugin compiled against internal KWin symbols. When Arch Linux or CachyOS updates KWin, the plugin binary ABI becomes incompatible and KWin disables it.  
**Solution:** Rebuild the package against the newly installed KWin headers:

```bash
paru -S --rebuild kwin-effect-rounded-corners-git
```

Log out and back in to reload KWin.

---

### Dialogs, panels, or popups lack frosted glass blur
**Symptom:** Translucent windows or the top menubar appear flat and see-through without gaussian background blur.  
**Cause:** KWin's desktop blur effect is disabled or the graphics compositor encountered an error.  
**Solution:**
1. Verify that blur is enabled in *System Settings → Window Management → Desktop Effects → Blur* (or *Better Blur DX*).
2. Alternatively, re-apply the styling module from the terminal:
   ```bash
   ./install.sh --only plasma-style
   ```
3. Restart the KWin compositor:
   ```bash
   qdbus6 org.kde.KWin /KWin reconfigure
   ```

---

### System Settings, Discover, or ROG Control Center are not frosted
**Symptom:** Qt Widgets and Kvantum windows display blur, but QML-based applications (like System Settings or Discover) render with opaque or unblurred backgrounds.  
**Cause:** `kwin-effects-better-blur-dx` requires matching window classes formatted strictly one per line. If comma-separated or incorrectly formatted, KWin ignores the match rules. Furthermore, ROG Control Center assigns its window class dynamically after initialization.  
**Solution:**
1. Re-run the module to write properly formatted window rules:
   ```bash
   ./install.sh --only plasma-style
   ```
2. Verify that the KWin script *RedRog menu placement* is enabled under *System Settings → Window Management → KWin Scripts*. This script automatically triggers a blur refresh once ROG Control Center maps to the display.

---

### Desktop color scheme does not update after installer run
**Symptom:** Running `./install.sh --only colors` reports completion, but active window decorations and highlights remain unchanged.  
**Cause:** KDE Plasma skips updating color schemes if the requested scheme name matches the currently active scheme string in `kdeglobals`, even if file contents changed.  
**Solution:** Toggle the active color scheme through Breeze Dark to force Plasma to invalidate its cache:

```bash
plasma-apply-colorscheme BreezeDark && plasma-apply-colorscheme RedRog
```

---

### GTK applications display default Breeze styling
**Symptom:** GTK applications (such as Loupe or GNOME Text Editor) or Firefox dropdown menus appear with default Breeze styling instead of RedRog dark/light palettes.  
**Cause:** The `arc-gtk-theme` base package failed to build or was removed during an update.  
**Solution:** Build and install the patched PKGBUILD from `packages/arc-gtk-theme`, then re-apply the GTK module:

```bash
cd packages/arc-gtk-theme && makepkg -si
cd ../..
./install.sh --only gtk
```

---

## 2. Panels, Widgets, and Menubar Legibility

### AppGrid (macOS Launchpad) fails to open on Plasma 6.8
**Symptom:** Pressing `Alt+Space` does nothing, or logs an error regarding `Applet::globalConfig()`.  
**Cause:** Plasma 6.8 permanently removed the legacy `Applet::globalConfig()` API, breaking unpatched upstream AppGrid builds.  
**Solution:** Install RedRog's patched AppGrid package:

```bash
cd packages/appgrid && makepkg -si
cd ../..
./install.sh --layout
```

---

### RedRog telemetry dashboard or battery applet does not reflect changes
**Symptom:** Clicking the battery percentage applet displays stale sensor readings or fails to open following an update.  
**Cause:** Plasma aggressively caches compiled QML bytecode in user cache directories.  
**Solution:** Clear the QML cache and restart the desktop shell:

```bash
rm -rf ~/.cache/plasmashell/qmlcache
systemctl --user restart plasma-plasmashell
```

---

### Top menubar text is illegible over a custom wallpaper
**Symptom:** Menubar text or tray icons blend into the wallpaper background.  
**Cause:** `redrog-panel-veil` may not have re-calculated linear luminance following a manual wallpaper change outside of RedRog scripts.  
**Solution:**
1. Manually trigger a menubar veil re-calculation:
   ```bash
   redrog-panel-veil
   ```
2. Verify that `plasma6-applets-panel-colorizer` is installed and active in the panel layout. For complete details on the APCA contrast algorithm used (Lc 60 threshold), refer to [docs/research/macos-menubar-legibility.md](research/macos-menubar-legibility.md).

---

### Desktop audio visualizer (*RedRog Spectrum*) does not react to audio
**Symptom:** The audio visualizer halo or bottom bars remain static while sound is playing.  
**Cause:** The underlying `cava` daemon is disconnected from the active PipeWire audio monitor sink.  
**Solution:**
1. Verify that `cava` is installed:
   ```bash
   cava
   ```
2. Verify that `plasma6-applets-kurve-git` is installed and active on the desktop.
3. Re-run the visualizer configuration module:
   ```bash
   ./install.sh --only visualizer
   ```

---

## 3. Hybrid Graphics, GPU Power, and Thermals

### Discrete NVIDIA GPU will not sleep (high battery discharge rate)
**Symptom:** On hybrid graphics laptops, the battery drains rapidly (25W+ discharge rate) and the laptop runs warm during basic desktop use.  
**Cause:** An unconfined Xwayland process or background application is keeping the discrete NVIDIA GPU powered on.  
**Solution:**
1. Check GPU runtime power status:
   ```bash
   cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
   ```
   *(Expected status during desktop idle: `suspended`)*.
2. Identify any processes holding open handles on the NVIDIA driver:
   ```bash
   sudo lsof /dev/nvidia*
   ```
3. Ensure the RedRog Xwayland power management wrapper is installed:
   ```bash
   ./install.sh --only asus-laptop
   ```
   This ensures `~/.local/bin/Xwayland` forces Xwayland clients onto the integrated Intel/AMD GPU.
4. Verify your GPU profile with `supergfxctl`:
   ```bash
   supergfxctl -g    # Should report Hybrid or Integrated
   ```
   For detailed hardware power profiles and hybrid graphics research, see [docs/research/asus-tuf-f15-thermals.md](research/asus-tuf-f15-thermals.md).

---

### ASUS notifications missing or displayed in English
**Symptom:** Adjusting fan profiles, battery charge thresholds, or keyboard backlight does not trigger on-screen notifications, or notifications appear in untranslated English.  
**Cause:** The user service `redrog-rog-notify` is stopped, `asusd` is inactive, or multi-language gettext catalogs were not compiled.  
**Solution:**
1. Inspect the service status and journal logs:
   ```bash
   systemctl --user status redrog-rog-notify
   journalctl --user -u redrog-rog-notify -n 50 --no-pager
   ```
2. Ensure `asusd` is running on the system bus:
   ```bash
   systemctl status asusd
   ```
3. Recompile notification catalogs:
   ```bash
   ./install.sh --only rog-notify
   ```

---

## 4. Audio DSP and EasyEffects

### Speaker DSP preset is applied to headphones (or headphones sound flat)
**Symptom:** Psychoacoustic bass boost remains active when plugging in headphones, causing distorted bass, or headphones receive no equalization.  
**Cause:** EasyEffects matches autoload profiles by device name and PipeWire route *description*. If the system language or locale was modified, the route description string changes (e.g., from `Speakers` to `Altavoces`), causing autoload rules to miss.  
**Solution:**
1. Re-generate autoload definitions matching your current system locale:
   ```bash
   ./install.sh --only audio
   ```
2. Verify active routing in EasyEffects:
   ```bash
   easyeffects -a output
   ```
3. To reset the speaker preset to factory defaults, launch **"Restore speaker sound"** from the desktop menu or run:
   ```bash
   redrog-audio-reset
   ```
   For calibrated target curves and headphone measurements, refer to [docs/research/jbl-bass-eq.md](research/jbl-bass-eq.md).

---

### Audio crackling or latency when microphone filter is active
**Symptom:** Microphone input stutters or exhibits latency during voice calls or recordings.  
**Cause:** DeepFilterNet LADSPA neural processing is contending for CPU time or the PipeWire buffer quantum is configured too small.  
**Solution:**
1. Check PipeWire quantum settings:
   ```bash
   pw-top
   ```
2. In *EasyEffects → Input → DeepFilterNet*, reduce attenuation intensity or switch to the standard `RedRog Laptop Mic` preset.

---

## 5. Terminal Architecture and Contextual Menu

### Right-clicking inside kitty terminal does not open the RedRog menu
**Symptom:** Right-clicking inside the terminal displays no menu or triggers text selection.  
**Cause:**
- **Mouse Capture:** An interactive terminal application (such as Vim, Neovim, `htop`, or `less`) has enabled mouse reporting and is consuming mouse clicks. Hold `Shift` while right-clicking to bypass application capture.
- **Runtime Dependency:** The menu requires Qt's standalone QML runtime (`/usr/lib/qt6/bin/qml`, provided by `qt6-declarative`).
- **Remote Control Permissions:** Kitty instances launched before running the installer lack remote control privileges. Press `Ctrl+Shift+F5` or open a new terminal window.
**Solution:** Test the menu directly from within a kitty terminal:

```bash
~/.local/lib/redrog/kitty/redrog-kitty-menu $KITTY_WINDOW_ID
```

Inspect any QML or Qt error messages printed to standard error.

---

### Tab bar reverts to default kitty appearance after an update
**Symptom:** Tabs render with stock kitty styling rather than macOS-style rounded tabs.  
**Cause:** Upstream kitty introduced changes to its internal `TabManager` API, preventing `tab_bar.py` from monkey-patching mouse event listeners.  
**Solution:** Inspect kitty startup logs:

```bash
kitty 2>&1 | grep -i tab_bar
```

Report any internal API changes so `tab_bar.py` can be updated.

---

## 6. ArtCraft Suite and AI Agent MCP Infrastructure

### AI Agent (Claude Code / Antigravity) cannot connect to Craft app MCP server
**Symptom:** The agent logs an error connecting to `photocraft`, `filmcraft`, or other Craft MCP servers.  
**Cause:**
- **Permission or Path:** `~/.local/bin/artcraft-mcp` is not executable or missing from user `$PATH`.
- **Token Invalidation:** When the application window is active, the MCP server connects to `127.0.0.1` and requires the runtime session token from `$XDG_RUNTIME_DIR`. If the session was restarted, the token may have changed.
**Solution:**
1. Verify the bridge script is executable:
   ```bash
   chmod +x ~/.local/bin/artcraft-mcp
   ```
2. Verify token existence in the runtime directory:
   ```bash
   ls -la $XDG_RUNTIME_DIR/artcraft-*.token
   ```
3. In Claude Code, run `/mcp` to reconnect servers. In Antigravity, re-initialize the MCP server connection.
4. If the application is closed, ensure headless binaries are accessible in `/usr/bin/`.

---

### Local ArtCraft repository fails to update
**Symptom:** Running `sudo pacman -Sy` does not show updates for ArtCraft applications, or reports database errors.  
**Cause:** `redrog-artcraft-repo.service` failed to download releases or cryptographic checksums did not match `SHA256SUMS.txt`.  
**Solution:** Inspect service logs:

```bash
sudo systemctl status redrog-artcraft-repo.service
journalctl -u redrog-artcraft-repo.service -n 50 --no-pager
```

Ensure network connectivity to GitHub and check `/var/lib/redrog-artcraft-repo` directory permissions.

---

## 7. Bootloader and System Initialization

### Limine boot menu does not reflect RedRog theme
**Symptom:** Bootloader menu displays stock CachyOS / Arch styling or pure text.  
**Cause:** System stage was not executed, or Limine config hash verification prevented applying `/etc/limine.conf`.  
**Solution:**
1. Re-run the system installation module as root:
   ```bash
   ./install.sh --system
   ```
2. Verify that `/etc/limine.conf` contains the `# >>> REDROG` configuration block.
3. If your distribution uses Limine hash enrollment:
   ```bash
   sudo limine-enroll-config /boot/limine/limine.conf
   ```
   A backup of your previous bootloader configuration is preserved in `/var/backups/redrog/`.

---

### Dynamic keyboard layout fails to auto-switch on USB/Bluetooth connection
**Symptom:** Plugging in an external keyboard defined in `KEYBOARD_AUTO_DEVICES` does not switch the active layout to English.  
**Cause:** `redrog-keyboard-layout` daemon is not running or device name strings in `config/user.conf` do not match the kernel input device name.  
**Solution:**
1. Inspect input device names detected by the kernel:
   ```bash
   cat /sys/class/input/event*/device/name
   ```
2. Verify that `KEYBOARD_AUTO_DEVICES` in `config/user.conf` contains an exact substring match.
3. Test layout switching manually via shortcut: `Meta+Alt+K`.

---

## 8. General Diagnostics and Support

If you encounter an issue not addressed above:

1. **Execute with Dry-Run Mode:** Inspect the precise commands executed by the installer without making changes:
   ```bash
   ./install.sh --dry-run
   ```
2. **Review Journal and Session Logs:**
   ```bash
   journalctl --user -p 3 -xb
   ```
3. **Inspect Application Backups:** Automatic backups created before system-level modifications reside in:
   ```bash
   /var/backups/redrog/
   ```

---

## 9. Related Documentation

- **Installation Guide:** [docs/INSTALL.md](INSTALL.md)
- **Architecture Specification:** [docs/ARCHITECTURE.md](ARCHITECTURE.md)
- **Customization Guide:** [docs/CUSTOMIZE.md](CUSTOMIZE.md)
- **Maintenance Manual:** [docs/MAINTENANCE.md](MAINTENANCE.md)
- **Menubar Legibility Research:** [docs/research/macos-menubar-legibility.md](research/macos-menubar-legibility.md)
- **Hardware Thermals Research:** [docs/research/asus-tuf-f15-thermals.md](research/asus-tuf-f15-thermals.md)
- **Acoustic Calibration Research:** [docs/research/jbl-bass-eq.md](research/jbl-bass-eq.md)
