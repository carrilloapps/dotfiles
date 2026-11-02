# Gamer/futuristic theming components for KDE Plasma 6 (CachyOS, Wayland, NVIDIA hybrid), as of 2026-10-16

Local system context, checked on this machine on 2026-10-16 with `pacman`, `/sys/class/dmi` and systemd:
- Hardware is an **ASUS TUF Gaming F15 FX507ZC4**. It is a TUF laptop, not a ROG one, but asusctl applies to both.
- Software: plasma-desktop 6.8.0, Qt 6.12.0, nvidia-utils 615.78.08.
- **The display manager is Plasma Login Manager** (`display-manager.service -> plasmalogin.service`, package `extra/plasma-login-manager 6.8.0`). **SDDM is not installed.** This decides the SDDM section below.
- `extra/asusctl 6.5.0` and `extra/rog-control-center 6.5.0` are installed already.
- Repos enabled: cachyos-v3, cachyos-extra-v3, cachyos-core-v3, cachyos, core, extra and multilib. **Chaotic-AUR is not enabled.**
- AUR versions and dates in this file come from the AUR RPC API (`https://aur.archlinux.org/rpc/v5/info|search`), queried 2026-10-16. Package pages are at `https://aur.archlinux.org/packages/<name>`.

## Q1. SDDM / login themes that work with Qt6 and look futuristic

### Takeaway
sddm-astronaut-theme (Keyitdev) is still the best futuristic SDDM theme for Qt6. It has a Cyberpunk preset, an animated Hyprland Kath preset and a "Post-apocalyptic hacker" preset. **But this laptop runs KDE's new Plasma Login Manager instead of SDDM, so SDDM themes do nothing unless the user switches back to SDDM.** Sugar Candy forks are outdated.

### Cited Findings
- sddm-astronaut-theme requirements: SDDM ≥ 0.21.0 and Qt ≥ 6.8, plus Qt SVG, Qt Virtual Keyboard and Qt Multimedia. Extra video codecs such as H.264 are suggested for the animated presets — [GitHub Keyitdev/sddm-astronaut-theme](https://github.com/Keyitdev/sddm-astronaut-theme)
- Its presets include Astronaut, Black hole, Japanese aesthetic, Pixel sakura (static and animated), Purple leaves, **Cyberpunk**, **Post-apocalyptic hacker**, **Hyprland Kath (animated)** and Jake the dog (animated). You pick one in `metadata.desktop` — [GitHub](https://github.com/Keyitdev/sddm-astronaut-theme)
- Install: a `setup.sh` script (supports pacman), or a manual clone into `/usr/share/sddm/themes/sddm-astronaut-theme` and editing `/etc/sddm.conf` plus `/etc/sddm.conf.d/virtualkbd.conf` — [GitHub](https://github.com/Keyitdev/sddm-astronaut-theme)
- AUR package `sddm-astronaut-theme` is at version 62.8f41a83-1, last modified 2025-01-24. That is older than upstream git, so installing from git or the script is the fresher option — [AUR](https://aur.archlinux.org/packages/sddm-astronaut-theme)
- Sugar Candy: `sddm-sugar-candy-git` was last modified 2024-12-25 and has popularity 0.03. `sddm-theme-sugar-candy-git` was last touched 2019. Forum users report that old Sugar/Sweet-based SDDM themes "don't work in Plasma 6" — [AUR sddm-sugar-candy-git](https://aur.archlinux.org/packages/sddm-sugar-candy-git); [EndeavourOS forum](https://forum.endeavouros.com/t/plasma-login-manager-6-6-0/77459)
- Other SDDM themes on the AUR that were maintained in 2026 (not themed or futuristic-checked): `sddm-theme-aurora-greeter-git` (2026-09-11), `sddm-theme-noctalia-git` (2026-02-27) and `sddm-theme-elegant-archlinux-git` (2026-02-09) — [AUR search](https://aur.archlinux.org/packages?K=sddm-theme)
- Plasma Login Manager (PLM) is new as of Plasma 6.6, per a KDE Discuss thread. A forum user believes PLM is limited to Breeze theming. Another post says PLM has its own KCM for appearance. I found **no official statement** that SDDM QML themes work in PLM — [KDE Discuss](https://discuss.kde.org/t/apt-upgrade-on-neon-asks-selecting-default-display-manager-plasmalogin-or-sddm/47801); [EndeavourOS forum](https://forum.endeavouros.com/t/plasma-login-manager-6-6-0/77459)
- PLM config is reportedly `/etc/plasmalogin.conf`, which overrides `/usr/lib/plasmalogin/defaults.conf`. This is an unverified forum claim — [EndeavourOS forum](https://forum.endeavouros.com/t/plasma-login-manager-6-6-0/77459)
- Smart Video Wallpaper Reborn says it can play video on the **login screen** when Plasma Login Manager is used instead of SDDM. That gives an animated cyberpunk login without SDDM — [GitHub luisbocanegra/plasma-smart-video-wallpaper-reborn](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn)
- Some Plasma 6 SDDM themes ship with global themes, for example L4ki's Motto and Breeze-Noir-Dark — [GitHub L4ki/Motto-Plasma-Themes](https://github.com/L4ki/Motto-Plasma-Themes)
- `kde-lockscreen-builder` is a live-preview dev environment for SDDM themes on Plasma 6 — [GitHub derryl/kde-lockscreen-builder](https://github.com/derryl/kde-lockscreen-builder)

### Inferences
- On this machine there are two options:
  - **(a)** Stay on PLM. Theme it with a cyberpunk wallpaper or video through Smart Video Wallpaper Reborn's login-screen support, and keep matching colours.
  - **(b)** Install `sddm`, enable it in place of plasmalogin, then use sddm-astronaut-theme's cyberpunk or hacker preset. Option (b) means leaving KDE's default login path, which could break on future updates.
- The animated astronaut presets use QtMultimedia video. On the NVIDIA hybrid laptop the greeter normally renders on the iGPU, so this should be cheap (inference, not tested).

### Gaps
- No official KDE documentation was found on PLM third-party theme support. The invent.kde.org page did not expose its README.
- I did not check the date of the latest upstream commit to sddm-astronaut-theme. The page shows © 2022–2025 and 92 commits.

## Q2. Icon packs and cursors for a neon/gamer look

### Takeaway
All of the main icon families are packaged and current in 2026:
- Tela (updated 2026-07)
- Papirus, in [extra], with `papirus-folders` for coloured folders
- Kora (2026-08)
- Fluent (2026-08)
- BeautyLine (the Garuda icons, in the [cachyos] repo)

The original Candy icons and Reversal are stale on the AUR, but `neo-candy-icons` is a maintained successor. For cursors, Bibata (2026-09) is the safe pick. Sweet cursors were refreshed in 2026-04.

### Cited Findings
- `tela-icon-theme` 2026.07.07-1, modified 2026-07-09 — [AUR](https://aur.archlinux.org/packages/tela-icon-theme)
- `papirus-icon-theme` 20260801-1 is in the official [extra] repo (local `pacman -Ss`). `papirus-folders` 1.14.0-1 was modified 2026-10-03. It recolours folders to red, magenta, cyan and other colours — [AUR](https://aur.archlinux.org/packages/papirus-folders)
- `kora-icon-theme` 2.0.6-1, modified 2026-08-24 — [AUR](https://aur.archlinux.org/packages/kora-icon-theme)
- `fluent-icon-theme` 20260727-1, modified 2026-08-13 — [AUR](https://aur.archlinux.org/packages/fluent-icon-theme)
- `colloid-icon-theme-git`, modified 2025-08-02 — [AUR](https://aur.archlinux.org/packages/colloid-icon-theme-git)
- `candy-icons-git` was last modified **2021-05-31**, so the AUR package is stale. `neo-candy-icons` 26.03_01-1 (2026-06-27) and `neo-candy-icons-git` (2026-07-02) are maintained — [AUR candy-icons-git](https://aur.archlinux.org/packages/candy-icons-git); [AUR neo-candy-icons](https://aur.archlinux.org/packages/neo-candy-icons)
- `sweet-folders-icons-git` was last modified 2024-03-07 — [AUR](https://aur.archlinux.org/packages/sweet-folders-icons-git)
- `reversal-icon-theme-git` was last modified **2021-06-06** (outdated) — [AUR](https://aur.archlinux.org/packages/reversal-icon-theme-git)
- `beautyline` 2:3.0.5-1 is in the **[cachyos] repo** (local `pacman -Ss`). BeautyLine is the neon-gradient icon set Garuda Dr460nized uses — [next.ink on Garuda](https://next.ink/1835/linux-coloree-garuda-se-distingue-par-son-esthetique-et-ses-performances/); [EndeavourOS thread](https://forum.endeavouros.com/t/trying-to-replicate-garuda-linuxs-kde-theming-on-endeavouros-plasma-kde/29895?page=2)
- Cursors:
  - `bibata-cursor-theme` 2.0.7-1, modified 2026-09-07 — [AUR](https://aur.archlinux.org/packages/bibata-cursor-theme)
  - `sweet-cursors-git`, modified 2026-04-19, with a `sweet-cursors-hyprcursor-git` variant — [AUR](https://aur.archlinux.org/packages/sweet-cursors-git)
  - `breeze-hacked-cursor-theme-git`, modified 2024-05-18 — [AUR](https://aur.archlinux.org/packages/breeze-hacked-cursor-theme-git)
  - `catppuccin-cursors-*` 2.0.0, modified 2025-02-22 — [AUR](https://aur.archlinux.org/packages/catppuccin-cursors-mocha)
- A "cyberpunk technotronic" icon theme appeared in KDE Store aggregator listings. It was not verified — [dot.kde.org aggregator](https://dot.kde.org/aggregator/sources/2?page=97)

### Inferences
- **Neon/Sweet look:** BeautyLine (repo) or neo-candy-icons, with Sweet cursors.
- **ROG red/black look:** Papirus-Dark with `papirus-folders -C red`, or Tela "red-dark" (Tela ships colour variants), with Bibata-Modern-Classic cursors.
- **Clean sci-fi look:** Fluent-dark or Kora with Bibata.

### Gaps
- No AUR package was found for "Future cursors" (`future-cursors` gave no result). It may only be on the KDE Store or GitHub; not verified.
- I did not open each icon theme's repo to confirm Plasma 6-specific issues. Icon themes are toolkit-agnostic, so the risk is low.

## Q3. Animated wallpapers: Wallpaper Engine plugin and Smart Video Wallpaper Reborn

### Takeaway
**The catsout Wallpaper Engine KDE plugin was archived on 2026-06-06 and moved to a new project, Waywallen.** Waywallen is now packaged on the AUR (0.4.x, Oct 2026) with a Plasma integration package. Smart Video Wallpaper Reborn (luisbocanegra) is the most mature video wallpaper option for Plasma 6. It has pause-on-maximize and battery-mode features and documented NVIDIA backends.

### Cited Findings
- catsout/wallpaper-engine-kde-plugin is "archived by the owner on Jun 6, 2026" and read-only. The README says it has "Moved to https://github.com/waywallen/waywallen" — [GitHub catsout](https://github.com/catsout/wallpaper-engine-kde-plugin)
- The old AUR `plasma6-wallpapers-wallpaper-engine-git` was last modified 2025-12-15 (0.5.4.r118) — [AUR](https://aur.archlinux.org/packages/plasma6-wallpapers-wallpaper-engine-git)
- Waywallen: a "Wallpaper Manager for Linux" that "started life as a Wallpaper Engine plugin for KDE".
  - Supports image and video wallpapers (Vulkan/VA-API hardware decoding) and Wallhaven. Scene and web Wallpaper Engine wallpapers come through third-party plugins such as open-wallpaper-engine, which run with user privileges.
  - Integrates with KDE Plasma (via waywallen-display), GNOME, Hyprland, Niri, Wayfire, COSMIC and Sway, with auto-pause.
  - — [GitHub waywallen](https://github.com/waywallen/waywallen)
- Waywallen NVIDIA notes:
  - A recent driver has an EGL bug, so set `QSG_RHI_BACKEND=vulkan` for plasmashell.
  - Web wallpapers need `shared_texture_enabled` disabled.
  - There is no NVDEC backend; use nvidia-vaapi-driver.
  - — [GitHub waywallen](https://github.com/waywallen/waywallen)
- Waywallen AUR packages: `waywallen` 0.4.4-1 (2026-10-07), `waywallen-bin`, and `plasma-wallpaper-waywallen` plus `waywallen-display` 0.4.2-1 (2026-10-14). It also ships as an AppImage and on Flathub — [AUR plasma-wallpaper-waywallen](https://aur.archlinux.org/packages/plasma-wallpaper-waywallen); [GitHub](https://github.com/waywallen/waywallen)
- Smart Video Wallpaper Reborn:
  - A Plasma 6 plugin that plays video on the desktop and lock screen, and on the login screen with PLM.
  - Pauses when a maximized or fullscreen window is open, when any window is active, during Overview or Show Desktop, or when the screen is off or locked.
  - **Battery mode** pauses the video and disables blur below a set battery threshold.
  - — [GitHub](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn)
- Smart Video Wallpaper Reborn on NVIDIA:
  - The README recommends hardware decoding and checking it with nvtop.
  - For NVIDIA-only or mixed-vendor systems it suggests the FFmpeg-with-CUDA backend, or FFmpeg-Vulkan if NVIDIA is the primary renderer.
  - Forcing VA-API needs that vendor's kernel module loaded.
  - — [GitHub](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn)
- AUR `plasma6-wallpapers-smart-video-wallpaper-reborn` 2.16.0-1, modified 2026-10-04. It is also on the KDE Store at store.kde.org/p/2139746 — [AUR](https://aur.archlinux.org/packages/plasma6-wallpapers-smart-video-wallpaper-reborn); [KDE Store](https://store.kde.org/p/2139746)
- `plasma6-applets-wallpaper-effects` 2.1.1 (2026-05-23) is also from the luisbocanegra ecosystem, though authorship was not verified — [AUR](https://aur.archlinux.org/packages/plasma6-applets-wallpaper-effects)

### Inferences
- On a hybrid RTX 3050 laptop, the low-power choice is Smart Video Wallpaper Reborn decoding on the **Intel iGPU via VA-API** (intel-media-driver), with pause-on-maximize and battery mode on. Decoding on NVIDIA wakes the dGPU and costs battery (inference).
- Waywallen is the only path for actual Wallpaper Engine scene wallpapers. At 0.4.x it is young, and its NVIDIA EGL bug note means extra setup. Treat it as experimental.
- The old `plasma6-wallpapers-wallpaper-engine-git` should be treated as **deprecated**.

### Gaps
- I found no measured numbers for battery or GPU cost of either plugin. The READMEs only give qualitative advice.

## Q4. Garuda Dr460nized on a non-Garuda Arch / CachyOS system

### Takeaway
Dr460nized is Garuda's Plasma rice. It uses the Sweet theme family (sweetified Plasma style), the Kvantum dark engine, BeautyLine icons and the Fira fonts / FiraCode Nerd Font. It moved to Plasma 6 in release 240428 (April 2024). `garuda-dr460nized` is **not on the AUR**. It is a Garuda package distributed through Chaotic-AUR / Garuda repos, and users report dependency breakages. Rebuilding the look by hand from its parts is more robust on CachyOS.

### Cited Findings
- GitLab project `garuda-linux/themes-and-settings/settings/garuda-dr460nized`: "Dr460nized settings for Garuda Linux", topics dotfiles, GPL-3.0+, created 2020-11-08, 439 commits, 72 releases. The project wiki is empty — [GitLab](https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized)
- Dr460nized uses the Kvantum engine with the "sweetified" Plasma theme (kvantum-dark) and BeautyLine icons — [next.ink](https://next.ink/1835/linux-coloree-garuda-se-distingue-par-son-esthetique-et-ses-performances/)
- One user rebuilt the look on EndeavourOS with these packages: `beautyline` (icons), `sweet-gtk-theme`, `sweet-kvantum-theme-git`, `sweet-kde-theme-git` and `ttf-fira-sans`. They hit a Chaotic-AUR PGP signature error — [EndeavourOS forum](https://forum.endeavouros.com/t/trying-to-replicate-garuda-linuxs-kde-theming-on-endeavouros-plasma-kde/29895?page=2)
- The Dr460nized edition moved to Plasma 6 in Garuda 240428 "Bird of Prey" — [linuxiac](https://linuxiac.com/?p=113405); [tuxmachines](https://news.tuxmachines.org/n/2024/04/29/Arch_Linux_Based_Garuda_Linux_Bird_of_Prey_Distro_Lands_with_KD.shtml)
- Garuda packages "were never in the AUR… They are garuda specific packages". Chaotic-AUR is a separate binary repo — [Garuda forum](https://forum.garudalinux.org/t/does-garuda-ship-aur-packages-by-default/24379)
- Known dependency breakages of `garuda-dr460nized` include losing `nerd-fonts-fira-code` and `sweet-theme-full-git` — [Garuda forum 24566](https://forum.garudalinux.org/t/latest-update-breaks-dependency-required-by-garuda-dr460nized/24566); [Garuda forum 31873](https://forum.garudalinux.org/t/garuda-update-removing-sweet-theme-full-git-breaks-dependency-required-by-garuda-dr460nized/31873)
- The full package list of the Dr460nized ISO is published at `https://iso.builds.garudalinux.org/iso/latest/garuda/dr460nized/latest.pkgs.txt` (link from a Garuda forum reply; not fetched) — [Garuda forum](https://forum.garudalinux.org/t/latest-update-breaks-dependency-required-by-garuda-dr460nized/24566)
- Relevant AUR packages on 2026-10-16:
  - `sweet-kde-theme-git` (modified 2026-04-19)
  - `sweet-cursors-git` (2026-04-19)
  - `plymouth-theme-dr460nized-sweet-git` (2022-10-26, stale)
  - — [AUR sweet-kde-theme-git](https://aur.archlinux.org/packages/sweet-kde-theme-git); [AUR plymouth-theme-dr460nized-sweet-git](https://aur.archlinux.org/packages/plymouth-theme-dr460nized-sweet-git)
- The CachyOS repos already have `beautyline` and `kvantum` 1.1.8 (local `pacman -Ss`).
- KDE Store has "Sweet Mars LAF Plasma 6" (store.kde.org/p/2166424) and "Utterly Sweet Global for Plasma 6". The page content could not be read in detail — [KDE Store Sweet Mars](https://store.kde.org/p/2166424)
- The EliverLara/Sweet main GitHub branch is described as "A beautiful theme with neon vibes for GNOME". The KDE parts live in other branches or the Sweet-kde repo (not verified on the page) — [GitHub EliverLara/Sweet](https://github.com/EliverLara/Sweet)

### Inferences
- Recommended way to get the look on CachyOS without Chaotic-AUR:
  1. `pacman -S beautyline kvantum`
  2. From the AUR: `sweet-kde-theme-git`, `sweet-cursors-git`, plus a Sweet Kvantum theme
  3. FiraCode Nerd Font (`ttf-firacode-nerd`, assumed to be in [extra]; not verified)
  4. Copy Garuda's Konsole/fish configs from the GitLab repo by hand
- Adding Chaotic-AUR only to pull in `garuda-dr460nized` brings Garuda-specific defaults and the known dependency breakages. It is not recommended on CachyOS (inference).

### Gaps
- I could not read the `garuda-dr460nized` PKGBUILD. `-/raw/master/PKGBUILD` and `-/raw/main/PKGBUILD` both returned 404, so the exact depends and file list, and the exact Konsole/fish/panel content, are unverified.
- I did not verify the current Chaotic-AUR availability or version of `garuda-dr460nized`.
- Nobara and Bazzite KDE theming were not researched, for lack of time. Both mostly ship near-stock Breeze (unverified).
- CachyOS's own KDE theming: the system has `cachyos-plymouth-theme` and `cachyos-plymouth-bootanimation` installed. CachyOS's KDE settings package was not investigated.

## Q5. ROG/ASUS-specific theming, and gamer/cyberpunk all-in-one packs

### Takeaway
I found **no maintained "ROG" or "Republic of Gamers" global theme for Plasma 6** on the KDE Store or GitHub. ROG theming on Linux comes down to a ROG GRUB theme, the asusctl / ROG Control Center tooling (already installed here), red/black colour schemes and wallpapers. There is also no well-known maintained cyberpunk global theme for Plasma 6. Plasma 6.6+ can save your current setup as a custom global theme, so a DIY ROG/cyberpunk global theme is the practical route.

### Cited Findings
- Searches of the KDE Store and GitHub for ROG / Republic of Gamers Plasma 6 themes returned nothing relevant — [KDE Store red tag](https://store.kde.org/browse?tag=red)
- Red/dark candidates on the KDE Store:
  - "Red Pastel" Global Theme (Plasma 6)
  - ArchRed, a Plasma 5-era theme at v0.1 (flag as outdated) — [GitHub tsbarnes/ArchRed](https://github.com/tsbarnes/ArchRed)
  - "Red Dot Black" Aurorae, with Plasma 6 status unclear
  - — [KDE Store red tag](https://store.kde.org/browse?tag=red)
- `grub-theme-asus-rog` 3.4-2, modified 2025-07-09, popularity 0.78 — [AUR](https://aur.archlinux.org/packages/grub-theme-asus-rog)
- `asusctl` 6.5.0 and `rog-control-center` 6.5.0 are in the official [extra] repo (local pacman). The AUR variants `asusctl-x11` and `rog-control-center-x11` are flagged out of date. `rogctl` 2.4.3 was modified 2026-10-14 (purpose not verified) — [AUR rogctl](https://aur.archlinux.org/packages/rogctl)
- Plasma 6.6 added saving the current look (colours, decorations, icons and so on) as a new global theme — [linuxiac](https://linuxiac.com/kde-plasma-6-6-lets-users-create-custom-global-themes/)
- Plasma 6.7 (June 2026) brought per-screen virtual desktops on Wayland and **Union, a new CSS-based theming system** — [itsfoss](https://itsfoss.com/news/kde-plasma-6-7-release.md)
- GTK-side cyberpunk: `gtk-cyberpunk-neon-theme-git` (2022-08-09, stale) and `cyberpunk-grub-theme-git` (2021, stale) — [AUR search cyberpunk](https://aur.archlinux.org/packages?K=cyberpunk)

### Inferences
- The machine is a TUF F15. asusctl can set keyboard RGB (aura modes) to match the theme accent colour, which is the most "gamer" cross-component touch (inference; asusctl aura commands not verified here).
- For a ROG look, combine:
  - the `grub-theme-asus-rog` GRUB theme
  - a red accent colour scheme with a dark Breeze/Kvantum base
  - Papirus `-C red` folders
  - Bibata cursors
  - a ROG video wallpaper through Smart Video Wallpaper Reborn
  
  Then save the result as a global theme (Plasma 6.6+).

### Gaps
- No ROG Plymouth theme or ROG global theme was verified. KDE Store search pages render poorly through the fetch tool, so a manual search on store.kde.org for "ROG" is still needed.
- I did not check whether Union (Plasma 6.7) breaks older Plasma styles or Kvantum themes.

## Q6. Plymouth splash, Konsole/terminal themes, fastfetch, and Plasma widgets

### Takeaway
Plymouth has `plymouth-kcm` and Breeze/CachyOS themes in the repos, and an ROG GRUB theme on the AUR, but the cyberpunk Plymouth packages are mostly stale. The catppuccin Plymouth themes (2024) and `plymouth-theme-bgrt-nerd-git` (2026-08) are maintained. The Plasma 6 widget ecosystem is very active:
- Panel Colorizer 8.0.0, for neon or transparent panels
- Audio Visualizer, for a media visualizer
- Thermal Monitor, for CPU/GPU temperatures
- Kurve
- Kara

Konsole colour schemes on the AUR are few, so most come from GitHub.

### Cited Findings
- Plymouth in the repos: `cachyos-plymouth-theme`, `cachyos-plymouth-bootanimation`, `holo-plymouth-themes` (the Steam Deck "Holo" boot, a gamer look), `breeze-plymouth 6.8.0` and `plymouth-kcm 6.8.0` (local `pacman -Ss`).
- AUR Plymouth packages:
  - `plymouth-theme-catppuccin-*-git` (2024-08-17)
  - `plymouth-theme-bgrt-nerd-git` (2026-08-27)
  - `plymouth-theme-mikuboot-git` (2024-10-17)
  - `plymouth-theme-dr460nized-sweet-git` (2022, stale)
  - — [AUR plymouth-theme search](https://aur.archlinux.org/packages?K=plymouth-theme)
- Plasma 6 widgets on the AUR, with modification dates:
  - `plasma6-applets-panel-colorizer` 8.0.0 (2026-08-11, popularity 2.43)
  - `plasma6-applets-audio-visualizer` 3.6.1 (2026-09-04)
  - `plasma6-applets-thermalmonitor` 0.2.8 (2026-08-22)
  - `plasma6-applets-kurve-git` 3.6.1 (2026-10-03)
  - `plasma6-applets-kara` 1.0.0 (2026-07-12)
  - `plasma6-applets-fokus` 3.1.3
  - `plasma6-applets-vutronmusic-lyrics` 26.10.8 (2026-10-10)
  - `plasma6-applets-appgrid` 1.9.3
  - — [AUR search plasma6-applets](https://aur.archlinux.org/packages?K=plasma6-applets)
- Konsole colour schemes on the AUR:
  - `catppuccin-konsole-colorscheme-*-git` (2025-06-09)
  - `konsole-colorscheme-matchama` (2025-12-11)
  - `konsole-dracula-git` (2021, stale)
  - — [AUR search konsole](https://aur.archlinux.org/packages?K=konsole)
- Fastfetch helpers: `fastfetch-configs-git` (2026-08-20), `fastfetch-theme-manager` 2.0.0 (2025-12-07), `fastfetch-configurator` 1.2 (2026-04-17) — [AUR search fastfetch](https://aur.archlinux.org/packages?K=fastfetch)

### Inferences
- For a gamer HUD desktop:
  - Panel Colorizer, for neon borders and translucent floating panels
  - Thermal Monitor for CPU/GPU temperatures, with Plasma's built-in System Monitor sensor widgets for GPU load
  - Audio Visualizer as a media/beat bar
  - Kurve, an audio visualizer according to its name; not verified
- For a neon Konsole: Sweet's Konsole scheme (in sweet-kde-theme) or a Dracula/Cyberpunk scheme from GitHub, set in Konsole profile colours. A fastfetch config with an ASUS/ROG logo can be built with `fastfetch-configs-git` presets (inference).

### Gaps
- I did not verify the GitHub URLs or Wayland/NVIDIA GPU-sensor behaviour of each widget. Whether Thermal Monitor reads the NVIDIA dGPU without waking it is unknown. Polling nvidia-smi can keep the dGPU awake on hybrid laptops, which is a known general concern but was not sourced here.
- No specific maintained "cyberpunk 2077" Konsole scheme or Plymouth theme was verified in 2026.
- Out of scope / not done for time: Nobara and Bazzite KDE, CachyOS KDE settings package contents, and r/unixporn Plasma 6 cyberpunk dotfiles.
