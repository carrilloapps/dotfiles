# Linux gaming tuning for stutter and heat (Proton/Steam, RTX 30 laptop, vkd3d-proton DX12, KDE Plasma 6 Wayland, CachyOS), with NFS Unbound notes

Research date: 2026-10-17. Context: ASUS TUF F15 FX507ZC4 (RTX 3050 Laptop, Intel 12th gen, hybrid graphics), CachyOS kernel 7.x.
Caveat on method: ProtonDB per-report pages are JS-rendered and could not be fetched directly; ProtonDB info below comes from its summary API and search-engine snippets of its report text. The Arch Wiki (Anubis block) and the NVIDIA developer forum (403) could not be fetched.

## 1. Frame rate capping and VRR (temps, frametime consistency, KDE Plasma 6 Wayland + NVIDIA)

### Takeaway
A frame cap below what the GPU can sustain is the single most effective software lever for both heat and frametime consistency on a thermally/power-limited laptop. vkd3d-proton has its own limiter (`VKD3D_FRAME_RATE`) for DX12 games, and MangoHud's `fps_limit` with `fps_limit_method=early` gives the smoothest pacing. VRR on KDE Wayland with NVIDIA works but has a history of fullscreen flicker/black-screen bugs; "Automatic" is the recommended policy.

### Cited Findings
- vkd3d-proton env var `VKD3D_FRAME_RATE`: "Frame rate cap. `0` uncaps it; any positive value sets the limit". It also exposes `VKD3D_SWAPCHAIN_PRESENT_MODE` (IMMEDIATE, MAILBOX, FIFO, FIFO_RELAXED, FIFO_LATEST_READY) to force a present mode — [vkd3d-proton README](https://github.com/HansKristian-Work/vkd3d-proton)
- Note: `DXVK_FRAME_RATE` applies only to DXVK (D3D8-11); a DX12 game like NFS Unbound runs on vkd3d-proton, so the relevant variable is `VKD3D_FRAME_RATE` — [vkd3d-proton README](https://github.com/HansKristian-Work/vkd3d-proton) (inference on DXVK scope, see Inferences)
- MangoHud `fps_limit` takes a comma-separated list (0 = unlimited); `fps_limit_method` = `late` (default, lowest latency) or `early` (smoothest frametimes); `toggle_fps_limit` default `Shift_L+F1` cycles values; in `MANGOHUD_CONFIG` multi-values use `+` (e.g. `fps_limit=60+30+0`) — [MangoHud README](https://raw.githubusercontent.com/flightlessmango/MangoHud/master/README.md)
- Anecdotal evidence (desktop RTX 4090): capping at 60 fps drew ~79% of average uncapped power, the frametime graph was "almost a perfect line", and lows were 13% higher; the user preferred an FPS cap over lowering power target — [Level1Techs forum](https://forum.level1techs.com/t/undervolting-my-rtx-4090/190315)
- Anecdotal laptop evidence: ROG Strix owner capped at 65-70 fps with undervolt and 77 °C target, reported no stutters; uncapped hit 120+ fps but ran hotter — [ASUS ROG forum](https://rog-forum.asus.com/t5/rog-strix-series/asus-rog-strix-ii-scar-laptop-normal-gaming-temperatures/m-p/870452)
- Laptop power-throttling pattern ("30 seconds at 100fps followed by 10 seconds at 20fps") was attributed to power throttling, not heat — [Dell community](https://www.dell.com/community/Inspiron/Dell-g5-5587-Usage-and-fps-drops/m-p/7329858)
- No rigorous laptop study testing FPS cap vs power-limit vs undervolt was found — (search result summary, see Gaps)
- KDE: Adaptive-Sync stutter/flicker fixes landed around Plasma 6.1; KWin 6.1 added triple buffering that only engages when a frame is predicted to miss; explicit sync (XWayland 24.1 + NVIDIA 555) fixed many NVIDIA-Wayland fullscreen problems; KDE guidance calls 555+ the practical floor — [Linux Journal](https://www.linuxjournal.com/content/kde-plasma-6-wayland-payoff-years-plumbing)
- 2025 NVIDIA+KDE VRR bug reports: erratic refresh with VRR during fullscreen video (Plasma 6.3.2, RTX 4090) — [CachyOS forum](https://discuss.cachyos.org/t/kde-plasma-nvidia-vrr-fullscreen-erratic-monitor-refresh/7050); fullscreen flicker/black screen after monitor sleep (Plasma 6.3) — [Arch BBS](https://bbs.archlinux.org/viewtopic.php?id=303951); fullscreen black screen fixed by disabling Adaptive Sync or rebooting (Plasma 6.2.5, NVIDIA 570.86.16) — [KDE Discuss](https://discuss.kde.org/t/black-screen-on-fullscreen-with-wayland/29368)
- "Always" policy: refresh fluctuated 48-120 Hz from Steam friend animations; users suggest "Always" interacts badly with triple buffering and recommend "Automatic" — [KDE Discuss](https://discuss.kde.org/t/different-way-of-handling-always-variable-refresh-rate/16428)
- "Always" can cause black flashes desktop-wide on some monitors, while "Never" displays fullscreen content normally — [freedesktop drm/amd #3162](https://gitlab.freedesktop.org/drm/amd/-/issues/3162)
- KWin doesn't dynamically drop the desktop to low Hz with VRR; rate changes mainly for fullscreen content — [Framework community](https://community.frame.work/t/auto-switch-60hz-165hz-on-off-battery-with-plasma-wayland/52538)

### Inferences
- Recommended stack: KDE Display settings → Adaptive Sync = "Automatic" (VRR only for fullscreen apps); game in borderless/exclusive fullscreen; in-game V-Sync off; cap 3-5 fps below panel max (for a 144 Hz panel, ~138-141) to stay inside the VRR window — or, for heat, cap much lower (60-90) since a lower cap directly reduces GPU power/heat. Preference order for the cap: in-game limiter (Frostbite's own, if it paces well) or `VKD3D_FRAME_RATE` / MangoHud `fps_limit` with `fps_limit_method=early`. Use only one limiter at a time.
- `DXVK_FRAME_RATE` is a DXVK variable and should have no effect on a DX12 title; this is based on DXVK/vkd3d split, not directly verified for this game.
- VRR on the TUF F15 internal panel: in hybrid (Optimus) mode the internal panel is typically driven by the Intel iGPU, so VRR on the internal display depends on the iGPU/panel (eDP Adaptive-Sync) rather than NVIDIA; whether the FX507ZC4 panel exposes Adaptive-Sync under Linux needs to be checked with `kscreen-doctor -o` (look for "Vrr: incapable/capable"). Not verified from sources.
- Expected effect: capping at ~60-75 fps in a racing game should cut GPU power substantially (the ~21% reduction in the RTX 4090 anecdote at a large headroom; more on a laptop that was otherwise pegged at its power limit) and flatten frametimes because the GPU stops bouncing between boost and power-limit states.

### Gaps
- No controlled laptop measurements of cap vs temps found; the numbers above are single-user anecdotes.
- Official KWin definition of the "Automatic" policy not found; behavior (fullscreen-only) is inferred from user reports.
- Whether the FX507ZC4's 144 Hz panel supports Adaptive-Sync in Linux was not researched.

## 2. Shader stutter: Steam pre-caching, fossilize, NVIDIA cache size, vkd3d-proton cache, DXVK_ASYNC/GPL

### Takeaway
For a DX12 game the relevant mechanisms are vkd3d-proton's own shader cache (on by default, stored in the game folder) plus the NVIDIA driver's disk cache — raise the NVIDIA cache limit and stop it from being cleaned. DXVK_ASYNC/GPL are DXVK (DX9-11) features and do nothing for vkd3d-proton; dxvk-async is obsolete since GPL (late 2022/2023). CachyOS recommends disabling Steam shader pre-caching when using proton-cachyos/GE.

### Cited Findings
- vkd3d-proton shader cache: by default writes `vkd3d-proton.cache` and `vkd3d-proton.cache.write` to the working directory (usually the game install folder in Steam); relocate with `VKD3D_SHADER_CACHE_PATH=/path`, disable with `VKD3D_SHADER_CACHE_PATH=0`; it caches DXBC/DXIL→SPIR-V conversion and "reduces stutter when pipelines would otherwise be created at the last minute, especially when the app relies on a warm driver cache"; with the internal cache on, the app's ID3D12PipelineLibrary is largely a dummy; `pipeline_library_app_cache` is an alternative mode sometimes enabled by app profiles — [vkd3d-proton README](https://github.com/HansKristian-Work/vkd3d-proton)
- CachyOS: disable Steam "Allow background processing of Vulkan shaders" and "Enable Shader Pre-caching" when using Proton-CachyOS/GE/EM; raise cache size in `~/.config/environment.d/gaming.conf`: NVIDIA `__GL_SHADER_DISK_CACHE_SIZE=12000000000`; example launch line uses `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` — [CachyOS wiki: Gaming](https://wiki.cachyos.org/configuration/gaming/)
- Steam pre-caching uses Fossilize; if processing isn't finished at launch Steam tries to finish first. Thread count can be set in `~/.steam/steam/steam_dev.cfg` via `unShaderBackgroundProcessingThreads N` (community guides; default reportedly 1; keep below CPU thread count) — [edu4rdshl blog, 2024](https://www.edu4rdshl.dev/posts/steam-on-linux-fixing-it); [GamingOnLinux 2020](https://www.gamingonlinux.com/2020/05/steam-beta-adds-vulkan-shader-processing/page=1) (2020 report that on NVIDIA processing used only 1 core — OLD, unverified today)
- dxvk-async removed in GE-Proton 7-45 (Jan 2023) because DXVK's Graphics Pipeline Library (GPL) supersedes it and async caused problems with the dxvk state cache; GPL NVIDIA support since driver 515.49.10, recommended 520.56.06+ — [GamingOnLinux](https://gamingonlinux.com/2023/01/ge-proton-removes-the-dxvk-async-patch-in-version-7-45/page=2); [SteamDeckHQ](https://steamdeckhq.com/news/proton-ge-7-44-is-released/) (2023, older but still the current state)
- gplasync fork users report it fixes non-streaming hitches but can show unshaded objects briefly (Mar 2025) — [r/dxvk mirror](https://redlib.hackliberty.org/r/dxvk/comments/1j0p4l9/question_about_the_gpl_async_fork)
- A ProtonDB report for NFS Unbound lists `DXVK_ASYNC` among launch options — [ProtonDB 1846380](https://www.protondb.com/app/1846380) (this has no effect on DX12/vkd3d-proton; see Inferences)

### Inferences
- For NFS Unbound (DX12): `DXVK_ASYNC=1` is placebo. The useful actions are: (1) set `__GL_SHADER_DISK_CACHE_SIZE=12000000000` and `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1` globally in `~/.config/environment.d/gaming.conf`; (2) let the vkd3d-proton cache persist in the game folder (don't delete it); (3) expect the first laps on each new map region / after each driver or Proton update to stutter while caches rebuild — measure on a second run.
- Steam pre-caching/Fossilize: with non-Valve Proton builds, Valve's pre-compiled Fossilize data is less likely to match, so disabling it (as CachyOS suggests) mainly saves background CPU time and heat after updates; with Proton Experimental/official Proton it may still help. Neither source quantifies the benefit.
- Frostbite compiles many PSOs at load/menu time; vkd3d-proton's cache helps reduce load times on later launches.

### Gaps
- NVIDIA's default `__GL_SHADER_DISK_CACHE_SIZE` value was not confirmed from a fetched source (NVIDIA README / Arch Wiki blocked). My recollection is ~1 GiB with automatic cleanup, but unverified.
- No benchmark quantifying stutter reduction from cache size changes for vkd3d-proton games on NVIDIA.

## 3. Proton variant choice and known NFS Unbound Linux issues

### Takeaway
NFS Unbound is ProtonDB Gold (168 reports, best Platinum, trending Gold). It works on Proton Experimental, Proton 9/10, recent GE-Proton and proton-cachyos, but reports conflict: the EA app and Denuvo license churn are the main breakers, not rendering. No DEVICE_HUNG-specific Unbound reports were found. NVAPI (needed for DLSS) is enabled by default for this game since Proton 8.0-3.

### Cited Findings
- ProtonDB summary for 1846380: tier gold, best platinum, trending gold, confidence strong, 168 reports — [ProtonDB API](https://www.protondb.com/api/v1/reports/summaries/1846380.json)
- Recent ProtonDB reports (via search snippets): working on "Proton 11.0 (beta)" and "Proton-CachyOS-11.0-slr", with `PROTON_ENABLE_NVAPI=1`; one reporter said DLSS fixed most of their performance problem; another runs fine on Proton 10.0-3 under Bazzite and says enabling Proton Wayland helps if it crashes on startup; another via Heroic + CachyOS Proton crashes at startup; some fixed launch crashes by switching Proton versions — [ProtonDB 1846380](https://www.protondb.com/app/1846380)
- Proton 8.0-3 enabled NVAPI by default for NFS Unbound — [Proton Changelog](https://github.com/ValveSoftware/Proton/wiki/Changelog)
- Proton issue #6502 history: Jan 2024 Denuvo license checks failing after restarts (EA app thinks it's a new PC); Mar 2024 VOL6 update caused very low FPS (menus ~20 fps) on an RTX 4060 — fixed by `sudo sysctl kernel.split_lock_mitigate=0` (back to 70-98 fps); Mar 2024 RTX 3060 Max-Q "Preparing Game" → black screen crash across Proton 5-9/Experimental; Sep 2025 crash from `libVkLayer_MESA_anti_lag.so`, fixed with `DISABLE_LAYER_MESA_ANTI_LAG=1` (Mesa MR !37509 to disable layer by default); Oct-Nov 2025 RTX 4060 Laptop (nvidia 580.95.05) crash at main menu, also on GE-Proton10-24 and reportedly on Windows 11 too; another user reported Proton 9.0-4, GE-Proton10-10 and Experimental working on AMD and NVIDIA; issue still open — [Proton #6502](https://github.com/ValveSoftware/Proton/issues/6502); [Proton #7561 VOL6 low fps](https://github.com/ValveSoftware/Proton/issues/7561)
- EA app launcher crashes across all Proton versions (Qt5Pdf.dll missing, 2024) affecting all EA app games — [Proton #7611](https://github.com/ValveSoftware/Proton/issues/7611); EA app improvements landed in Proton Experimental 2023 — [GamingOnLinux 2023](https://www.gamingonlinux.com/2023/05/proton-experimental-improves-ea-app-battlenet-and-nvapi-enabled-for-many-games/)
- On multi-GPU systems `VKD3D_FILTER_DEVICE_NAME="<substring>"` forces the discrete GPU (2023 workaround in #6502); vkd3d-proton documents `VKD3D_FILTER_DEVICE_NAME` and `VKD3D_VULKAN_DEVICE` — [Proton #6502](https://github.com/ValveSoftware/Proton/issues/6502); [vkd3d-proton README](https://github.com/HansKristian-Work/vkd3d-proton)
- proton-cachyos: NTSync enabled by default (`PROTON_NO_NTSYNC=1` to disable); use `proton-cachyos-slr` for EAC/BattlEye games — [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/)
- General NVIDIA DX12 gap: CachyOS wiki notes a DX12 performance drop on NVIDIA tied to how the NVIDIA driver handles GPU scheduling, with no official statement/workaround — [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/); NVIDIA 595.44.06 Vulkan beta (May 2026) added/fixed `VK_EXT_descriptor_heap` — [Phoronix](https://phoronix.com/news/NVIDIA-595.44.06-Vulkan-Beta); vkd3d-proton merged descriptor heap support (May 27, 2026) behind `VKD3D_CONFIG=descriptor_heap` because NVIDIA bugs remain — [Phoronix](https://phoronix.com/news/vkd3d-proton-descriptor-heaps); forum users report mixed results (black screens, broken DLSS) — [NVIDIA forum thread](https://forums.developer.nvidia.com/t/directx12-performance-is-terrible-on-linux/303207?page=37) (snippet only; page 403)
- vkd3d-proton 3.0.1 released May 2026 — [GamingOnLinux](https://www.gamingonlinux.com/2026/05/vkd3d-proton-3-0-1-brings-many-linux-gaming-enhancements-for-direct3d-12-via-vulkan/comment_id=294024)
- vkd3d-proton: NVIDIA driver 535 minimum; try latest stable/beta/Vulkan beta when problems occur; `force_static_cbv` is an "unsafe" NVIDIA speed hack; `no_upload_hvv` frees VRAM at a GPU-performance cost; `single_queue` disables async compute/transfer queues (debug) — [vkd3d-proton README](https://github.com/HansKristian-Work/vkd3d-proton)

### Inferences
- Practical order to try for NFS Unbound on NVIDIA: (1) Proton Experimental (Valve-tested EA app fixes); (2) proton-cachyos (latest, NTSync, newest vkd3d-proton); (3) GE-Proton latest. If the EA app or game crashes at start, switching Proton version or adding `PROTON_ENABLE_WAYLAND=1` (proton-cachyos/GE/11 Wayland driver) is the reported fix. Keep the same Proton version once working, because each change can trigger Denuvo/EA re-activation (license limit) and cache rebuild.
- `kernel.split_lock_mitigate=0` is directly relevant (VOL6+ Frostbite split-lock slowdown on Intel CPUs, and the TUF F15 has an Intel 12th-gen CPU). CachyOS's cachyos-settings package is believed to set this by default, but verify with `sysctl kernel.split_lock_mitigate` (not confirmed from a fetched source).
- `VKD3D_CONFIG=descriptor_heap` is experimental (as of mid-2026) and may break DLSS; not recommended for a stability/heat goal.
- `DXGI_ERROR_DEVICE_HUNG` in Frostbite DX12 under vkd3d-proton is usually a GPU hang; generic mitigations are updating NVIDIA driver/vkd3d-proton and removing overclocks/undervolts. Not Unbound-specific evidence.

### Gaps
- No Unbound-specific DEVICE_HUNG reports or Reddit 2025-2026 threads were found.
- Full per-report ProtonDB text (dates, GPUs) could not be retrieved; only snippets.
- No head-to-head benchmark of Proton Experimental vs proton-cachyos vs GE for this game.

## 4. CachyOS specifics: game-performance, ananicy-cpp, scx schedulers, kernels

### Takeaway
`game-performance %command%` switches power-profiles-daemon to performance during the game (and the active scx scheduler to its gaming profile) — this raises clocks and therefore heat, the opposite of the heat goal. Don't combine GameMode with ananicy-cpp. scx_lavd is designed for gaming/handhelds with an automatic power mode, but evidence that it reduces stutter on laptops is anecdotal and mixed.

### Cited Findings
- `game-performance`: uses power-profiles-daemon to switch to `performance` while the game runs, restores on exit, also switches an active scx scheduler to its gaming profile; usage `game-performance %command%`; may not help on old CPUs — [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/)
- GameMode offers similar functionality; don't combine with ananicy-cpp (both adjust niceness); stop with `systemctl stop ananicy-cpp` — [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/)
- Launch option pattern `[env] [wrappers] %command% [args]`, example `__GL_SHADER_DISK_CACHE_SKIP_CLEANUP=1 prime-run game-performance %command% -dx11`; Proton logs via `PROTON_LOG=1` — [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/)
- scx_lavd described as "developed for Gaming and mainly for handhelds" (May 2024 tutorial; possibly outdated); scx_rusty "very interactive and stress resistant"; scx_rustland has userspace overhead; schedulers set via `/etc/default/scx` + `systemctl enable --now scx` (older method) — [CachyOS forum tutorial](https://discuss.cachyos.org/t/tutorial-using-sched-ext-and-its-schedulers/158)
- scx_lavd default mode "automatically decide[s] the scheduler's power mode based on system load"; separate explicit performance and energy-profile modes exist — [CachyOS forum](https://discuss.cachyos.org/t/helper-scripts-and-schedulers-explanation/7149)
- Single-user Cyberpunk 2077 desktop benchmark: scx_lavd had higher frametime variance than scx_cake — [CachyOS forum](https://discuss.cachyos.org/t/performance-optimization-how-to-set-scx-cake-as-default-or-add-it-to-scx-manager-gui/20917)
- Kernel manager can set the scheduler permanently; SCX Manager GUI reportedly mishandles custom schedulers — [CachyOS forum](https://discuss.cachyos.org/t/performance-optimization-how-to-set-scx-cake-as-default-or-add-it-to-scx-manager-gui/20917)

### Inferences
- For a hot laptop, skip `game-performance` (or use it only when plugged in and cooling is not the constraint). Forcing the platform `performance` profile raises CPU boost behavior; the CPU and GPU share a heat pipe assembly on most thin gaming laptops, so less CPU heat leaves more thermal headroom for the GPU. Better: keep `balanced` and cap FPS.
- Scheduler choice is a second-order effect for GPU-bound DX12 racing at capped FPS; the default EEVDF/BORE kernel scheduler is a reasonable baseline. If testing scx, compare with MangoHud logs (1% / 0.1% lows) rather than feel.
- Keep ananicy-cpp (CachyOS default) and don't add GameMode on top.

### Gaps
- No laptop-specific evidence that sched-ext schedulers reduce stutter.
- Current (2026) CachyOS scx defaults and scx_loader/scxctl tooling not verified.
- Kernel variants (linux-cachyos vs -bore vs -lts) were not compared for gaming in any found source.

## 5. NVIDIA env vars, DLSS/Reflex on Linux, lowering GPU load

### Takeaway
DLSS Super Resolution works through DXVK-NVAPI (bundled in Proton; NVAPI is already enabled by default for Unbound), and is the best way to cut GPU load/heat while keeping image quality. Native DLSS Frame Generation is not available on RTX 30. Reflex works for DX games out of the box via DXVK-NVAPI. `__GL_THREADED_OPTIMIZATIONS` is an OpenGL setting and is irrelevant to vkd3d-proton (Vulkan).

### Cited Findings
- Proton includes DXVK-NVAPI by default; games must support DLSS natively; titles without NVAPI show no DLSS options — [NVIDIA driver docs: DLSS / Smooth Motion / Reflex](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/gaming.html)
- `PROTON_ENABLE_NGX_UPDATER=1` updates the DLSS DLLs bundled with the game; settings overrides `DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE=on` and `DXVK_NVAPI_DRS_NGX_DLSS_SR_OVERRIDE_RENDER_PRESET_SELECTION=render_preset_latest` (also RR/FG variants); preset availability depends on DXVK-NVAPI version (use newer Proton/Experimental) — [NVIDIA docs](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/gaming.html)
- DLSS indicator: `DXVK_NVAPI_SET_NGX_DEBUG_OPTIONS=DLSSIndicator=1024,DLSSGIndicator=2` (persists in prefix; set to 0 to remove) — [NVIDIA docs](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/gaming.html)
- Smooth Motion: `NVPRESENT_ENABLE_SMOOTH_MOTION=1`, for titles without native FG; native FG and Smooth Motion "should not be used together" — [NVIDIA docs](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/gaming.html) (page does not state GPU-generation requirements)
- Reflex: DirectX under Proton supported out of the box via DXVK-NVAPI; Vulkan games need `DXVK_NVAPI_VKREFLEX=1` and `VK_NV_low_latency2` — [NVIDIA docs](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/gaming.html)
- GPU utilization reporting under Proton needs wine-nvml installed manually — [NVIDIA docs](https://docs.nvidia.com/datacenter/tesla/driver-installation-guide/gaming.html)
- CachyOS offers `dlss-swapper %command%` wrapper (and `dlss-swapper-dll`) to use newer DLSS DLLs — [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/)
- 2024 Proton added Optical Flow SDK for Turing/Ampere/Ada and DLSS 3 FG support — [PCGH](https://www.pcgameshardware.de/Linux-Software-26761/News/DLSS-3-Frame-Generation-mit-Proton-unter-Linux-1459522/); an RTX 3060 user saw no FG options in games — [CachyOS forum](https://discuss.cachyos.org/t/dlss-frame-gen-is-now-possible-in-linux/3749)
- DLSS 4.5 Dynamic Multi Frame Generation (CES Jan 2026) targets RTX 50; DLSS Updater app gained Linux support — [GamingOnLinux Jan 2026](https://www.gamingonlinux.com/2026/01/nvidia-announce-dlss-4-5-with-dynamic-multi-frame-generation-plus-dlss-updater-gets-linux-support/page=1/)
- ProtonDB Unbound reporter: DLSS was what fixed most of the performance problem — [ProtonDB 1846380](https://www.protondb.com/app/1846380)

### Inferences
- `PROTON_ENABLE_NVAPI=1` is harmless but redundant for Unbound on Proton ≥8.0-3 (NVAPI whitelisted).
- DLSS Frame Generation (DLSS 3/4) requires RTX 40+ hardware on any OS, so it won't appear on an RTX 3050 laptop; the Optical Flow mention for Ampere refers to the SDK, not FG eligibility (from general knowledge, consistent with the RTX 3060 user's report). Smooth Motion RTX 30 eligibility under Linux is unverified.
- Heat-reduction recipe on the GPU side: DLSS Quality/Balanced (lower internal render res) + FPS cap + Reflex On (reduces render queue; often slightly lowers GPU load when GPU-bound). `PROTON_ENABLE_NGX_UPDATER=1` or dlss-swapper to get a newer DLSS model (better image at Balanced/Performance, letting you drop internal res further).
- `__GL_THREADED_OPTIMIZATIONS` only affects OpenGL; no effect on DX12/Vulkan. Skip.
- `VKD3D_CONFIG=force_static_cbv` is labeled unsafe; not worth the stability risk.

### Gaps
- RTX 30 Smooth Motion support status on Linux drivers (590/595+) not confirmed.
- No measurements of power reduction from DLSS on Linux.

## 6. Measuring frametime spikes on Linux (MangoHud)

### Takeaway
Use MangoHud with frametime graph + throttling status + temps/power, and log runs to CSV (Shift_L+F2) to compare 1% / 0.1% lows and spike counts before/after each change, on a fixed route and after caches are warm.

### Cited Findings
- `frame_timing` graph on by default; `histogram` switches graph type; `fps_metrics=avg,0.01,0.001` shows avg and percentile lows; `benchmark_percentiles` default `97,AVG,1,0.1` in log summary; `reset_fps_metrics` Shift_R+F9 — [MangoHud README](https://raw.githubusercontent.com/flightlessmango/MangoHud/master/README.md)
- Logging: `output_folder` (required), `output_file`, `log_duration` (s), `autostart_log=`, `toggle_logging` (default Shift_L+F2), `log_interval` ms (default 0 = every frame), `log_versioning` — [MangoHud README](https://raw.githubusercontent.com/flightlessmango/MangoHud/master/README.md)
- `throttling_status` shows GPU power/current/temp throttling, disabled by default for NVIDIA; `gpu_temp`, `cpu_temp`, `gpu_power`, `cpu_power`, `gpu_core_clock`, `gpu_mem_clock` — [MangoHud README](https://raw.githubusercontent.com/flightlessmango/MangoHud/master/README.md)
- `MANGOHUD_CONFIG` inline config overrides files; prepend `read_cfg` to also load file config; use `+` for multi-values — [MangoHud README](https://raw.githubusercontent.com/flightlessmango/MangoHud/master/README.md)
- vkd3d-proton logging: `VKD3D_DEBUG`, `VKD3D_LOG_FILE`; Proton: `PROTON_LOG=1` — [vkd3d-proton README](https://github.com/HansKristian-Work/vkd3d-proton); [CachyOS wiki](https://wiki.cachyos.org/configuration/gaming/)
- Test method: plugged in, hard surface, fixed scene, log temps — [Acer community guide](https://community.acer.com/en/discussion/724763/ultimate-laptop-cooling-optimization-guide)

### Inferences
- Example Steam launch line for testing NFS Unbound:
  `MANGOHUD_CONFIG=read_cfg,fps,frametime,frame_timing,fps_metrics=avg+0.01+0.001,gpu_temp,cpu_temp,gpu_power,gpu_core_clock,throttling_status,output_folder=/home/m/mangologs,log_duration=180 VKD3D_FRAME_RATE=60 mangohud %command%`
  (note `+` separators for multi-value inside MANGOHUD_CONFIG). Compare logs with the MangoHud log uploader/FlightlessMango site or a spreadsheet.
- Distinguish spike types: a single-frame spike when new effects appear and that disappears on a second run is shader compilation; periodic dips with `throttling_status` = Power/Temp and falling `gpu_core_clock` are thermal/power throttling (fix with cap/DLSS, not shader settings); spikes correlated with CPU temp/clock drop point at CPU throttling.
- A/B protocol: one variable at a time, same route (e.g. a fixed race), 3 runs each, discard first run after any driver/Proton change (cache rebuild).

### Gaps
- MangoHud on NVIDIA may need `throttling_status` explicitly enabled; reliability of NVIDIA throttle reasons via NVML on laptops wasn't verified.
