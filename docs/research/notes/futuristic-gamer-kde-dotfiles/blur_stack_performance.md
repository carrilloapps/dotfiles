# KDE Plasma 6 Wayland blur and translucency stack: tools, upkeep, and NVIDIA hybrid performance (as of 2026-10-16)

Context checked locally on the target machine on 2026-10-16 with `pacman -Q` and `pacman -Ss`:
- Installed: `kwin 6.8.0-1.1`, `plasma-workspace 6.8.0-1.1`, `nvidia-utils 615.78.08-2`, `linux-cachyos-nvidia-open 7.2.9-2` (the open kernel module). Plasma 6.8 was released on 2026-10-14, two days before these notes ([Phoronix](https://phoronix.com/news/KDE-Plasma-6.8-Released); [GamingOnLinux](https://www.gamingonlinux.com/2026/10/plasma-6-8-is-out-as-kde-celebrates-30-years/)).
- In the CachyOS and Arch repos: `kvantum 1.1.8` (extra and cachyos-extra-v3) and `kwin-effect-rounded-corners 0.10.0-1` (cachyos repo). **None of these are in the official or CachyOS repos: Better Blur DX, Glass, Darkly, Klassy, Lightly, Panel Colorizer.** They have to come from the AUR, and the `pacman -Ss` search found no match for them.
- Important caveat: every third-party KWin effect below was last documented as supporting Plasma 6.7 at most. **I found no confirmation that any of them build or work on KWin 6.8.0.** Treat 6.8 compatibility as unverified.

## 1. Better Blur (taj-ny/kwin-effects-forceblur) and its successors: status, packages, features, compatibility

### Takeaway
The original Better Blur (taj-ny) was archived in November 2025 and is dead. Its two active successors are **Better Blur DX** (xarblu) and **Glass** (4v3ngR). Both offer force blur, anti-aliased rounded corners, brightness/contrast/saturation controls and refraction. Glass adds tint, glow and edge lighting. Neither currently has the GPU-cheap "static blur" mode. Both must be rebuilt after every KWin update and regularly break on Plasma upgrades.

### Cited Findings
- **taj-ny/kwin-effects-forceblur ("Better Blur") was archived on Nov 20, 2025** and is read-only. Its last listed support was Plasma 6.4, and v1.3.6 covered Plasma 6.0 to 6.3.5. Features were force blur, anti-aliased rounded corners, **static blur ("uses much less GPU")**, brightness/contrast/saturation and refraction. AUR: `kwin-effects-forceblur`. — [GitHub taj-ny/kwin-effects-forceblur](https://github.com/taj-ny/kwin-effects-forceblur)
- **Better Blur DX (xarblu/kwin-effects-better-blur-dx)** calls itself a "loose continuation" of Better Blur, forked from taj-ny.
  - Supports Plasma 6.5, 6.6 and 6.7. Older versions are only lightly tested.
  - Features: force blur (with regex class matching), brightness/contrast/saturation, corner radius, refraction.
  - **Static blur is missing.** The README says it "wasn't trivially portable to the Plasma 6.5 blur".
  - AUR: `kwin-effects-better-blur-dx`, `kwin-effects-better-blur-dx-git`, and `-x11` variants. X11 is effectively deprecated.
  - It only works with the exact KWin version it was built for, so it needs a rebuild after upgrades.
  - Conflicts with the stock Blur effect, which must be disabled. Incompatible with Wobbly Windows.
  - Activity at fetch time: about 700 stars, 43 open issues, 1,137 commits.
  - — [GitHub xarblu/kwin-effects-better-blur-dx](https://github.com/xarblu/kwin-effects-better-blur-dx); [Mintlify docs](https://www.mintlify.com/xarblu/kwin-effects-better-blur-dx)
- **Glass (4v3ngR/kwin-effects-glass)** is also a fork of taj-ny.
  - Features: force blur, anti-aliased rounded corners, brightness/contrast/saturation, **tint, glow, edge lighting**, Snell's refraction, and separate blur and noise strengths for docks, decorations and content.
  - Supports Plasma 6.7 and 6.6. Support for 6.5 and X11 ended after commit 0ae94cf.
  - AUR: `kwin-effects-glass-git`.
  - About 520 stars, 25 open issues, about 675 commits.
  - — [GitHub 4v3ngR/kwin-effects-glass](https://github.com/4v3ngR/kwin-effects-glass)
- **Glass README caveats:**
  - Enabling KWin's **Translucency** effect weakens all blur plugins, including Glass and Better Blur DX, so it should be disabled. Window-rule opacity does not have this problem.
  - Some windows need "Ignore content blur region", for example terminals and Electron apps that don't declare Wayland blur regions.
  - — [GitHub 4v3ngR/kwin-effects-glass](https://github.com/4v3ngR/kwin-effects-glass)
- Darkly's README itself recommends `kwin-effects-better-blur-dx` or `kwin-effects-glass` for transparency and warns that they conflict with the stock blur. — [GitHub Bali10050/Darkly](https://github.com/Bali10050/Darkly)
- **Breakage history:**
  - On 2026-06-20 the AUR `kwin-effects-better-blur-dx` 2.4.1-2 failed to build on Plasma 6.7 with "wayland/blur.h: No such file or directory". The `-git` variant built and worked.
  - After 6.7.1, users advised rebuilding with `--rebuild`. One user ran Better Blur DX with the built-in blur turned off.
  - — [EndeavourOS forum, Plasma 6.7 thread p.5](https://forum.endeavouros.com/t/kde-plasma-6-7-is-out-hurry-up/80194?page=5)
- A Plasma 6.6.4 user reported Glass and Better Blur DX disappearing from Desktop Effects after updating from 6.6.3. The suspected cause was a missing rebuild. — [KDE Discuss (search snippet)](https://discuss.kde.org/t/installed-desktop-effects-missing-from-system-settings-plasma-6-6-4/46220) (not opened in full)
- On Plasma 6.5, stock blur became brighter and stopped matching themes, and the "improve contrast" toggle went missing. Users reported Better Blur fixed it. — [KDE Discuss](https://discuss.kde.org/t/blur-effect-is-brighter-on-6-5-and-doesnt-match-the-theme/40946) (from search summary)
- Other forks exist but were not evaluated:
  - [D3SOX/kwin-forceblur](https://github.com/D3SOX/kwin-forceblur)
  - [graninius/kwin-effects-forceblur](https://github.com/graninius/kwin-effects-forceblur)
  - A Fedora COPR [yohane-shiro/kwin-effects-forceblur](https://copr.fedorainfracloud.org/coprs/yohane-shiro/kwin-effects-forceblur)
  - AeroThemePlasma's bundled copy

### Inferences
- **For the strongest "futuristic glass" look in 2026, Glass is the most feature-rich**, with tint, glow, edge lighting and refraction. Better Blur DX is the more conservative and more widely referenced successor. Use only one; they conflict with each other and with stock Blur.
- **Expect a rebuild after every CachyOS KWin update.** The `-git` AUR variants have historically adapted faster to new Plasma majors than tagged packages. Since KWin 6.8.0 has just landed, either effect may currently fail to build or load until patched.
- Losing static blur in all 6.5+ forks removes the main low-GPU option the original Better Blur offered.

### Gaps
- No verified data on Plasma 6.8 compatibility for Better Blur DX or Glass. Both READMEs top out at 6.7.
- Latest release tags and dates were not visible on the GitHub pages fetched. AUR pages were blocked by Anubis bot protection, so current AUR versions and vote counts are unverified.
- A `taj-ny/kwin-effects-glass` repo is mentioned in a forum post but could not be confirmed.

## 2. Native KWin blur, Kvantum, Klassy, Darkly, Lightly, rounded corners, Panel Colorizer, and the Translucent panel

### Takeaway
The working stack in 2026 has five layers:
1. A blur engine: stock KWin Blur, **or** Better Blur DX, **or** Glass.
2. An application style that draws translucent surfaces: Darkly, or Kvantum with a translucent theme.
3. A window decoration: Klassy or Darkly's decoration.
4. Optional rounded corners and outlines: KDE-Rounded-Corners, which is packaged in the CachyOS repo.
5. Panel styling: Panel Colorizer, with its optional C++ blur plugin.

Darkly itself does not blur. It relies on the KWin blur effect.

### Cited Findings
- **Darkly (Bali10050)** is a fork of Lightly and actively maintained (about 2,877 commits, about 1.1k stars).
  - Current code targets Plasma 6.5 and later. Use v0.5.25 or the Darkly-6.4 branch for Plasma below 6.5, and v0.5.16 for below 6.3.
  - AUR: `darkly`, `darkly-bin`.
  - **Darkly provides no blur itself.** It points to Better Blur DX or Glass, and asks for help with a KWin blur merge request.
  - Limits: QML/Qt Quick apps get limited transparency, colour-scheme changes apply only partly, and apps need a restart for style changes.
  - — [GitHub Bali10050/Darkly](https://github.com/Bali10050/Darkly)
- **KDE-Rounded-Corners (matinlotfali)** is actively maintained and supports Plasma 5.27 to 6.7+, tested on Wayland on 6.3, 6.4, 6.5 and 6.7.
  - Features: active/inactive outlines (up to 3), gradient outlines, a squircle option, corner shadows, and an option to disable on maximized or tiled windows.
  - It is shader-based, "optimized to render once instead of five times", and the author claims little performance impact.
  - It needs a rebuild after KWin updates, and the repo provides an autorun script for this. Undecorated windows such as Steam may lose shadows; a window-rule workaround is documented.
  - AUR: `kwin-effect-rounded-corners-git`.
  - — [GitHub matinlotfali/KDE-Rounded-Corners](https://github.com/matinlotfali/KDE-Rounded-Corners)
  - CachyOS repo package: `cachyos/kwin-effect-rounded-corners 0.10.0-1`, checked locally on 2026-10-16.
- **Panel Colorizer (luisbocanegra)** is AUR `plasma6-applets-panel-colorizer`.
  - Features: presets that auto-switch on fullscreen, maximized or floating state; native panel opacity (needs Plasma 6.3 or later); hiding the native background; simulated always-floating panels; widget "islands"; shadows and borders; D-Bus control.
  - **Blur behind custom backgrounds requires building its C++ plugin**, which "may stop working or cause Plasma to crash after a system update".
  - The author reports about 0.5–1% extra idle CPU.
  - — [GitHub luisbocanegra/plasma-panel-colorizer](https://github.com/luisbocanegra/plasma-panel-colorizer)
- **Kvantum 1.1.8** is in the extra and cachyos-extra-v3 repos, checked locally. Its translucency and blur behaviour was not re-verified on the tsujan/Kvantum page in this session.
- KWin's **Translucency** effect, which is separate from Kvantum and Panel Colorizer opacity, weakens Glass and Better Blur DX blur. — [Glass README](https://github.com/4v3ngR/kwin-effects-glass)

### Inferences
- A sensible high-impact combination for this machine:
  - Glass or Better Blur DX, with stock Blur and Translucency disabled
  - Darkly as both application style and decoration (or Klassy for the decoration)
  - KDE-Rounded-Corners from the CachyOS repo, possibly redundant because both blur forks already round corners
  - Panel Colorizer with presets that go opaque or solid when a window is fullscreen or maximized
- Three or four out-of-tree C++ KWin/Plasma plugins all need a rebuild on every Plasma update. That is the main maintenance cost. Repo-packaged pieces (rounded corners, Kvantum) are rebuilt by CachyOS automatically.

### Gaps
- **Not verified in this session:**
  - Klassy (paulmcauley) status and its Plasma 6.7/6.8 support.
  - Lightly (Luwx) maintenance status.
  - Kvantum's blur/translucency options page.
  - Native KWin blur slider ranges for "Blur strength" and "Noise strength".
  - The Plasma "Translucent / Adaptive" panel opacity setting.
- I did not check whether Darkly builds on Plasma 6.8.

## 3. Performance: blur GPU cost, which GPU KWin uses on hybrid laptops, fullscreen games, gamer recommendations

### Takeaway
I found **no published benchmark** of blur GPU cost on NVIDIA Wayland. The evidence is qualitative:
- The fork authors say blur "can be very resource-intensive with many windows" and that under high GPU load it causes cursor latency or stutter.
- One user reported animations became smooth again on Plasma 6.7.1 after disabling blur.

For gaming, the main levers are:
- Make sure fullscreen games get **direct scanout**. Blur behind covered windows is then not composited.
- Use Panel Colorizer presets so panels drop translucency in fullscreen.
- Watch **which GPU kwin_wayland lands on**. Since Plasma 6.7, KWin's new Vulkan path has been pulling kwin_wayland onto the NVIDIA dGPU on Optimus laptops.

### Cited Findings
- **Blur cost and cursor mitigations:**
  - Better Blur DX and Glass both warn the effect "can be very resource-intensive" with many windows. On Wayland, high GPU load can cause cursor latency or stuttering.
  - Suggested mitigations: `KWIN_DRM_NO_AMS=1`, and testing `KWIN_FORCE_SW_CURSOR=0` or `1`.
  - **Intel GPUs use a software cursor by default** because of an upstream bug. This matters if KWin composites on the Iris Xe.
  - — [Better Blur DX README](https://github.com/xarblu/kwin-effects-better-blur-dx); [Glass README](https://github.com/4v3ngR/kwin-effects-glass)
- The original Better Blur's **static blur "uses much less GPU"**, but it is not available in the 6.5+ forks. — [taj-ny README](https://github.com/taj-ny/kwin-effects-forceblur); [Better Blur DX README](https://github.com/xarblu/kwin-effects-better-blur-dx)
- **Plasma 6.7 Intel regression** (June 2026):
  - CachyOS users on Intel i915 saw choppy zoom, pan and Firefox. Downgrading to KWin 6.6.5 fixed it.
  - The reporter attributed it to the zoom plugin's text scaling (KWin commit 0aab86031b). Disabling text sharpening helped.
  - A second user reported that **disabling blur made animations "much faster and smooth"** on 6.7.1. Nate Graham asked for a separate bug report; no bug link was shown.
  - — [KDE Discuss: Plasma 6.7 Performance Regression on Intel](https://discuss.kde.org/t/kde-plasma-6-7-performance-regression-on-intel/48032)
- **KWin on the dGPU after Plasma 6.7** (reports from June to July 2026):
  - `kwin_wayland` shows up in `nvidia-smi` on hybrid laptops, including an ASUS ROG Zephyrus G16 on CachyOS kernel 7.0.12. Users saw louder fans, battery drain and about 6 W of idle dGPU draw.
  - Workaround reported to work locally: `KWIN_DISABLE_VULKAN=1` in `~/.config/plasma-workspace/env/set_gpu.sh`.
  - `KWIN_DRM_DEVICES` gave mixed results.
  - KDE developer meven: "KWin only really needs OpenGL"; Vulkan mainly adds optimizations, chiefly on NVIDIA.
  - Related bug: [521914 "GpuManager unconditionally opens all render nodes at startup"](https://bugs.kde.org/show_bug.cgi?id=521914).
  - — [KDE Discuss thread](https://discuss.kde.org/t/kwin-unnecessarily-run-on-dedicated-graphics-card-nvidia-with-hybrid-gpu-after-upgrading-to-plasma-6-7/47977)
  - Similar CachyOS reports: [KWIN_DRM_DEVICES not working](https://discuss.cachyos.org/t/kwin-wayland-always-used-nvidia-dgpu-instead-of-intel-igpu-kwin-drm-devices-not-working/31576), [kwin_wayland incorrectly using dGPU](https://discuss.cachyos.org/t/kwin-wayland-inccorrectly-using-my-nvidia-dgpu-by-default/31947), [hybrid GPU + Wayland keeps breaking](https://discuss.cachyos.org/t/i-want-to-love-kde-but-hybrid-gpu-wayland-keeps-breaking/26603) (search snippets only).
- **`KWIN_DRM_DEVICES` semantics** (forum, not official docs):
  - The first listed device does the compositing.
  - Card numbering can change between boots, so `/dev/dri/by-path` names are safer.
  - Trade-off: when an external monitor is wired to the dGPU's HDMI port, compositing on the iGPU gave about 49 FPS on a 120 Hz screen. Forcing the dGPU fixed it at a cost in power and VRAM.
  - — [KDE Discuss: frame pacing on external dGPU output](https://discuss.kde.org/t/kwin-wayland-halved-poor-frame-pacing-on-external-monitor-dgpu-output-in-hybrid-intel-nvidia-setup/47044) (search snippet)
- **Plasma 6.7.3** (2026-07-14):
  - Re-enabled **triple buffering for NVIDIA**, which reduces stutter when the compositor can't sustain the refresh rate.
  - Fixed Vulkan device detection and moved Vulkan init to a graphics queue.
  - **Direct scanout is now attempted earlier in rendering.**
  - No blur fixes listed.
  - — [Linuxiac](https://linuxiac.com/kde-plasma-6-7-3-restores-triple-buffering-for-nvidia-gpus/)
  - Per [comss.ru](https://www.comss.ru/page.php?id=21079), triple buffering is enabled by default on the 6.8 branch (Russian-language secondary source).
- **Plasma 6.8** (2026-10-14) lists "vRAM optimizations" among its headline changes. It also completes the move to Wayland-only; the 6.6 LTS line stays supported to 2029. — [Phoronix](https://phoronix.com/news/KDE-Plasma-6.8-Released) (search summary)
- **Direct scanout vs. blocking compositing:**
  - Direct scanout (since Plasma 5.22) lets fullscreen app frames skip the compositor copy, for better performance and latency. — [Phoronix 2021](https://www.phoronix.com/news/Plasma-5.22-Direct-Scan-Out) (older)
  - Direct scanout is on by default and is a frame-forwarding path, distinct from "blocking compositing". The KWin debug console's "show compositing" indicator reflects compositing, not scanout. `KWIN_DRM_NO_DIRECT_SCANOUT=1` disables scanout for testing. — [CachyOS forum, June 2026](https://discuss.cachyos.org/t/direct-scanout-is-not-turning-on/31826/2)
  - KWin's "allow applications to block compositing" option is on by default and can be overridden per window by a rule. — [kwin.kcfg](https://invent.kde.org/plasma/kwin/-/blob/853020336f13af2d91f007ba7eccca3239d5e7a3/kwin.kcfg) (older commit)
- **Recent direct scanout bugs:**
  - KWin 6.7.3 ignored `KWIN_DRM_NO_DIRECT_SCANOUT` on virtual outputs, which froze fullscreen Chromium. — [KDE bug 523353](https://bugs.kde.org/show_bug.cgi?id=523353) (snippet)
  - A gamescope report says direct scanout did not engage in fullscreen under Plasma 6. — [gamescope #1423](https://github.com/ValveSoftware/gamescope/issues/1423) (snippet)
  - An older 2022–2023 NVIDIA forum thread reported KDE Wayland games being force-vsynced, with uneven frame pacing on NVIDIA. — [NVIDIA forums](https://forums.developer.nvidia.com/t/nvidia-bug-kde-wayland-games-are-force-vsynced/237880) (older)

### Inferences
- On a PRIME-offload laptop with the internal panel on the iGPU (the usual ASUS TUF F15 layout; verify with `ls /dev/dri/by-path` and `nvidia-smi`), the best gaming outcome is:
  - KWin composites on the **Iris Xe**.
  - Games run on the RTX 3050 via `prime-run` or `__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia`, or Steam's `prime-run %command%`.
  - Blur shaders then run on the iGPU and do not take shader time from the game. The cost is moved to the iGPU and shared memory bandwidth, so heavy blur still costs some frame time on the Iris Xe.
- **Check whether kwin_wayland is on the dGPU** (`nvidia-smi` lists it) on Plasma 6.7/6.8. If it is, `KWIN_DISABLE_VULKAN=1` is the reported fix. That puts the blur workload and the game on the same 4 GB card, which hurts both VRAM and battery.
- **Blur in fullscreen games:**
  - When a game is fullscreen and direct scanout engages, KWin doesn't composite other windows, so blur costs nothing.
  - In windowed or borderless games, or when overlays and notifications break scanout, blurred panels and windows are composited every frame.
  - This is inferred from how scanout works; I found no direct measurement.
- **Gamer recommendations** (synthesized; not individually verified as 2026 best practice):
  1. Run games truly fullscreen.
  2. Use Panel Colorizer's fullscreen preset to make panels opaque.
  3. Disable the Translucency effect.
  4. Keep blur radius moderate.
  5. Use gamemode and MangoHud for monitoring. MangoHud's own effect on scanout was not verified.
  6. Gamescope is an option for frame limiting and scaling, but has reported scanout quirks under Plasma.
  7. Toggle effects or compositing off via a KWin script or a shortcut-bound `qdbus` call when gaming. Compositing cannot be fully disabled on Wayland.

### Gaps
- **No quantified measurements** were found for blur GPU cost (ms per frame or % GPU) on NVIDIA or on Iris Xe under Wayland.
- **Not verified for 2026:** VRR in KWin 6.8 with blur; gamemode and MangoHud interaction with direct scanout; gamescope-under-KWin performance.
- **Not verified:** whether `KWIN_DISABLE_VULKAN` is still needed on 6.8, and whether bug 521914 was fixed.

## 4. Known NVIDIA + Wayland + KWin issues with blur effects (2025–2026)

### Takeaway
I found **no NVIDIA-specific blur bug** in 2025–2026 sources. The blur effect READMEs don't mention NVIDIA at all. The relevant NVIDIA/KWin issues are general compositor ones, and these indirectly affect how heavy blur feels:
- kwin_wayland landing on the dGPU after 6.7
- triple buffering being dropped and then restored in 6.7.3
- Vulkan device selection

On the blur side, the problems are version breakage after Plasma updates and the 6.5 brightness change, not anything driver-specific.

### Cited Findings
- The Better Blur DX and Glass READMEs have no NVIDIA-specific notes. Their warnings are about GPU load, cursor lag and Intel's software cursor. — [Better Blur DX](https://github.com/xarblu/kwin-effects-better-blur-dx); [Glass](https://github.com/4v3ngR/kwin-effects-glass)
- Plasma 6.7.3 fixed NVIDIA triple buffering, Vulkan device detection and EGL context creation, but listed no blur fixes. — [Linuxiac](https://linuxiac.com/kde-plasma-6-7-3-restores-triple-buffering-for-nvidia-gpus/)
- KWin's Vulkan work in 6.7 was tested on an RTX 5070 Ti with proprietary drivers. — [DesdeLinux](https://blog.desdelinux.net/en/KDE-Plasma-6.7-scaling--Wayland-Vulkan-interface-improvements/) (secondary)
- Since Plasma 6.7, kwin_wayland lands on the NVIDIA dGPU in hybrid setups (see section 3). — [KDE Discuss](https://discuss.kde.org/t/kwin-unnecessarily-run-on-dedicated-graphics-card-nvidia-with-hybrid-gpu-after-upgrading-to-plasma-6-7/47977)
- Plasma 6.5 changed stock blur so it renders brighter. — [KDE Discuss](https://discuss.kde.org/t/blur-effect-is-brighter-on-6-5-and-doesnt-match-the-theme/40946)

### Inferences
- With NVIDIA 615.78.08 (open modules) and KWin 6.8.0, the main risks for a blur-heavy setup are:
  - third-party effects not yet rebuilt or patched for 6.8
  - KWin compositing on the dGPU, which costs battery and VRAM
- Neither is a known blur-on-NVIDIA rendering bug.

### Gaps
- I found no NVIDIA 615.x-specific KWin reports.
- I did not search the KDE bug tracker for NVIDIA + blur bugs directly.
- The Klassy, Kvantum and Panel Colorizer issue trackers were not checked for NVIDIA reports.
