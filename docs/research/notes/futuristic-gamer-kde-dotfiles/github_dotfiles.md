# Futuristic / cyberpunk / gamer KDE Plasma 6 dotfiles and theme suites (GitHub/AUR survey, as of 2026-10-16)

Method note: Repo metadata (stars, last push, license) came from the GitHub REST API on 2026-10-16. After about 30 calls the API rate-limited this IP, so some repos have no star or date figures (marked "n/v", not verified). READMEs came from raw.githubusercontent.com. AUR data came from the AUR RPC v5. r/unixporn could only be reached through mirror/aggregator pages, and those turned up no concrete cyberpunk Plasma 6 repo links, so this list is GitHub-centric. Stars are as of 2026-10-16. Most bespoke cyberpunk rices are very new (2026) and have very few stars, so they are unproven.

## Q1. Candidate list: name, URL, author, components, installer, Plasma version claimed, Wayland, last activity, stars, license

### Takeaway
I found 20+ relevant repos. The strongest full-suite cyberpunk/gamer candidates for a CachyOS + Plasma 6.7/6.8 Wayland + Plasma Login Manager target are:
- **NEONGRID** (cromewar): built for exactly CachyOS / Plasma 6.7 / Wayland / plasmalogin.
- **Neon District** (coex177): Plasma 6.7, Wayland, plasmalogin greeter support.
- **Arasaka KDE** (sne11ius): Plasma 6.7, Wayland, PLM login.
- **Crimson Glass** (SirFork1988): red/black glass gamer look, CachyOS source, already patched for 6.8, but its login theme targets SDDM.
- **CyberKDE** (jrcn1991).
- **Bitpunk** (bitr8).
- **Daemon MK2** (MathisP75).
- **Tron Legacy** (chasperli).

None of the bespoke rices explicitly claims Plasma 6.8 except Crimson Glass, whose v1.1.1 includes a 6.8 login repair.

### Cited Findings

**A. Full cyberpunk/neon rices (bespoke, Plasma 6)**

1. **NEONGRID**, by cromewar: https://github.com/cromewar/neongrid
   - **Look:** neon green with violet/magenta accents, transparency, blur and glow. Live GLSL wireframe wallpaper, translucent panel with neon edge and bloom, floating dock.
   - **Components:** one `palette.sh` drives KDE colors, Darkly app style, Klassy decoration (accent outline and coloured glow shadow), Better Blur DX force-blur, Panel Colorizer panels, kde-shader-wallpaper, hue-snapped icon theme, cursor, GTK3/4 CSS, Ghostty, btop, fzf, starship, fish/zsh, Plymouth, Limine boot menu, plasmalogin greeter and lock screen. It also rebuilds a two-panel layout: a 64px floating dock plus a 34px top bar.
   - **Installer:** yes. One-line `net-install.sh`, a TUI, `--dry-run`, and a snapper snapshot before changes. "Tested on CachyOS + Plasma 6.7.2 + Wayland." Steps for Limine, Plymouth and plasmalogin are skipped automatically when those aren't present.
   - **Repo stats:** 1 star, last push 2026-08-15, no license file (GitHub API).
   - **Notable:** it themes Plasma Login Manager by pointing `WallpaperPluginId` at the shader wallpaper. The README says "plasmalogin cannot use QML themes at all", so its only appearance hook is the wallpaper plugin. — [README](https://github.com/cromewar/neongrid)

2. **Neon District**, by coex177: https://github.com/coex177/neon-district-plasma
   - **Look:** cyberpunk, generated from `palette.py`. Three variants: cyan/magenta, ember (orange/teal) and violet.
   - **Components:** colour scheme, Plasma style, Kvantum theme, icon set (derived from breeze-dark at build time), procedural 4K wallpaper, Konsole profile, splash, GTK overlay and global theme.
   - **Installer:** yes (`build.sh`, `install.sh <variant>`, `switch.sh`, `uninstall.sh`). `sudo ./install-system.sh` points the plasmalogin greeter at the theme.
   - **Versions:** "Built and tested on Fedora 44 / KDE Plasma 6.7 / Wayland."
   - **Repo stats:** 0 stars, last push 2026-08-31, MIT.
   - **Blur:** none mentioned; it relies on Kvantum. — [README](https://github.com/coex177/neon-district-plasma)

3. **Arasaka KDE**, by sne11ius: https://github.com/sne11ius/arasaka-kde
   - **Look:** "rain-soaked, neon-red desktop for KDE Plasma 6" (Cyberpunk 2077 Arasaka). Interactive shader rain wallpaper shared across desktop, lock screen and PLM login.
   - **Components:** search-first launcher, automatic binary-tree tiling, TV Glitch window transitions (Burn-My-Windows), and a palette across Plasma, Klassy, Kvantum, Konsole, GTK accents, browser chrome and a Zsh prompt. Credits Better Blur DX, Daemon, Silent KLockscreen and Klassy.
   - **Installer:** yes (`./bin/apply-live` plus per-component scripts; `./bin/build-plm` builds the login packages). Warning: "no full-desktop dry-run or transactional rollback."
   - **Versions:** target is "TUXEDO OS on Debian testing/forky, amd64, Plasma 6.7, Wayland".
   - **Repo stats:** 1 star, last push 2026-10-15. EUPL-1.2, but some shaders carry non-commercial/share-alike terms. — [README](https://github.com/sne11ius/arasaka-kde)

4. **CyberKDE**, by jrcn1991: https://github.com/jrcn1991/theme-cyberkde
   - **Look:** "Neo-military cyberpunk" inspired by Cyberpunk 2077 menus. Default red; `cyberkde cor '#hex'` regenerates any accent.
   - **Components:** colour scheme, chamfered Kvantum style, Aurorae decoration with a KWin "scan" open/close animation, Plasma style with a popup animation, icons, Konsole, SDDM login, splash, lock screen, wallpapers, and a top bar plus dock layout. Optional patched animated Dolphin/Konsole (Ubuntu 26.04 only).
   - **Installer:** yes (`./instalar.sh --ligar`). Fully reversible `cyberkde off`. The CLI is in Portuguese.
   - **Versions:** tested on Kubuntu/Ubuntu 26.04, Plasma 6.6, Wayland.
   - **Repo stats:** 0 stars, last push 2026-10-03. GPL-3.0 code, CC BY-SA artwork.
   - **Also:** published on the KDE Store. — [README](https://github.com/jrcn1991/theme-cyberkde)

5. **Bitpunk**, by bitr8: https://github.com/bitr8/bitpunk-theme
   - **Look:** "Complete KDE Plasma 6 cyberpunk theme", cyan #0ABDC6 with magenta/yellow on OLED black.
   - **Components:** colour scheme, Plasma theme, animated KSplash, Plymouth, Konsole/Kitty/Ghostty, GTK, Conky sensor widget, SDDM, wallpaper, Bibata cursor, and Papirus with cyan folders.
   - **Installer:** yes (`install.sh` / `uninstall.sh`). SDDM and Plymouth are manual.
   - **Repo stats:** 15 stars, last push 2026-02-06, GPL-3.0.
   - **Gaps:** no Kvantum, no blur effect, no explicit Wayland claim. — [README](https://github.com/bitr8/bitpunk-theme)

6. **Daemon / Daemon MK2**, by MathisP75. v1: https://github.com/MathisP75/daemon-dotfiles. v2: https://github.com/MathisP75/daemon-kde-mk2
   - **v1:** "Cyberpunk style theme for KDE". 127 stars, last push 2024-03-26, GPL-3.0. Era-wise it is Plasma 5 (it references Qt5 settings and Kvantum in qt5ct).
   - **MK2:** "Version 2.0 of the Daemon global theme for KDE Plasma 6", inspired by Cyberpunk 2077 (red/cyan).
   - **MK2 components:** colour scheme, Kvantum, icons, Plasma style, Aurorae decoration, Konsole, Kitty, VSCode. It recommends a TV Glitch (Burn-My-Windows) effect, Cube, Rajdhani/Orbitron fonts and a widget list.
   - **MK2 installer:** manual copy. There is an LLM-made install script that the author warns against using. Components are also on Pling.
   - **MK2 stats:** stars, date and license n/v (API rate limit).
   - **Influence:** Arasaka KDE credits Daemon, and an Omarchy port exists (Doghouse-Mike/omarchy-daemon-mkii-theme). — [v1 README](https://github.com/MathisP75/daemon-dotfiles); [MK2 README](https://github.com/MathisP75/daemon-kde-mk2)

7. **Tron Legacy KDE Theme**, by chasperli: https://github.com/chasperli/tron-legacy-kde-theme
   - **Look:** neon-cyan global theme.
   - **Components:** Plasma style, Aurorae with glow, generated neon icons, cursors (SVG for Wayland plus Xcursor), animated QML splash, animated lock screen/screensaver, SDDM, wallpapers, Konsole/Kate/Vim/Neovim/VSCode schemes, and a Podman container-monitor plasmoid.
   - **Installer:** yes (`install.sh`).
   - **Versions:** "KDE Plasma 6".
   - **Repo stats:** 0 stars, last push 2026-10-09, GPL-2.0. — [README](https://github.com/chasperli/tron-legacy-kde-theme)

8. **Neon Noir**, by geosem42: https://github.com/geosem42/kde-neonnoir
   - **Look:** "Work in progress", cyan/magenta on blue-black.
   - **Components:** colour scheme, global theme and splash, Plasma style, Aurorae, Kvantum, icons (4,598 generated), sysmon and options plasmoids, wallpaper, Konsole, Kate, GTK3/4/libadwaita, VS Code, Firefox userChrome, kwinrc effects, SDDM and Plymouth.
   - **Installer:** yes, idempotent, with `--dry-run` and backup.
   - **Versions:** "Kubuntu 26.04 / KDE Plasma 6.6 (Wayland, Qt 6)".
   - **Repo stats:** 0 stars, last push 2026-09-20, no license. — [README](https://github.com/geosem42/kde-neonnoir)

9. **Crimson Glass**, by SirFork1988 (red/black gamer, ROG-like): https://github.com/SirFork1988/Crimson-Glass
   - **Look:** "black and ruby-red glass theme for KDE Plasma 6" with translucent windows.
   - **Components:**
     - 26k-name crimson icon pack, Kvantum for Qt5/Qt6 plus a separate glass Dolphin style, GTK2/3/4 and Konsole.
     - Andromeda launcher, global menu, floating dock and matching cursors.
     - Five system-monitor widgets, Magic Lamp effect, SDDM, KSplash and Plymouth.
     - A "game opacity policy" that keeps Steam, Proton and fullscreen game windows opaque.
   - **Installer:** yes (`install.sh --all`, `--dry-run`, `--no-layout`, `restore.sh`, and SHA-256 manifests).
   - **Versions:** the visual source is "CachyOS with Plasma 6.7.5, Qt 6.11.2, and Kvantum 1.1.8".
   - **Plasma 6.8:** v1.1.1 adds a "Repair login after upgrading to Plasma 6.8", because Plasma 6.8 removed Breeze's `VirtualKeyboardLoader`, which broke its SDDM theme.
   - **Repo stats:** 7 stars, last push 2026-10-16. MIT installer; components keep upstream licenses (Papirus, Tela, WhiteSur, Qogir and others). — [README](https://github.com/SirFork1988/Crimson-Glass)

10. **sanguine-node-rice**, by petrolal: https://github.com/petrolal/sanguine-node-rice
    - **Look:** "cyberpunk and monochromatic" / "Biopunk", obsidian with crimson accents.
    - **Components:** Panel Colorizer floating capsule presets ("Main Blur"), KWin Wayland force blur (Better Blur DX), Zen Browser glass userChrome, Monochrome KDE colors, YAMIS icons, Bibata cursor, Smart Video Wallpaper Reborn (desktop, lock and login), YoRHa HUD telemetry widget, Kurve CAVA visualizer, Thermal Monitor and Konsole.
    - **Installer:** yes. A Babashka/Clojure engine resolves pacman, AUR and git dependencies; there is also a NixOS guide.
    - **Versions:** "Arch Linux / CachyOS / NixOS, KDE Plasma 6.7+, Wayland native".
    - **Repo stats:** 1 star, last push 2026-10-01, GPL-3.0.
    - **Caution:** the default video wallpaper filename suggests NSFW content. — [README](https://github.com/petrolal/sanguine-node-rice)

11. **Imperial Geass Noir**, by Sir-Starch: https://github.com/Sir-Starch/imperial-geass-noir
    - **Look:** black, noir purple, crimson and gold, with "thin HUD lines, glass-like surfaces".
    - **Components:** colour scheme, Plasma theme, look-and-feel, Aurorae, recoloured Papirus icons, a top-panel layout script, wallpapers (including ultrawide), Kitty/Konsole/Alacritty/Ghostty/WezTerm, shell prompts, VS Code and Fastfetch HUD.
    - **Versions:** "Wayland-first", Plasma 6, v1.0.1.
    - **Repo stats:** 4 stars, last push 2026-09-21, license NOASSERTION. — [README](https://github.com/Sir-Starch/imperial-geass-noir)

12. **Mystical Blue Theme**, by juxtopposed: https://github.com/juxtopposed/Mystical-Blue-Theme
    - **Look:** a futuristic blue glass look (the "No Man's Sky" Kvantum base). This is the most-starred Plasma 6 rice in the topic: 1,242 stars, last push 2026-07-30, MIT.
    - **Components:** colours, Plasma style, Aurorae, Kvantum (modified No Man's Sky), YAMIS icons, Rofi, Panel Colorizer transparent panel with a "progressive blur" wallpaper trick, Krohnkite tiling, and Better Blur with a class list (dolphin, konsole, plasmashell, steam, discord and others).
    - **Installer:** none (manual steps).
    - **Outdated link:** it points to the archived taj-ny/kwin-effects-forceblur. — [README](https://github.com/juxtopposed/Mystical-Blue-Theme)

13. **KDE Plasma Liquid Glass Theme**, by david-x3d: https://github.com/david-x3d/kde-plasma-liquid-glass-theme
    - **Look:** heavy-blur glass (macOS Tahoe style, not cyberpunk). It is a good blur base to recolour.
    - **Components (as git submodules):** Darkly, BreezeEnhanced, WhiteSur icons, modified Layan Plasma style, Better Blur DX, KDE Rounded Corners and a Discord/Vesktop CSS theme.
    - **Installer:** yes (`scripts/install.sh --full-setup`, `--dry-run`). Distro-aware: on the Arch family, including CachyOS, it builds into /usr.
    - **Repo stats:** n/v. — [README](https://github.com/david-x3d/kde-plasma-liquid-glass-theme)

14. **Della KDE**, by huggan360: https://github.com/huggan360/Della-KDE
    - **Look:** "glassmorphism theme for KDE Plasma 6 on Arch Linux".
    - **Components:** Plasma theme, Kvantum, window decoration, a "Liquid Glass" compositor effect, colours, wallpaper and panel. The decoration and effect compile against the local KDE/Qt.
    - **Installer:** yes (`install.py`, `restore.py`).
    - **Versions:** Wayland.
    - **Repo stats:** 0 stars, last push 2026-09-24. — [README](https://github.com/huggan360/Della-KDE)

15. **lavaglass**, by cybWasHere: https://github.com/cybWasHere/lavaglass
    - **Look:** a music-reactive lava-lamp wallpaper and glass dock, with Konsole, OBS and other windows at 80% over blur.
    - **Components:** rounded corners, two KWin scripts (Gap Maximize, Panel Edge Reveal) and Ferra colours.
    - **Installer:** yes, no root. Described as "Vibecoded".
    - **Repo stats:** 0 stars, last push 2026-10-06, MIT.
    - **Fit:** not cyberpunk, but a blur/glass reference. — [README](https://github.com/cybWasHere/lavaglass)

16. **Project Purple**, by Robotminded: https://github.com/Robotminded/ProjectPurple
    - **Look:** "futuristic", neon purple, transparent panels.
    - **Components:** global theme, Aurorae and wallpaper.
    - **Installer:** yes (`install.sh`).
    - **Versions:** claims "KDE Plasma 5 & 6".
    - **Repo stats:** 1 star, last push 2025-08-21. — [README](https://github.com/Robotminded/ProjectPurple)

17. **Red Glass**, by cycloarcane: https://github.com/cycloarcane/kde-redglass
    - **Look:** red/black glass recolour of "Black Glass".
    - **Components:** Plasma theme, Aurorae and colour scheme only.
    - **Installer:** manual.
    - **Versions:** Plasma 6.
    - **Repo stats:** 0 stars, last push 2026-02-19. — [README](https://github.com/cycloarcane/kde-redglass)

18. **Space Neon Minimal**, by heli-toon: https://github.com/heli-toon/space-neon-plasma
    - **Look:** black with neon orange.
    - **Components:** colours, Plasma style, Aurorae, look-and-feel, GTK, Konsole and Rofi.
    - **Installer:** a one-line curl installer.
    - **Versions:** Plasma 5 and 6.
    - **Repo stats:** 1 star, last push 2026-09-30.
    - **Blur:** "no heavy third-party engines", so none. — [README](https://github.com/heli-toon/space-neon-plasma)

19. **Cyberpunk-Neon**, by Roboron3042: https://github.com/Roboron3042/Cyberpunk-Neon
    - **Look:** a cyberpunk/outrun palette ported to many apps.
    - **Components:** for KDE, only a colour scheme and welcome screen, plus GTK, icons (Papirus kolorizer) and terminals.
    - **Repo stats:** 837 stars, last push 2025-05-05, CC-BY-SA-4.0.
    - **AUR:** `gtk-cyberpunk-neon-theme-git`, last modified 2022.
    - **Fit:** not a full Plasma suite. — [README](https://github.com/Roboron3042/Cyberpunk-Neon); [AUR RPC](https://aur.archlinux.org/rpc/v5/search/cyberpunk?by=name-desc)

20. **Project-CyberPlasma**, by Project-ELYX: https://github.com/Project-ELYX/Project-CyberPlasma
    - **Look:** purple/cyan/magenta.
    - **Components:** Aurorae, EWW widgets, Bismuth tiling and GLava.
    - **Versions:** **requires X11 session**.
    - **Repo stats:** 1 star, last push 2025-09-10.
    - **Status:** effectively dead for a Plasma 6.8 Wayland target. — [README](https://github.com/Project-ELYX/Project-CyberPlasma)

21. **arch-kde-rice**, by SuperYanka: https://github.com/SuperYanka/arch-kde-rice
    - **Look:** cyberpunk palette on the "Moe" theme.
    - **Versions:** Plasma 6.4.4 on **X11**.
    - **Repo stats:** 5 stars, last push 2025-09-07. — [README](https://github.com/SuperYanka/arch-kde-rice)

22. **Other hits, not deeply verified:**
    - keyaruga33/redo-of-arch: 15 stars, last push 2026-10-14, GPL-3.0, Plasma 6 Wayland, cyan on midnight, tri-panel layout. — [README](https://github.com/keyaruga33/redo-of-arch)
    - WeSky-source/MacTahoe-Futuristic-kde: amber/teal fork, 0 stars.
    - BuaxDEV/kde-golden-glass: translucent glass for CachyOS, 0 stars, last push 2026-10-16.
    - zaki-c2/cyber_conky: Cyberpunk/Tron conky only. — GitHub search API results, 2026-10-16

**B. Theme-suite authors (component suites, not cyberpunk-specific)**
- **vinceliuice suites** (Plasma style, Aurorae, Kvantum, global theme, with `install.sh`). Last pushes:
  - WhiteSur-kde: 2026-08-07, 1,286 stars
  - Graphite-kde-theme: 2026-08-23, 197 stars (dark graphite, the closest to a "tech" look)
  - Layan-kde: 2025-11-27, 542 stars
  - Fluent-kde: 2025-11-10
  - Orchis-kde: 2025-10-18
  - Colloid-kde: 2025-07-06
  - Qogir-kde: 2024-12-20
  - All GPL-3.0. — GitHub API; [Layan README](https://github.com/vinceliuice/Layan-kde)
  - AUR: `plasma6-themes-layan-git` (last modified 2024-07-16), `plasma6-themes-fluent-git` (2025-11-23), `plasma6-themes-orchis-kde-git` (2026-06-20), `plasma6-themes-colloid-git`. — [AUR RPC](https://aur.archlinux.org/rpc/v5/search/plasma6-themes?by=name-desc)
- **EliverLara Sweet**:
  - Sweet (GTK, "neon vibes"): 1,709 stars, last push 2026-08-13, GPL-3.0.
  - Sweet-kde (Plasma port): 253 stars, last push 2025-04-25, no license detected.
  - Sweet-sddm-v2 ("neon vibes for plasma 6"): 4 stars, 2025-06-11.
  - AUR: `sweet-kde-theme-git` (last modified 2026-04-19).
  - Sweet is the closest mainstream "neon" suite. — GitHub API; [AUR RPC](https://aur.archlinux.org/rpc/v5/search/sweet-kde?by=name-desc)
- **Bali10050 Darkly** (Qt app style, fork of Lightly): 1,077 stars, last push 2026-10-15, license NOASSERTION. Builds against Qt5 and Qt6 with `install.sh`. AUR: `darkly` and `darkly-bin` 0.5.41 (modified 2026-10-13, 28 votes for -bin). NEONGRID chose it over Kvantum because it follows the colour scheme. — [Darkly README](https://github.com/Bali10050/Darkly); [AUR](https://aur.archlinux.org/packages/darkly-bin)
- **paulmcauley Klassy** (decoration and app style; accent outline and coloured shadow): 1,945 stars, last push 2026-10-16. The master branch "requires Plasma 6.6, or later". AUR: `klassy` 6.7.3 (2026-09-18, 44 votes), `klassy-git`, `klassy-bin`. — [Klassy README](https://github.com/paulmcauley/klassy); [AUR RPC](https://aur.archlinux.org/rpc/v5/search/klassy?by=name-desc)
- **luisbocanegra Panel Colorizer**: 1,231 stars, last push 2026-09-20, GPL-3.0. AUR: `plasma6-applets-panel-colorizer` 8.0.0 (2026-08-11). The Plasma 5 version is unmaintained. — [README](https://github.com/luisbocanegra/plasma-panel-colorizer); [AUR RPC](https://aur.archlinux.org/rpc/v5/search/panel-colorizer?by=name-desc)

**C. Blur engines**
- **Better Blur DX**, by xarblu: https://github.com/xarblu/kwin-effects-better-blur-dx
  - 700 stars, last push 2026-10-13, GPL-3.0.
  - README lists supported versions 6.5, 6.6 and 6.7.
  - **Release 2.6.0 (13 Oct 2026) is titled "Plasma 6.8 support and more."** The AUR packages `kwin-effects-better-blur-dx` 2.6.0 (2026-10-13) and `-git` exist, along with an `-x11` variant. — [Releases](https://github.com/xarblu/kwin-effects-better-blur-dx/releases); [README](https://github.com/xarblu/kwin-effects-better-blur-dx); [AUR RPC](https://aur.archlinux.org/rpc/v5/search/better-blur?by=name-desc)
- **Glass**, by 4v3ngR: https://github.com/4v3ngR/kwin-effects-glass
  - 520 stars, last push 2026-10-16, GPL-3.0.
  - README lists supported versions 6.7 and 6.6. The last commit supporting 6.5 and X11 is pinned.
  - **The 6.8 build fix PR #121 ("fix: plugin build on KDE 6.8") was merged on 2026-10-16; PR #124 is still open.**
  - AUR: `kwin-effects-glass-git` (last modified 2026-06-23, which predates the 6.8 fix, so a rebuild from git is needed). — [README](https://github.com/4v3ngR/kwin-effects-glass); [6.8 PRs](https://github.com/4v3ngR/kwin-effects-glass/issues?q=6.8)
- **taj-ny/kwin-effects-forceblur** ("Better Blur"): **archived** (888 stars, last push 2025-08-13). NEONGRID says it is "archived and gone from the AUR". Mystical Blue still links to it. — GitHub API; [NEONGRID README](https://github.com/cromewar/neongrid)

### Inferences
- For CachyOS + 6.8 Wayland + PLM, NEONGRID is the closest ready-made match (same distro, Wayland, plasmalogin handling, Better Blur DX, Klassy, Darkly, Panel Colorizer). It was only tested on 6.7.2, and its pinned build components must be rebuilt for 6.8.
- Arasaka KDE and Neon District also handle PLM, but they target Debian and Fedora respectively, so package names will differ on CachyOS.
- For a ROG-style red/black look:
  - Crimson Glass is the most complete and the only one explicitly patched for 6.8, but its login theming is SDDM-only and won't apply under PLM.
  - Arasaka KDE (neon red) and CyberKDE (default red) are the alternatives.
- Almost all bespoke rices have fewer than 20 stars and were created in 2026. Treat them as single-author, low-validation projects: read the scripts before running them, because several are self-described "vibecoded" or LLM-assisted.

### Gaps
- Stars, dates and licenses for daemon-kde-mk2 and kde-plasma-liquid-glass-theme are n/v because of the API rate limit.
- yeyushengfan258 and L4ki: the repo names I guessed (Ant-Dark-kde, Ultimate-KDE-Themes, Fluent-kde) returned 404. I did not verify their current Plasma 6 suites; they mostly publish on store.kde.org/Pling, which I didn't check.
- I found no direct r/unixporn 2025–2026 posts with linked cyberpunk Plasma 6 repos; the mirror sites returned generic listings.
- I found no ROG/ASUS-branded full KDE suite on GitHub ("kde rog theme" returned 0 results).

## Q2. Aesthetic level and blur mechanism

### Takeaway
The heaviest real blur and glow comes from rices that use Better Blur DX force-blur together with Panel Colorizer and Klassy glow:
- NEONGRID
- sanguine-node-rice
- Mystical Blue
- Liquid Glass

Kvantum-only themes (Neon District, CyberKDE, Daemon MK2, Neon Noir) give translucency or neon chrome but limited true blur. Pure colour/Aurorae packs (Bitpunk, Tron, Red Glass, Space Neon) rely on native KWin blur at most.

### Cited Findings
- **NEONGRID:** "real compositor blur, a green glow shadow on the focused window (Klassy)". It blurs Ghostty by force-blurring its window class in Better Blur DX, and disables Background Contrast because it "washes out a near-black base". — [NEONGRID](https://github.com/cromewar/neongrid)
- **sanguine-node-rice:** "KWin Wayland Force Blur" with a Panel Colorizer "Main Blur" preset and Zen translucency via Better Blur DX. — [README](https://github.com/petrolal/sanguine-node-rice)
- **Crimson Glass:** "blur, subtle translucency, Magic Lamp". It replaced a broad KWin translucency rule with a game-opacity policy so games are not made transparent. — [README](https://github.com/SirFork1988/Crimson-Glass)
- **Mystical Blue:** Better Blur with an explicit window-class list, plus a fake "progressive blur" panel done through the wallpaper. — [README](https://github.com/juxtopposed/Mystical-Blue-Theme)
- **Liquid Glass:** Better Blur DX, KDE Rounded Corners, Darkly and BreezeEnhanced. — [README](https://github.com/david-x3d/kde-plasma-liquid-glass-theme)
- **Della:** ships its own compiled "Liquid Glass" compositor effect. — [README](https://github.com/huggan360/Della-KDE)
- **Arasaka:** shader rain with refraction on the wallpaper, plus TV Glitch transitions. — [README](https://github.com/sne11ius/arasaka-kde)
- **Better Blur DX features:** force blur, brightness/contrast/saturation, corner radius and refraction. Blur is visible only on translucent windows; disable the stock blur first. — [mintlify docs](https://www.mintlify.com/xarblu/kwin-effects-better-blur-dx/introduction); [window transparency](https://www.mintlify.com/xarblu/kwin-effects-better-blur-dx/usage/window-transparency)
- **Glass caveat:** the maintainer warns that enabling the translucency effect plugin makes every blur plugin less effective. — [Glass repo](https://github.com/4v3ngR/kwin-effects-glass)
- **Client-side blur in Plasma 6.7:** KDE 6.7 dropped the old `org_kde_kwin_blur_manager` protocol for `ext-background-effect-v1`. Ghostty 1.3.1 and kitty client-side blur silently stopped working; force-blur from the compositor is the workaround. — [NEONGRID](https://github.com/cromewar/neongrid)

### Inferences
- If the user's terminal or apps request blur client-side, expect breakage on 6.7+. Force-blurring by window class in Better Blur DX or Glass is the robust path.

### Gaps
- I found no benchmarks comparing the GPU cost of Better Blur DX and Glass.

## Q3. Known problems: Plasma 6.5+ / 6.7 Union / 6.8, AUR deps, NVIDIA/Wayland, performance

### Takeaway
The main risk is compiled KWin/Plasma plugins (Better Blur DX, Glass, Klassy, Panel Colorizer's C++ part, Della's effect). They break on every Plasma minor update and must be rebuilt.

Plasma 6.8 (released 2026-10-14):
- Better Blur DX already has a 6.8 release.
- Glass merged a 6.8 build fix on 2026-10-16.
- Klassy's AUR package is 6.7.3, and I could not confirm 6.8 status.
- 6.8 expands the Union theming preview to QtWidgets apps. It is opt-in, so Kvantum/Darkly themes are unaffected unless Union is selected.
- 6.8 removed the X11 login, which kills X11-only rices.

### Cited Findings
- **NEONGRID's post-update warning:**
  - After every Plasma update, `kwin-effects-better-blur-dx` stops blurring silently.
  - `klassy-git` leaves windows without decorations.
  - Panel Colorizer can leave plasmashell crash-looping. Fix: remove `~/.local/share/plasma/plasmoids/luisbocanegra.panel.colorizer` and restart plasma-plasmashell.
  - NEONGRID ships a pacman hook and `rebuild.sh` for this. — [NEONGRID](https://github.com/cromewar/neongrid)
- **Better Blur DX:** "only works for the exact KWin version it was built for", so it may need rebuilding after upgrades. — [mintlify install docs](https://www.mintlify.com/xarblu/kwin-effects-better-blur-dx/installation/overview)
  - Issue #128, "Compiles fail on Plasma 6.8 (6.7.90)", is closed (Sep 2026).
  - v2.6.0 adds 6.8 support. — [issues](https://github.com/xarblu/kwin-effects-better-blur-dx/issues?q=6.8); [releases](https://github.com/xarblu/kwin-effects-better-blur-dx/releases)
  - X11 support is "more or less deprecated", needs a separate build, and KWin X11 has seen no API changes since 6.5. — [README](https://github.com/xarblu/kwin-effects-better-blur-dx)
- **Glass:** fix PR #121 for 6.8 was merged on 2026-10-16. The AUR -git package was last modified 2026-06-23. — [PRs](https://github.com/4v3ngR/kwin-effects-glass/issues?q=6.8); [AUR RPC](https://aur.archlinux.org/rpc/v5/search/kwin-effects-glass?by=name-desc)
- **Klassy:** master requires Plasma 6.6+. AUR `klassy` is 6.7.3 (2026-09-18). A search of its issues for "6.8" showed no explicit Plasma 6.8 breakage report. — [README](https://github.com/paulmcauley/klassy); [issues search](https://github.com/paulmcauley/klassy/issues?q=6.8)
- **Union:** in 6.7 it was a tech preview, not enabled by default. Setting it globally through an environment variable breaks Flatpak apps. — [Plasma 6.7 beta announcement](https://kde.org/announcements/plasma/6/6.6.91/); [Union FAQ](https://discuss.kde.org/t/get-started-with-union-plasmas-new-theming-engine-in-2-minutes-or-less-a-faq/47883)
  - Plasma 6.8 extends Union to QtWidgets apps (Dolphin, Kate) through a "Breeze (Union)" application style. It is still early, with "many visual glitches". — [linuxiac](https://linuxiac.com/kde-plasma-6-8-expands-union-theming-to-qtwidgets-apps/); [alternativeto](https://alternativeto.net/news/2026/9/plasma-6-8-beta-adds-kup-backups-and-expands-union-theming/)
  - One secondary source says 6.8 removes X11 login support. — [linuxiac 6.8 preview](https://linuxiac.com/kde-plasma-6-8-heres-whats-coming/)
- **Plasma 6.8 and SDDM themes:** 6.8 removed Breeze's `VirtualKeyboardLoader`, which broke Crimson Glass's SDDM theme (fixed in 1.1.1). Other SDDM themes that import Breeze components may hit the same problem. — [Crimson Glass](https://github.com/SirFork1988/Crimson-Glass)
- **Plasma Login Manager:** the global look-and-feel does not theme plasmalogin; its only appearance hook is `WallpaperPluginId`. So SDDM themes from Bitpunk, Tron, CyberKDE, Neon Noir, Crimson Glass and Sweet won't apply under PLM. — [NEONGRID](https://github.com/cromewar/neongrid)
  - PLM-aware rices: NEONGRID, Neon District (`install-system.sh`) and Arasaka (`build-plm`). — [Neon District](https://github.com/coex177/neon-district-plasma); [Arasaka](https://github.com/sne11ius/arasaka-kde)
- **Other gotchas:**
  - Klassy reads its config only at KWin start.
  - Cursor themes should go in /usr/share/icons for some Wayland/GTK clients.
  - Disable "accent colour from wallpaper" with animated wallpapers.
  - Cap the shader wallpaper at 30 FPS for GPU cost. — [NEONGRID](https://github.com/cromewar/neongrid)
- **CyberKDE:** under llvmpipe, KWin disables all animations. — [CyberKDE](https://github.com/jrcn1991/theme-cyberkde)
- **Daemon v1:** Flatpak KDE apps ignore Kvantum. — [Daemon v1](https://github.com/MathisP75/daemon-dotfiles)
- **Crimson Glass:** libadwaita, Electron, Flatpak and Snap apps may keep or isolate their own theming. — [Crimson Glass](https://github.com/SirFork1988/Crimson-Glass)
- **Older Aurorae report:** Aurorae themes had issues with fractional scaling on Wayland (an anecdotal report from the Plasma 6.0 era). — [lemmy thread](https://lemmy.korz.dev/post/596956)

### Inferences
- On CachyOS, prefer the AUR or Chaotic builds that track KWin releases (`kwin-effects-better-blur-dx` 2.6.0), and add a pacman hook to rebuild after `kwin` updates.
- Aurorae-based decorations (CyberKDE, Daemon MK2, Tron, Neon Noir, Imperial Geass, Red Glass) avoid compiled-plugin breakage, but they are SVG-rendered and historically weaker on fractional scaling.

### Gaps
- I found no specific NVIDIA (hybrid RTX) issues for Better Blur DX or Glass in the issue searches I ran. The blur-on-NVIDIA performance question remains unverified.
- I did not verify Panel Colorizer and Darkly against 6.8 (no 6.8 issues found; Darkly 0.5.41 was released on 2026-10-13).

## Q4. AUR / CachyOS package names

### Takeaway
Core pieces are packaged in the AUR. The bespoke cyberpunk rices are not; they are git-clone and install-script only.

### Cited Findings
- **Blur:**
  - `kwin-effects-better-blur-dx` (2.6.0, 2026-10-13), `kwin-effects-better-blur-dx-git`, `kwin-effects-better-blur-dx-x11`, `kwin-effects-better-blur-dx-x11-git`, `kwin-effects-better-blur-dx-patched` (2.3.0, stale).
  - `kwin-effects-glass-git` (2026-06-23).
  - `kwin-effects-blur-respect-rounded-decorations-git`. — [AUR RPC](https://aur.archlinux.org/rpc/v5/search/kwin-effects?by=name-desc)
- **App style:** `darkly`, `darkly-bin` (0.5.41), `darkly-git`, `darkly-qt5-git`, `darkly-qt6-git`. — [AUR RPC](https://aur.archlinux.org/rpc/v5/search/darkly?by=name-desc)
- **Decoration:** `klassy` (6.7.3), `klassy-bin`, `klassy-git`, `klassy-qt5`. — [AUR RPC](https://aur.archlinux.org/rpc/v5/search/klassy?by=name-desc)
- **Panel:** `plasma6-applets-panel-colorizer` (8.0.0). — [AUR RPC](https://aur.archlinux.org/rpc/v5/search/panel-colorizer?by=name-desc)
- **Theme suites:**
  - `plasma6-themes-layan-git`, `plasma6-themes-fluent-git`, `plasma6-themes-orchis-kde-git`, `plasma6-themes-colloid-git`, `plasma6-themes-chromeos-kde-git`.
  - `plasma6-themes-vapor-steamos` (3.9.4, 2026-10-11: the SteamOS "Vapor" theme, a gamer-adjacent option).
  - `sweet-kde-theme-git`. — [AUR RPC](https://aur.archlinux.org/rpc/v5/search/plasma6-themes?by=name-desc)
- **Effects:** `kwin-effects-burn-my-windows-git` (last modified 2025-04-15), which provides the TV Glitch effect recommended by Daemon MK2 and Arasaka. — [AUR RPC](https://aur.archlinux.org/rpc/v5/search/kwin-effects?by=name-desc)

### Inferences
- `kwin-effects-burn-my-windows-git` was last touched in April 2025, so it may not build on 6.8. Arasaka vendors its own adapted copy.

### Gaps
- I did not check which of these are in CachyOS's own repos or Chaotic-AUR.
- I found no AUR package for any of the bespoke cyberpunk rices (NEONGRID, Neon District, Arasaka, CyberKDE, Bitpunk, Daemon, Crimson Glass).
