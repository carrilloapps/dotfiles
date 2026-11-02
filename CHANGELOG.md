# Changelog

All notable changes to RedRog are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Ongoing optimizations and refinements for upcoming KDE Plasma releases.

### Changed
- Documentation tables and index references updated with synchronized English research report titles.

## [0.0.1] - 2026-11-01

### Added
- Complete RedRog Dark desktop theme featuring near-black surfaces (`#1c1c1c`, `#252524`, `#313131`), warm off-white typography (`#efeeeb`), and Pantone Red 032 C (`#ef3340`) as the signature accent.
- RedRog Light variant (`THEME_VARIANT="light"`, `REDROG_VARIANT=light`) based on Pantone Cloud Dancer 11-4201 and Pantone 1795 C accent, accompanied by Papirus-Light icons, tailored Kitty colors, and custom OBS and Audacity themes.
- Live theme variant switcher widget in the system tray with single-click toggle and a context menu providing Dark, Light, and Automatic (scheduled) modes, transition animation controls, and theme settings.
- Zero-restart live theme switching: Plasma menus, Polkit authentication dialogs, and XDG desktop portal windows render with dynamic Breeze integration conforming to RedRog color palettes in real time, eliminating shell restarts and preserving per-screen wallpaper state.
- Fullscreen animated transition veil inspired by Samsung DeX: displays smoothly fade into the target variant's canvas color with the charging Arch Linux logo centered, applying theme changes underneath before fading the veil over the new aesthetic (~1.5 s total duration).
- Adaptive macOS-style menu bar luminance daemon (`redrog-panel-veil`): samples linear luminance beneath the top panel per display, dynamically toggling light/dark glyphs and text using APCA contrast algorithms, applying subtle bilateral panel shading only when crossing heterogeneous wallpaper boundaries.
- Dedicated hardware control center docked behind the battery indicator: live per-thread CPU core equalizer differentiating Performance and Efficient cores, power draw in watts against active power limits (PL1/PL2), core throttling alerts, ROG power profile toggle, `supergfxctl` GPU switching (Intel / Automatic / NVIDIA), battery charge thresholds, and system telemetry export.
- Floating desktop system hologram widget (`org.redrog.hud`): live CPU/GPU temperatures, memory allocation, fan speeds, disk I/O, network throughput, and battery status with zero wakeups to discrete NVIDIA GPUs.
- Audio-reactive wallpaper visualizer (`org.redrog.spectrum`): dynamic audio halo or bottom-edge spectrum bars with falling peak ballistics, automatically idling when windows are maximized.
- macOS-inspired desktop layout: translucent top status bar (global application menu, system tray, battery percentage, unified clock, Notification Center) and floating dock with Launchpad-style AppGrid.
- EasyEffects "Equalizer" tray widget integrated alongside hardware status indicators, featuring a context menu for quick preset switching and DSP bypass.
- Studio-grade PipeWire microphone DSP pipeline ("RedRog Microphone"): 80 Hz high-pass filter, RNNoise neural noise suppression, EBU R128 autogain targeted at -18 LUFS, and peak limiter; calibrated ALSA mixer gain paths (0 dB capture, +10 dB boost) preventing analog clipping while reserving user digital volume headroom.
- Acoustic measurement-calibrated EasyEffects presets: tailored laptop speaker profile delivering fuller response, and specialized headphone profiles ("RedRog JBL Quantum 350 Bass Loudness" and universal "RedRog JBL Bass Loudness") providing Harman curve-guided sub-bass compensation below 65 Hz via `mda-loudness`.
- Automatic audio output routing: speaker DSP profile automatically restricted to onboard laptop speakers, seamlessly switching to user or neutral profiles upon connecting external outputs, with a desktop launcher to restore defaults.
- Low-latency network and wireless tuning (`--system`): disabled Wi-Fi dynamic power save (reducing ping latency from 300-800 ms to ~6 ms), disabled Ethernet EEE and runtime PM, disabled Bluetooth autosuspend, and enabled TCP BBR congestion control with `fq` queuing discipline.
- ASUS ROG and TUF laptop hardware integration module (`modules/asus-laptop`): automated NVIDIA dGPU power management with Xwayland offload isolation, and hardware Armoury Crate key mapping to ROG Control Center.
- Localized ASUS notification daemon (`rog-notify`) for power profiles, battery charge thresholds, and graphics modes.
- Custom-built ROG Control Center (`packages/rog-control-center`): native Wayland blur via `ext-background-effect-v1`, macOS-style sidebar navigation, refined UI controls, overhauled fan curve and Aura LED pages, and full Spanish localization.
- Custom RedRog Glass KWin effect applying seamless frosted glass blur across System Settings, Discover, System Monitor, Info Center, and EasyEffects, maintained via pacman rebuild hooks across KWin ABI bumps.
- Kitty terminal configuration with RedRog frosted glass, macOS-style tabs with status dots, split-pane shortcuts, and an integrated context menu for file navigation and AI coding agents (Claude Code, Antigravity).
- Production-ready OBS Studio profile (`modules/obs`): themed UI, hardware-accelerated NVENC (H.264 streaming, HEVC recording) and Intel Quick Sync pipelines, Hybrid MP4 container output, and essential plugins (Application Audio Capture, Background Removal, Move Transition, Composite Blur, StreamFX masks, Source Record).
- Recolored Audacity theme (`modules/audacity`) matching RedRog Dark/Light palettes, with automatic rebuild hooks upon application updates and expanded LV2/LADSPA and Vamp analysis plugins.
- Hardware-optimized Steam configuration (`modules/steam`): dedicated NVIDIA GPU offloading for games via CachyOS game-performance profile while rendering the Steam client on the integrated GPU, enabled NVAPI, 12 GB untrimmed DXVK/VKD3D shader cache, 14 shader compilation threads, and enforced HTTP/1.1 client downloads.
- Declarative, modular installer (`install.sh`) supporting granular flags (`--layout`, `--packages`, `--system`, `--only`, `--dry-run`) alongside a complete uninstaller (`uninstall.sh`).
- Pure-black unified boot-to-desktop visual pipeline: themed Limine bootloader, Plasma Login Manager (SDDM) styling, enabled boot-time Num Lock, and pacman hooks preserving configurations across updates.
- Centralized palette system in `lib/palette.sh` shared across installer routines and live recoloring scripts.
- Multi-language localization coverage across 21 languages for desktop widgets, notifications, and installer prompts.

### Changed
- Migrated default application style to Darkly, enabling synchronized live light/dark transitions across all active Qt applications.
- Refined Dolphin file manager configuration to a unified, borderless frosted-glass layout with Finder-like flat tabs and subtle separators.
- Optimized EasyEffects spectrum analyzer rendering: transitioned to a smooth macOS-style red fill over window glass, removing rigid grid lines and stabilizing decay ballistics.
- Decoupled hardware-specific tuning: relocated reference laptop profiles to `hosts/asus-tuf-f15` while keeping base dotfiles clean, declarative, and universal across systems.
- Accelerated system boot sequence: removed redundant graphics drivers from the initial ramdisk (initramfs) and reduced Limine boot timeout to 1 second.
- Redesigned ROG Control Center hardware monitor into modular status tiles per silicon component (temperature telemetry, utilization bar, and fan tachometer).
- Refined Qt/Kvantum widget heuristics: rounded accent selection pills, borderless container panes, and segmented controls for tab bars.
- Improved multi-monitor wallpaper handling to automatically configure newly connected displays while preserving user-selected custom wallpapers.
- Configured keyboard layout selector to automatically hide from the top bar when only a single layout is active.
- Unified desktop terminal integration: mapped `$TERMINAL`, `xdg-terminal-exec`, and CachyOS update notifications directly to Kitty.

### Fixed
- Fixed top-bar panel tinting when windows are maximized, matching panel tint directly to foreground icon contrast over arbitrary wallpapers instead of defaulting to a static window background color.
- Corrected light variant panel styling: eliminated halo artifacts and artificial white veils by calculating icon glyph colors directly from linear luminance using APCA contrast algorithms.
- Adjusted light variant dialog opacity to 34% to properly expose underlying blur shaders.
- Resolved duplicate entries for default dark wallpapers in the KDE wallpaper picker.
- Packaged missing `mda.lv2` dependency and normalized gain mappings in EasyEffects to ensure JBL Bass Loudness filters function correctly without attenuating bass below -6 dB.
- Corrected out-of-specification audio preset parameters, adjusting limiter release from 50 ms to 20 ms maximum and compressor release threshold from -100 dB to -80 dB minimum.
- Restored consistent "RedRog <name>" prefix convention for auto-loaded audio profiles in `config/audio/`.
- Fixed double-translucency rendering bugs on legacy Qt QtWidgets embedded inside System Settings (e.g., Wi-Fi configuration modules).
- Resolved broken background blur in ROG Control Center on KDE Plasma 6.8 by transitioning from deprecated KDE blur protocols to Wayland `ext-background-effect-v1`, eliminating initial-map visual flicker.
- Fixed `.gitignore` rule that previously excluded RedRog Glass KWin effect sources from clean repository clones.
- Resolved file collision during installation between `modules/system` localization output and the standalone `rog-control-center` package.
- Formatted Better Blur DX window class inclusion lists with single entries per line to adhere to parser requirements, restoring blur across QML applications.
- Ensured dock configuration idempotency: running `./install.sh --layout` preserves user-pinned dock applications instead of resetting them to default `DOCK_APPS`.
- Fixed output route matching in EasyEffects to match PulseAudio/PipeWire sink route descriptions rather than hardware port names, preventing laptop speaker DSP from persisting over headphones.
- Resolved an Xwayland process isolation issue where background X11 emulation prevented hybrid laptops from entering runtime D3cold power-saving state on NVIDIA GPUs.
- Bound physical hardware and custom keys (Ctrl+Alt+T, Armoury Crate) to active global desktop actions, ensuring immediate hardware trigger response.
- Resolved recurring PipeWire audio memory state allocation exception in audio processing loops.
- Fixed upstream AUR build and source hosting failures by providing patched local PKGBUILDs for `obs-move-transition` and `qm-vamp-plugins`.

### Removed
- Removed legacy Blender workstation module (`modules/blender`) and associated MCP automation servers to streamline system dependencies.
- Removed CadCraft tool from the bundled ArtCraft suite.
- Removed redundant desktop utilities (`gnome-maps`, `gnome-weather`).
- Removed machine-specific personal data and user secrets from `hosts/asus-tuf-f15`, restricting tracked files exclusively to hardware tuning and reusable configuration templates.
- Removed blocking systemd boot services (`NetworkManager-wait-online.service`) to accelerate boot times.
- Removed sluggish translucent backdrop and heavy gradient layers in the Limine bootloader menu in favor of high-performance pure-black rendering.

[Unreleased]: https://github.com/carrilloapps/dotfiles/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/carrilloapps/dotfiles/releases/tag/v0.0.1
