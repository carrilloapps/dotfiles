# Curate GNOME à la Carte, Preserve the KDE Core

A hybrid desktop strategy delivers the highest stability and aesthetic coherence. Core KDE utilities that dominate their functional category remain in place: Dolphin, Ark, Spectacle, Partition Manager, KWalletManager, snapper/Btrfs Assistant, and the underlying display, theme, and hardware management stack. Conversely, user-facing applications where the GNOME ecosystem offers a refined, mature, and officially packaged Apple equivalent in Arch Linux's `extra` repository replace their stock counterparts—mirroring the previous adoption of Loupe and GNOME Text Editor: **Showtime** (QuickTime Player), **Papers** (Preview), **Mission Center** (Activity Monitor), **GNOME Calculator**, **pwvucontrol**, **Iotas** (Apple Notes), **Planify** (Apple Reminders), **Snapshot** (Photo Booth), **GNOME Clocks/Weather/Maps**, **Dialect** (Apple Translate), **Rnote** (Freeform), and **Pika Backup** (Time Machine for `/home`). Outside the GNOME sphere, the strongest candidates comprise **Thunderbird** (Apple Mail + Calendar + Contacts), **LocalSend** (AirDrop), **Zen Browser** (Safari / Arc), **Vesktop** (Discord), and **GNOME Boxes / virt-manager** in place of VirtualBox. Nearly all recommended packages reside in `extra` or the `cachyos` native repositories, rendering **Flatpak unnecessary**. 

System dependency analysis reveals a decisive architectural boundary: **`gnome-control-center` drags in `xdg-desktop-portal-gnome`** (via `gnome-shell` → `gnome-session`). This hard constraint eliminates GNOME Online Accounts (GOA) as a background sync provider for GNOME Calendar and Contacts, dictating why unified calendaring and address book management are consolidated under Thunderbird. Furthermore, native traffic-light window controls for libadwaita applications do not require heavyweight third-party theme packages like MacTahoe or WhiteSur: the RedRog theme already contains vector assets for `windowcontrols`, and a concise user CSS snippet in `~/.config/gtk-4.0/` binds them directly. Finally, extraneous development tools, Java consoles, and package manager sub-launchers should not be uninstalled, but hidden via `.desktop` overrides—mirroring macOS's encapsulation of subordinate developer binaries inside Xcode.

---

## Architectural Guardrails Governing Laptop Evaluation

Three local system realities filter all package recommendations:

1. **Flatpak Is Not Installed:** Almost no core workflow requires it. Applications distributed primarily on Flathub (such as Folio, Kiview, or Orion) either have mature native equivalents in Arch repositories or remain experimental.
2. **Desktop Portal Integrity:** The compositor relies strictly on `xdg-desktop-portal-kde` and `xdg-desktop-portal-gtk`, completely omitting `xdg-desktop-portal-gnome`. Introducing `xdg-desktop-portal-gnome` into the dependency tree causes it to preempt the KDE portal implementation, breaking native Qt file picker dialogs across the desktop ([Manjaro Forums](https://forum.manjaro.org/t/how-to-specify-the-file-manager-kde-plasma-uses-for-recent-files-open-containing-folder/187825); [KDE Discuss](https://discuss.kde.org/t/how-to-use-nautilus-in-kde/45550)). Reverse dependency analysis using `pactree` confirms that none of the recommended applications pull this package, with the single exception of **`gnome-control-center`** (which depends on `gnome-shell` → `gnome-session` → `xdg-desktop-portal-gnome`). `discord-screenaudio` also requires it and is likewise disqualified. While earlier reports suggested Nautilus pulled GNOME portal components, modern packaging lists them as optional; however, Nautilus remains deprecated on Plasma due to session instability ([GNOME GitLab Issue #3370](https://gitlab.gnome.org/GNOME/nautilus/-/issues/3370)).
3. **Libadwaita Toolkit Boundary:** GTK4 / libadwaita applications will never inherit Kvantum or Klassy widget styles. Libadwaita prohibits arbitrary widget skinning, exposing only system accent colors via the Settings portal ([Xfce Issue #225](https://gitlab.xfce.org/xfce/xfce4-session/-/issues/225); [Phoronix](https://www.phoronix.com/news/GNOME-Shell-Accent-Color-Merged)). They retain their signature geometry: elevated headerbars, symbolic iconography, and rounded margins. Because this visual language closely aligns with modern macOS Human Interface Guidelines, applications like Loupe and GNOME Text Editor integrate naturally. A GNOME application is adopted **only when its user experience is unmistakably more refined than the KDE counterpart**, or when the KDE equivalent is unmaintained. Where KDE applications excel functionally (e.g., Dolphin over Nautilus, Spectacle over GNOME Screenshot), they are preserved.

---

## Fourteen Native Replacements Delivering a macOS Desktop Experience

These transitions deliver optimal ergonomics with minimal architectural risk. All candidates maintain active releases and provide native Arch/AUR packages:

| Existing Application | macOS Benchmark | Recommendation & Alternatives | Package | Toolkit | Maintenance Baseline | Disposition |
|---|---|---|---|---|---|---|
| Haruna / VLC / mpv | QuickTime Player | **Showtime** by default (Celluloid, Clapper). Haruna remains secondary, mpv for advanced CLI pipelines | `showtime` 50.0 (extra) | GTK4 + GStreamer | Default GNOME media player ([UbuntuHandbook](https://ubuntuhandbook.org/index.php/2024/09/showtime-totem-default-ubuntu/)) | **Adopt** |
| Okular | Preview (PDF / Docs) | **Papers** (Evince fork, modern libadwaita interface) | `papers` 49.0 (extra) | GTK4/libadwaita | GNOME core document viewer ([GNOME GitLab](https://gitlab.gnome.org/GNOME/Incubator/papers)) | **Adopt** |
| Plasma System Monitor / btop | Activity Monitor | **Mission Center** (btop remains in terminal) | `mission-center` 1.7.0 (extra) | GTK4 + Rust | Tracks GPU usage per-process ([missioncenter.io](https://missioncenter.io/)) | **Adopt** |
| KCalc | Calculator | **GNOME Calculator** (Qalculate! remains for engineering math) | `gnome-calculator` 49.0 (extra) | GTK4/libadwaita | GNOME core component ([archlinux.org](https://archlinux.org/packages/extra/x86_64/gnome-calculator/)) | **Adopt** |
| pavucontrol | Sound Settings | **pwvucontrol** (WirePlumber native, modern interface) | `pwvucontrol` 0.4.x (extra) | GTK4 + Rust | Native PipeWire volume mixer ([GitLab](https://gitlab.freedesktop.org/ryuuk/pwvucontrol)) | **Adopt** |
| KNotes / Marknote | Apple Notes | **Iotas** (Folio, Notes-Up) | `iotas` 0.10.x (extra) | GTK4/libadwaita | Markdown notes with Nextcloud sync ([apps.gnome.org](https://apps.gnome.org/Iotas/)) | **Adopt** |
| KOrganizer / Kalendar | Apple Reminders | **Planify** (Errands) | `planify` 4.12.x (extra) | GTK4/libadwaita | Todoist/Nextcloud sync, calendar integration ([apps.gnome.org](https://apps.gnome.org/Planify/)) | **Adopt** |
| Kamoso / Cheese | Photo Booth | **Snapshot** | `snapshot` 49.0 (extra) | GTK4/libadwaita + Rust | Replaces Cheese in GNOME core ([apps.gnome.org](https://apps.gnome.org/Snapshot/)) | **Adopt** |
| KClock / KWeather | Clocks & Weather | **GNOME Clocks** & **GNOME Weather** | `gnome-clocks`, `gnome-weather` (extra) | GTK4/libadwaita | Modern macOS-style widgets ([apps.gnome.org](https://apps.gnome.org/Clocks/)) | **Adopt** |
| Marble | Apple Maps | **GNOME Maps** | `gnome-maps` 49.0 (extra) | GTK4/libadwaita | OpenStreetMap client with turn-by-turn routing ([apps.gnome.org](https://apps.gnome.org/Maps/)) | **Adopt** |
| Crow Translate | Apple Translate | **Dialect** | `dialect` 3.0.0 (extra) | GTK4/libadwaita | Google, LibreTranslate, and Lingva backends ([apps.gnome.org](https://apps.gnome.org/Dialect/)) | **Adopt** |
| KCharSelect / Font Viewer | Font Book | **GNOME Font Viewer** | `gnome-font-viewer` 49.0 (extra) | GTK4/libadwaita | Clean typography inspection and installation | **Adopt** |
| KWave / Sound Recorder | Voice Memos | **GNOME Sound Recorder** & **Decibels** | `gnome-sound-recorder`, `decibels` (extra) | GTK4/libadwaita | Single-waveform audio capture and quick preview | **Adopt** |
| VirtualBox | Parallels Desktop | **GNOME Boxes** (simple) & **virt-manager** (advanced KVM) | `gnome-boxes`, `virt-manager` (extra) | GTK4 / GTK3 + libvirt | Native Linux KVM virtualization; bypasses DKMS modules | **Adopt** |

Supplementary audio, graphical, and backup utilities:
- **Image Annotation (Apple Markup):** **Gradia** (`gradia` 1.13.0 in `extra`), featuring 10 annotation presets and native OCR, complements Spectacle ([apps.gnome.org](https://apps.gnome.org/Gradia/)).
- **Photo Library:** **Koko** (`koko` 26.08.2 in `extra`), a lightweight Kirigami photo organizer from KDE Gear ([apps.kde.org](https://apps.kde.org/koko/)).
- **Music Library (Apple Music):** **Gapless** (`gapless` 4.6.2 in AUR) or **Amberol** (`amberol` in `extra`) provide elegant local album playback.
- **Backup Engine (Time Machine):** Maintain `snapper` for root/system Btrfs snapshots, and deploy **Pika Backup** (`pika-backup` 0.8.4 in `extra`, Borg-based) to manage encrypted, scheduled backups of `/home` to external storage ([Open Collective](https://opencollective.com/pika-backup/updates/version-0-8-released)).

Operational notes: Showtime decodes media via GStreamer rather than mpv's `hwdec`. Hardware acceleration on this machine routes through `libva-nvidia-driver` (H.264, HEVC, AV1) alongside `gst-plugins-bad-libs` (`nvcodec`). Video decode offloading can be confirmed by observing the `dec` column in `nvidia-smi dmon` during playback. For terminal emulation, **Kitty remains primary** due to deep fish shell integration and registration as `TerminalApplication` in `kdeglobals`. Ghostty 1.3.x ([Ghostty Release Notes](https://ghostty.org/docs/install/release-notes/1-3-0)) represents a compelling alternative if GTK4 native tabs and traffic lights are preferred.

---

## Preserved KDE Core Utilities

In file operations, screenshot pipelines, partition editing, and credential storage, native KDE applications substantially surpass GNOME alternatives:

| Application | macOS Equivalent | Rationale for Retention (Discarded Alternative) | Toolkit | Disposition |
|---|---|---|---|---|
| Dolphin | Finder | Superior multi-tab management, split views, KIO protocols, and custom actions compared to Nautilus. Enhanced via `dolphin-plugins`. | Qt | **Preserve** |
| Ark | Archive Utility | Deep Dolphin context-menu integration; File Roller offers no advantages in KDE. | Qt | **Preserve** |
| Filelight | Storage Analyzer / DaisyDisk | Circular multi-level pie charts provide superior storage visualization over Baobab. | Qt | **Preserve** |
| KDE Partition Manager | Disk Utility | Feature-complete storage administration; GNOME Disks maintenance has slowed ([archlinux.org](https://archlinux.org/packages/extra/x86_64/gnome-disk-utility/)). | Qt | **Preserve** |
| Spectacle | Screenshot Utility | Integrated OCR, inline annotations, Wayland screen recording, and global shortcuts. | Kirigami | **Preserve** |
| KWalletManager | Keychain Access | Native Secret Service backend for Plasma. For password management, pair with KeePassXC or Bitwarden. | Qt | **Preserve** |
| KInfoCenter | System Information | Native KDE hardware profiling; optionally supplemented by `cpu-x`. | Qt | **Preserve** |
| KDE Connect | Continuity & AirDrop | Bidirectional notifications, clipboard synchronization, SMS, and remote input. Paired with LocalSend. | Qt | **Preserve** |
| scrcpy | iPhone Mirroring | Low-latency Android/device display mirroring over USB/ADB. | SDL | **Preserve** |
| EasyEffects | eqMac | PipeWire audio processing and parametric EQ, ported to Qt6/Kirigami in 8.3.0 ([archlinux.org](https://archlinux.org/packages/extra/x86_64/easyeffects/)). | Kirigami | **Preserve** |
| Czkawka / BleachBit | CleanMyMac | High-performance deduplication and system cleaner. (On Btrfs, freed blocks reflect after snapshot rotation). | Rust / Slint / GTK | **Preserve** |

Professional suites, development editors, and hardware management tools remain intact:
- **Productivity & Office:** ONLYOFFICE Desktop Editors (`onlyoffice-bin`) + ArtCraft suite for documents; LibreOffice 26.8 as fallback.
- **Code & IDEs:** VS Code and Meld preserved; Zed 1.x available for lightweight editing.
- **AI & Assistants:** `claude-desktop` maintained via CachyOS packaging.
- **Media Production:** DaVinci Resolve Studio, OBS Studio, Audacity, Qtractor, Affinity, Blackmagic RAW Player, and HyperFrames.
- **Gaming Runtime:** Steam, Heroic, Lutris, Faugus Launcher, Goverlay, and MangoHud.
- **System Administration:** Kvantum Manager, Klassy Settings, ROG Control Center, CachyOS Kernel Manager, scx-manager, and Limine Snapper Restore.

---

## Hiding Subordinate Launchers from the Application Menu

To match macOS's clean Launchpad presentation, developer helper utilities and system diagnostic tools should be concealed using `NoDisplay=true` overrides placed in `~/.local/share/applications/`:
- **Qt Development Tools:** Qt Assistant, Qt Designer, Qt Linguist, Qt D-Bus Viewer, `qv4l2`, `qvidcap`.
- **System & Engine Utilities:** `lstopo`, OpenJDK consoles (`jconsole`, `jshell`), CMake GUI, Vim/Micro terminal launchers, `mpv` (invoked via Showtime/Haruna).
- **Package Management Subtools:** Octopi Notifier, Octopi Cache Cleaner, Octopi Repository Editor.
- **Redundant Entries:** KDE Connect SMS and non-plasma helper, `scrcpy-console`, Blackmagic RAW Speed Test, DaVinci Control Panels Setup, redundant `kdesystemsettings`, `nvidia-settings` (X11 options non-functional on Wayland), Winetricks, Protontricks, and post-setup CachyOS Hello.

---

## Personal Information Management: Resolving the Portal Conflict

A clean macOS installation includes Mail, Calendar, Contacts, Notes, and Reminders. In GNOME, Calendar and Contacts depend on GNOME Online Accounts (GOA). Because GOA lacks an independent configuration UI, accounts must be provisioned through `gnome-control-center` ([NixOS Wiki](https://wiki.nixos.org/wiki/GNOME/Calendar)). As established, installing `gnome-control-center` pulls `xdg-desktop-portal-gnome`, which compromises KDE Plasma file dialogues. The KDE alternative, Merkuro (Akonadi), suffers from recurring OAuth token expiration and sync regressions with Google Workspace ([KDE Discuss](https://discuss.kde.org/t/merkuro-setup-a-gmail-account/12525)).

**Thunderbird 158 provides the solution**, serving simultaneously as Mail, Calendar, and Contacts:
- Incorporates native Microsoft Exchange Web Services (EWS) sync since the 153 ESR release cycle ([IT-Connect](https://www.it-connect.tech/thunderbird-153-brings-a-new-esr-base-native-exchange-support-and-61-fixes/)).
- 2026 roadmap implements Microsoft 365 calendar and contact synchronization natively ([Phoronix](https://www.phoronix.com/news/Thunderbird-Roadmap-2026)).
- Robust native CalDAV and CardDAV synchronization handles Google and Nextcloud accounts cleanly without external daemons.

---

## RedRog Traffic Light Controls in Libadwaita via User CSS

Libadwaita applications ignore system window decoration themes like Klassy, rendering monochromatic circular window controls. However, libadwaita exposes documented `windowcontrols` CSS nodes ([GTK Documentation](https://docs.gtk.org/gtk4/class.WindowControls.html)). RedRog injects customized CSS into `~/.config/gtk-4.0/gtk.css`, mapping the RedRog dark traffic-light button assets directly to GTK4 window controls:

```css
/* ~/.config/gtk-4.0/redrog-windowcontrols.css */
windowcontrols { border-spacing: 6px; }
windowcontrols > button {
  min-width: 24px; min-height: 24px; padding: 0; margin: 0;
  border: none; box-shadow: none; background-color: transparent;
  background-position: center; background-repeat: no-repeat;
}
windowcontrols > button > image { -gtk-icon-source: none; background: none; box-shadow: none; }
windowcontrols > button.close            { background-image: -gtk-scaled(url("redrog-assets/titlebutton-close-dark.png"), url("redrog-assets/titlebutton-close-dark@2.png")); }
windowcontrols > button.close:hover      { background-image: -gtk-scaled(url("redrog-assets/titlebutton-close-hover-dark.png"), url("redrog-assets/titlebutton-close-hover-dark@2.png")); }
windowcontrols > button.close:active     { background-image: -gtk-scaled(url("redrog-assets/titlebutton-close-active-dark.png"), url("redrog-assets/titlebutton-close-active-dark@2.png")); }
windowcontrols > button.close:backdrop   { background-image: -gtk-scaled(url("redrog-assets/titlebutton-close-backdrop-dark.png"), url("redrog-assets/titlebutton-close-backdrop-dark@2.png")); }
windowcontrols > button.minimize          { background-image: -gtk-scaled(url("redrog-assets/titlebutton-minimize-dark.png"), url("redrog-assets/titlebutton-minimize-dark@2.png")); }
windowcontrols > button.minimize:hover    { background-image: -gtk-scaled(url("redrog-assets/titlebutton-minimize-hover-dark.png"), url("redrog-assets/titlebutton-minimize-hover-dark@2.png")); }
windowcontrols > button.minimize:active   { background-image: -gtk-scaled(url("redrog-assets/titlebutton-minimize-active-dark.png"), url("redrog-assets/titlebutton-minimize-active-dark@2.png")); }
windowcontrols > button.minimize:backdrop { background-image: -gtk-scaled(url("redrog-assets/titlebutton-minimize-backdrop-dark.png"), url("redrog-assets/titlebutton-minimize-backdrop-dark@2.png")); }
windowcontrols > button.maximize          { background-image: -gtk-scaled(url("redrog-assets/titlebutton-maximize-dark.png"), url("redrog-assets/titlebutton-maximize-dark@2.png")); }
windowcontrols > button.maximize:hover    { background-image: -gtk-scaled(url("redrog-assets/titlebutton-maximize-hover-dark.png"), url("redrog-assets/titlebutton-maximize-hover-dark@2.png")); }
windowcontrols > button.maximize:active   { background-image: -gtk-scaled(url("redrog-assets/titlebutton-maximize-active-dark.png"), url("redrog-assets/titlebutton-maximize-active-dark@2.png")); }
windowcontrols > button.maximize:backdrop { background-image: -gtk-scaled(url("redrog-assets/titlebutton-maximize-backdrop-dark.png"), url("redrog-assets/titlebutton-maximize-backdrop-dark@2.png")); }
```

Client-side decorated applications (VS Code, Chrome, Zen Browser, Discord) should be configured to use system titlebars (`"window.titleBarStyle": "native"` in VS Code; "Use system title bar and borders" in Chrome and Zen), ensuring KWin renders hardware Klassy traffic lights.

---

## Five-Phase Implementation Blueprint

Executed in fish shell with dependency guards verified at each step:

```fish
# Phase 0: Dependency Integrity Guard (Must produce zero output)
for p in showtime papers mission-center gnome-calculator pwvucontrol iotas planify thunderbird
    pactree -s -u $p | grep -x xdg-desktop-portal-gnome; and echo "CRITICAL CONFLICT: $p introduces GNOME portal"
end
# STRICT RULE: Never install gnome-control-center, gnome-shell, gnome-session, or discord-screenaudio
```

### Phase 1: High-Priority Direct Replacements
```fish
sudo pacman -S --needed showtime papers mission-center gnome-calculator pwvucontrol dolphin-plugins
# Register default MIME handlers
xdg-mime default org.gnome.Showtime.desktop video/mp4 video/x-matroska video/webm video/quicktime
xdg-mime default org.gnome.Papers.desktop application/pdf
```

### Phase 2: Native Complementary Suite
```fish
sudo pacman -S --needed iotas planify thunderbird gnome-clocks gnome-weather gnome-maps dialect \
    gnome-font-viewer snapshot gnome-sound-recorder decibels rnote koko gradia localsend pika-backup
paru -S --needed gapless          # Optional local music library
# Open firewall port 53317 for LocalSend transfers; configure Pika Backup to exclude .snapshots/
```

### Phase 3: Browser, Communications & Virtualization
```fish
sudo pacman -S --needed zen-browser-bin gpu-screen-recorder-ui gnome-boxes virt-manager qemu-desktop libvirt dnsmasq
paru -S --needed vesktop-bin
sudo systemctl enable --now libvirtd.service
sudo usermod -aG libvirt $USER

# After validating replacements, prune obsolete packages:
sudo pacman -Rns virtualbox virtualbox-host-dkms brave-bin pavucontrol discord
sudo pacman -Rns vlc vlc-plugins-all vlc-gui-qt vlc-cli   # Review dependencies before confirming
```

### Phase 4: Menu Sanitization & Libadwaita Traffic Lights
```fish
mkdir -p ~/.local/share/applications
for f in assistant designer linguist qdbusviewer qv4l2 qvidcap lstopo jconsole-java-openjdk jshell-java-openjdk \
         cmake-gui vim micro mpv octopi-notifier octopi-cachecleaner octopi-repoeditor \
         org.kde.kdeconnect.nonplasma org.kde.kdeconnect.sms scrcpy-console blackmagicraw-speedtest \
         DaVinciControlPanelsSetup kdesystemsettings nvidia-settings winetricks protontricks \
         org.kde.plasma-systemmonitor org.kde.kcalc
    set dst ~/.local/share/applications/$f.desktop
    if not test -f $dst
        test -f /usr/share/applications/$f.desktop; and cp /usr/share/applications/$f.desktop $dst; or continue
    end
    grep -q '^NoDisplay=true' $dst; or sed -i '0,/^\[Desktop Entry\]/s//[Desktop Entry]\nNoDisplay=true/' $dst
end
kbuildsycoca6

# Deploy RedRog traffic lights to GTK4
mkdir -p ~/.config/gtk-4.0/redrog-assets
ln -sf ~/.local/share/themes/RedRog/gtk-4.0/assets/titlebutton-*-dark*.png ~/.config/gtk-4.0/redrog-assets/
cp ~/.config/gtk-4.0/gtk.css ~/.config/gtk-4.0/gtk.css.bak
# Write ~/.config/gtk-4.0/redrog-windowcontrols.css with the snippet above, then link:
sed -i '1i @import "redrog-windowcontrols.css";' ~/.config/gtk-4.0/gtk.css
```

### Phase 5: Experimental Tools & Portal Enforcement
```fish
paru -S --needed vicinae-bin       # Raycast-style spotlight launcher (rebind Meta+Space)
sudo pacman -S --needed ghostty zed # Optional high-performance GTK4 terminal and editor
mkdir -p ~/.config/xdg-desktop-portal
printf '[preferred]\ndefault=kde;gtk\norg.freedesktop.impl.portal.FileChooser=kde\n' > ~/.config/xdg-desktop-portal/kde-portals.conf
```

---

## Conclusion

This strategy shifts the core architectural question: rather than chasing skin-deep visual clones, the objective is determining **how much of the modern GNOME application ecosystem can be harnessed without allowing the GNOME Shell stack to destabilize KDE**. The line of demarcation is isolated to a single package: `gnome-control-center`. Excluding it keeps the desktop clean of `xdg-desktop-portal-gnome`, allowing Circle and Core applications to integrate seamlessly alongside KDE core infrastructure. Thunderbird bridges the personal data gap, while libadwaita user CSS harmonizes window controls across disparate toolkits without brittle global themes.
