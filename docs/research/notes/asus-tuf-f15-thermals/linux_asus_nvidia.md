# ASUS TUF F15 FX507ZC4 (i7-12700H + RTX 3050 Laptop, Ampere) on Linux vs Windows: asusd/asusctl, supergfxctl, NVIDIA, CPU, stutter

Research date: 2026-10-17. Some findings below come from read-only inspection of the user's own machine. They are marked **[LOCAL]**, with the command or sysfs path they came from. Local versions: asusctl 6.5.0, supergfxctl 5.2.7, nvidia-utils 615.78.08 (open modules), linux-cachyos 7.2.9, power-profiles-daemon 0.30, BIOS FX507ZC4.312. thermald and tuned are not installed or not active.

## 1. asusd/asusctl 6.x: profiles, PPT values, asus-armoury attributes, fan curves

### Takeaway
On kernel 7.2 the asus-armoury firmware-attributes driver is present and exposes `ppt_pl1_spl`, `ppt_pl2_sppt` and `nv_dynamic_boost` for the FX507Z. Their ranges (PL1 28–90 W, PL2 28–135 W, Dynamic Boost 5–15 W) match Armoury Crate's maximums. The firmware default equals the maximum (90/135/15), which is effectively Windows "Turbo". asusd 6.x applies **per-profile, per-AC/DC user tunings** stored in `/etc/asusd/asusd.ron`; it does not apply fixed vendor presets. On this machine the Performance profile is currently capped **below** firmware Turbo (PL1 80 / PL2 95 / DB 15). `nv_temp_target` and `nv_tgp` are not exposed for this model.

### Cited Findings
- The asus-armoury patch v17 9/9, "add ppt_* and nv_* tuning knobs", has an `FX507Z` DMI entry. AC: ppt_pl1_spl min 28 / max 90, ppt_pl2_sppt min 28 / max 135, nv_dynamic_boost min 5 / max 15. DC: PL1 25–45, PL2 35–60, no DC Dynamic Boost. No nv_temp_target, nv_tgp, nv_base_tgp or pl3_fppt is defined. The entry has `requires_fan_curve = true`. When no `_def` is given, default = max. An attribute is created only if its AC max exists. Tunables are stored separately for AC (index 1) and DC (index 0). The ranges were derived from Armoury Crate because ASUS doesn't publish them — [LKML v17 9/9](https://lkml.iu.edu/2511.0/00952.html)
- The driver lives at `/sys/class/firmware-attributes/asus-armoury/attributes/<name>/{current_value,min_value,max_value,default_value,...}`. It is meant to supersede the older asus-wmi sysfs knobs — [LKML v6 3/9](https://lkml.rescloud.iu.edu/2409.3/06721.html); [asus-armoury.c source](https://gbmc.googlesource.com/linux/+/refs/heads/master/drivers/platform/x86/asus-armoury.c)
- **[LOCAL]** `/sys/class/firmware-attributes/asus-armoury/attributes/` lists charge_mode, dgpu_disable=0, gpu_mux_mode=1, nv_dynamic_boost=15 (5/15/def 15), panel_overdrive=1, ppt_pl1_spl=**80** (28/90/def 90), ppt_pl2_sppt=**95** (28/135/def 135). Platform profile = performance; choices are quiet, balanced, performance. The driver's table is confirmed active on this BIOS.
- A user report on G-Helper (FX507ZC4) says Armoury Crate's maximums are PL1 90 W and PL2 135 W. It also reports that GPU offsets above roughly +200 core / +300 mem MHz caused stutter and crashes — [g-helper #2104](https://github.com/seerge/g-helper/issues/2104)
- Notebookcheck measured the sibling FX507ZM (same i7-12700H) at 90 W PL1 and 115 W PL2 — [Notebookcheck FX507ZM review](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html)
- asusctl changelog (6.x):
  - v6.1.0-rc6: "Move to using platform_profile api only (no throttle_thermal_policy)"
  - rc4: "Allow each performance profile to have different PPT settings"
  - rc5: "Per-AC/DC, per-profile tunings enabled" and "Add ability to restore PPT defaults"
  - rc7: "Selecting a profile defaults PPT to off/disabled" and "Do not apply unless group is enabled"
  - v6.1.22: "Allow configuration of nv_tgp" and "Treat dGPU attributes as power profiles"
  - v6.3.5: nv_tgp slider
  - v6.3.7: "Load fan profiles at start"
  - v6.3.8: "Prevent setting custom TDP without a custom fan curve"

  Source: [asusctl CHANGELOG](https://gitlab.com/asus-linux/asusctl/-/raw/main/CHANGELOG.md)
- **[LOCAL]** `/etc/asusd/asusd.ron` has `ac_profile_tunings` enabled for each profile:
  - Quiet: PL1 35 / PL2 55 / DB 5
  - Balanced: PL1 55 / PL2 85 / DB 10
  - Performance: PL1 80 / PL2 95 / DB 15

  `dc_profile_tunings` are disabled. Other settings: `platform_profile_linked_epp: true` (Quiet→power, Balanced→balance_power, Performance→performance EPP), `platform_profile_on_ac: Performance`, `platform_profile_on_battery: Quiet`, `disable_nvidia_powerd_on_battery: true`. These values are user/asusctl-set, not firmware presets.
- Fan curves: the old asus-linux FAQ says custom curves are "only supported on Ryzen ROG laptops". It says they are tied to the Quiet/Balanced/Performance profiles via `asusctl fan-curve -m <profile> -e true`, and "If no profile is activated manually then the fan curve from the BIOS is used" — [asus-linux FAQ](https://asus-linux.org/faq/). **[LOCAL]** contradicts the Ryzen-only statement for this Intel TUF: hwmon7 exposes `pwm1/2_auto_point1..8_{temp,pwm}`. `asusctl fan-curve --get-enabled` shows CPU and GPU curves **enabled** for the active profile: 45c:14%, 55c:25%, 62c:34%, 68c:47%, 74c:61%, 80c:78%, 85c:90%, 90c:100%. Fan RPM is read from `/sys/devices/platform/asus-nb-wmi/hwmon/hwmon*/fan{1,2}_input`; it read 5700/4700 RPM at sampling time.

### Inferences
- "Performance" on Linux corresponds to Armoury Crate's Turbo/Performance platform-profile tier at the EC level. Watts are a separate matter: asusd overwrites them with whatever group is enabled. With PL1 80 / PL2 95 the CPU runs about 10 W below Turbo's sustained maximum and 40 W below its burst maximum. That should *reduce* heat versus Windows Turbo, not increase it. To replicate Windows Turbo exactly, set the Performance group to 90/135/15 or disable the group so firmware defaults apply. To run cooler than Windows, keep or lower these caps.
- Because `requires_fan_curve = true` and asusctl 6.3.8 blocks custom TDP without a custom fan curve, the custom PPT on this machine is coupled to the custom fan curve shown. That curve may be gentler or harsher than the EC's Turbo curve; no source documents the Windows Turbo curve for comparison.

### Gaps
- No primary source gives the exact Windows Armoury Crate Silent/Performance/Turbo watt values for the FX507ZC4. Only the maximums (90/135/15) are corroborated. Nor is the stock EC Turbo fan curve or the fans' max RPM documented. The 5700 RPM local reading is an observed value, not a spec.
- I could not confirm which mainline kernel version merged the final asus-armoury PPT patch. CachyOS 7.2 clearly ships it.

## 2. NVIDIA Dynamic Boost on Linux (nvidia-powerd) and the real GPU power limit

### Takeaway
Dynamic Boost is supported on this laptop and works: the NVIDIA proc file reports "Notebook Dynamic Boost: Supported". `nvidia-smi` shows Default 80 W → Current/Max 95 W, which is 80 W base plus 15 W `nv_dynamic_boost`. So the Linux ceiling matches the configured Windows maximum, and the GPU is not TGP-starved. nvidia-powerd still logs recurring `JPAC is not created` and `Failed to get SysPwrLimitGetInfo` errors; I found no documentation for these.

### Cited Findings
- NVIDIA README (580 series, still current in structure):
  - Requirements: notebook only, "Ampere or newer GPUs", "Intel CometLake or newer", SBIOS support, systemd, D-Bus, cpufreq.
  - Enabling: copy `nvidia-dbus.conf` to `/etc/dbus-1/system.d`, then `systemctl enable --now nvidia-powerd`.
  - Verify SBIOS support via `/proc/driver/nvidia/gpus/<bus>/power` or `nvidia-settings -q DynamicBoostSupport`.
  - Behaviour: it only activates under sufficient GPU load. It controls the CPU by writing cpufreq `scaling_max_freq`. On DC it may cost performance.

  Source: [NVIDIA README – Dynamic Boost](https://download.nvidia.com/XFree86/Linux-x86_64/580.95.05/README/dynamicboost.html)
- Community reports:
  - Limits showing "N/A" or a Max equal to Default indicate Dynamic Boost is not active. In one case enabling nvidia-powerd raised the max to 175 W.
  - A heuristic: "If Max Power Limit = Default, then Dynamic Boost is impossible".
  - One secondary source says drivers ≥550 block `nvidia-smi -pl` on laptops.
  - On an HP Omen the firmware reported "Client (presumably SBIOS) has requested to disable Dynamic Boost".

  Sources: [NVIDIA forum – stuck at 95 W](https://forums.developer.nvidia.com/t/ubuntu-nvidia-smi-power-limit-stuck-at-95w/364197); [PCLinuxOS mag 2026-06](https://pclosmag.com/html/Issues/202606/page11.html); [HP Omen 80 W thread](https://forums.developer.nvidia.com/t/hp-omen-max-16-rtx-5070-ti-laptop-gpu-power-locked-at-80w-on-linux-ubuntu-24-04-3-lts/351924); [MSI Katana low limit](https://forums.developer.nvidia.com/t/linux-kubuntu-26-04-nvidia-gpu-msi-katana-laptop-low-power-limit/368081)
- An Arch user hypothesised that ACPI errors (an unresolved BPWM symbol) and asusd crashes broke EC negotiation of the TGP budget. This is a hypothesis, not confirmed — [Arch BBS 313511](https://bbs.archlinux.org/viewtopic.php?id=313511)
- asus-linux FAQ: start nvidia-powerd, set the profile to Performance, and verify with nvtop/MangoHud. A driver bug that caused excessive nvidia-powerd CPU use was fixed in 530.41.03 / 525.105.17 — [asus-linux FAQ](https://asus-linux.org/faq/)
- **[LOCAL]** `nvidia-smi -q -d POWER` reports Current Power Limit 95.00 W, Default 80.00 W, Max 95.00 W, Min 1.00 W, Requested N/A; draw was 35.6 W during sampling. `/proc/driver/nvidia/gpus/*/power` reports "Notebook Dynamic Boost: Supported". `journalctl -u nvidia-powerd` shows repeated "ERROR! JPAC is not created/already destroyed" and "CRITICAL! Failed to get SysPwrLimitGetInfo".

### Inferences
- Linux is not running the RTX 3050 at a lower TGP than Windows here: 80 + 15 = 95 W, the most the asus-armoury table allows. The heat difference against Windows is therefore unlikely to come from a higher GPU limit. Note that Dynamic Boost works by lowering CPU `scaling_max_freq` when the GPU is loaded, so CPU clocks in games may be capped by nvidia-powerd.
- How to read the real limit: `nvidia-smi -q -d POWER` (Current vs Default vs Max), plus `nvidia-smi --query-gpu=power.draw,power.limit,clocks.gr,temperature.gpu --format=csv -l 1` under load. If Current stays at 80 W, Dynamic Boost is not engaging.
- The SysPwrLimitGetInfo/JPAC errors may mean the total-system-power (JPAC) budget negotiation fails while the per-GPU boost still applies. This is unverified.

### Gaps
- No public source explains the `JPAC` and `SysPwrLimitGetInfo` messages. A targeted search returned nothing relevant.
- I found no direct Windows-vs-Linux measured TGP comparison for the FX507ZC4.

## 3. MUX switch / supergfxctl modes vs PRIME render offload on Plasma 6 Wayland

### Takeaway
The system is in Hybrid mode (`gpu_mux_mode=1`, supergfxctl "Hybrid"); the available modes are Integrated, Hybrid and AsusMuxDgpu. In Hybrid, games render on the NVIDIA GPU and frames are copied to the Intel iGPU, which drives the panel. AsusMuxDgpu wires the panel to the NVIDIA GPU directly and always requires a reboot. I found no rigorous benchmark of AsusMuxDgpu versus PRIME offload on KWin Wayland. The documented costs of PRIME are a buffer copy through the iGPU and the iGPU staying busy compositing.

### Cited Findings
- From the supergfxctl README:
  - Modes are Integrated (dGPU force-disabled), Hybrid (dGPU offload), Vfio, AsusEgpu, and AsusMuxDgpu ("toggles the ASUS MUX to make the dGPU primary").
  - "Switching to/from Hybrid mode requires a logout only"; for AsusMuxDgpu "A reboot is *always* required due to how this works in ACPI".
  - Runtime D3 "has been buggy in some use cases".
  - It conflicts with optimus-manager, suse-prime, system76-power and bbswitch.
  - "Xorg is no-longer supported".

  Source: [supergfxctl README](https://gitlab.com/asus-linux/supergfxctl/-/raw/main/README.md)
- The asus-linux FAQ notes lag on external displays wired to the dGPU in Hybrid mode, with X11 or an iGPU-wired USB-C adapter as workarounds. Failed switches are diagnosed via `journalctl -b -u asusd` and run from a TTY — [asus-linux FAQ](https://asus-linux.org/faq/)
- From the CachyOS wiki (updated 2026-07): PRIME offload works out of the box with nvidia-utils and cachyos-settings. Use `prime-run %command%` in Steam. For DX12 games that pick the wrong GPU, add `VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json`. Avoid optimus-manager — [CachyOS Dual GPU](https://wiki.cachyos.org/configuration/dual_gpu/)
- NVIDIA describes render offload as "particularly useful in combination with dynamic power management". PRIME uses shared memory, so frames cross the iGPU — [NVIDIA README PRIME Render Offload](https://download.nvidia.com/XFree86/Linux-x86_64/510.54/README/primerenderoffload.html); [NVIDIA forum](https://forums.developer.nvidia.com/t/prime-render-offloading-on-nvidia-optimus/44439)
- Plasma/NVIDIA state:
  - Plasma 6.6.5 fixed stutter and freezes with NVIDIA R595 on Wayland — [Ubunlog](https://en.ubunlog.com/?p=57859)
  - A 2026 benchmark of Plasma 6.7.2 with driver 610.43.02 on an RTX 5090 desktop found Wayland equal to or better than X11 in games — [WebProNews](https://www.webpronews.com/plasma-6-7-benchmarks-show-wayland-pulling-ahead-on-nvidia-hardware/)

  Both are desktop or general results, not laptop MUX results.
- **[LOCAL]** `supergfxctl -g` → Hybrid; `supergfxctl -s` → [Integrated, Hybrid, AsusMuxDgpu].

### Inferences
- In Hybrid mode the iGPU shares the CPU package power and thermal budget, since it composites and scans out every game frame. AsusMuxDgpu removes the PRIME copy and the iGPU load, which typically gives slightly higher FPS, lower latency and possibly VRR on the internal panel. The trade-off is that the dGPU can never power down, so idle power and heat rise and battery life drops. For gaming-only sessions on AC, AsusMuxDgpu is the configuration most like Windows "Ultimate/dGPU" mode.
- In Hybrid, check that the game actually runs on NVIDIA (`prime-run`, MangoHud's GPU line). A game accidentally rendered on the Intel iGPU would heat the CPU package and perform poorly.

### Gaps
- I found no 2025–2026 source with measured frametime or latency for AsusMuxDgpu versus PRIME on KWin Wayland with NVIDIA 5xx/6xx. I also found no confirmed current bug list for AsusMuxDgpu on Wayland; the only report found was an old 2024 Plasma 5 black-screen case after a supergfx switch ([Arch BBS 292682](https://bbs.archlinux.org/viewtopic.php?id=292682)).
- I found no source on VRR or G-Sync availability on the internal panel in each mode.

## 4. CPU: intel_pstate EPP/governor, power-profiles-daemon with asusd, thermald, undervolting

### Takeaway
On this system asusd sets EPP per profile (`platform_profile_linked_epp: true`). Performance maps to EPP `performance` with the `powersave` intel_pstate governor, the normal active-mode combination. That EPP lets the 12700H boost aggressively, which is a major source of heat in CPU-bound games. Software undervolting on Alder Lake is effectively locked (MSR 0x150) on both Windows and Linux. The practical levers are PL1/PL2, EPP, and capping max frequency or disabling turbo.

### Cited Findings
- **[LOCAL]** `scaling_governor` = powersave and `energy_performance_preference` = performance. power-profiles-daemon 0.30 is active alongside asusd. tuned and thermald are inactive or not installed. In asusd.ron the profile→EPP mapping is quiet→Power, balanced→BalancePower, performance→Performance.
- The asus-linux FAQ recommends having power-profiles-daemon installed so the desktop's profile control works, and setting profiles via `asusctl profile -P`, ROG Control Center, or the DE — [asus-linux FAQ](https://asus-linux.org/faq/). The asusctl changelog mentions power-profiles-daemon only for v4.0.0 ("profiles now depend on power-profile-daemon"); 6.x uses the kernel platform_profile API directly — [asusctl CHANGELOG](https://gitlab.com/asus-linux/asusctl/-/raw/main/CHANGELOG.md)
- Dynamic Boost (nvidia-powerd) also manipulates CPU `scaling_max_freq` while the GPU is loaded — [NVIDIA README – Dynamic Boost](https://download.nvidia.com/XFree86/Linux-x86_64/580.95.05/README/dynamicboost.html)
- Undervolting:
  - Intel disabled undervolting through ADL microcode and XTU changes ("does not allow voltage to be set lower than default voltage") — [Dell KB XPS 15 9520](https://www.dell.com/support/kbdoc/en-us/000211454/xps-15-9520-no-way-to-undervolt-the-computer-after-bios-v1-7-0?lang=en)
  - The ThrottleStop author says the lock may be Intel's fix for Plundervolt, and warns that BIOS voltage edits could brick 12th-gen laptops — [TechPowerUp 12700H thread](https://www.techpowerup.com/forums/threads/undervolting-i7-12700h-laptop.297533/)
  - intel-undervolt returns "Values do not equal" on 12th gen — [Manjaro forum](https://forum.manjaro.org/t/whether-intel-undervolt-is-no-longer-supported-values-do-not-equal-after-config/111890)
  - The `undervolt` tool uses MSR 0x150 — [PyPI undervolt](https://www.pypi.org/project/undervolt/0.2.3/)

### Inferences
- Effective CPU heat levers on Linux, in rough order of impact:
  1. PL1/PL2 via asusctl (already 80/95; 45–65 W PL1 trades a little FPS for much lower temps)
  2. EPP `balance_performance` instead of `performance` in the Performance profile (`profile_performance_epp`)
  3. `echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo` or a `scaling_max_freq` cap for GPU-bound games
- power-profiles-daemon and asusd both act on profiles. Leave only one owner of EPP: asusd with linked EPP. Changing profiles in KDE's battery applet goes through ppd, which can also set EPP and platform_profile, so the two daemons can fight. This is not documented by a source found here.
- thermald: no 2024–2026 source found on its value for Alder Lake laptops whose EC/WMI already enforces limits; its benefit is likely marginal next to asusd's PPT control.

### Gaps
- No primary source found for thermald on Alder Lake ASUS laptops, nor for measured EPP-versus-temperature results in games.
- No official asus-linux statement on ppd and asusd 6.x arbitration.

## 5. Known Linux stutter causes on such laptops and fixes

### Takeaway
On this setup the documented candidates are:
- **RTD3 fine-grained power management** (`NVreg_DynamicPowerManagement=3`, active here): wake latency when the dGPU powers back up.
- **PRIME copy and iGPU compositing** in Hybrid mode.
- **NVIDIA/KWin Wayland driver bugs**, fixed in recent Plasma 6.6.x.
- **Overclock offsets**, and **CPU frequency clamping** by nvidia-powerd or low PL limits.

The GSP firmware is mandatory with the open modules, and I found no current source tying it to stutter on Ampere laptops.

### Cited Findings
- NVIDIA RTD3:
  - Value 0x03 is the default; on Ampere+ notebooks it "translates to fine-grained power control". 0x02 powers the GPU down after short idle periods even while apps run; 0x01 sleeps only when no clients exist; 0x00 disables RTD3.
  - Entry and exit add latency, and a higher VRAM threshold "will increase the latency during RTD3 entry and exit transitions" (default 200 MB, max 1024 MB, 0 keeps VRAM on).
  - The GPU stays active while driving a display or running CUDA.
  - Status is read from `/proc/driver/nvidia/gpus/<bus>/power`.

  Source: [NVIDIA README – Dynamic Power Management](https://download.nvidia.com/XFree86/Linux-x86_64/580.95.05/README/dynamicpowermanagement.html)
- supergfxctl says Runtime D3 "has been buggy in some use cases" — [supergfxctl README](https://gitlab.com/asus-linux/supergfxctl/-/raw/main/README.md)
- The asus-linux FAQ lists processes that keep the NVIDIA GPU from sleeping: GPU monitoring widgets, ollama, rtkit — [asus-linux FAQ](https://asus-linux.org/faq/)
- Plasma 6.6.5 fixed stutter and visual freezes with NVIDIA R595 drivers on Wayland, especially multi-monitor — [Ubunlog](https://en.ubunlog.com/?p=57859)
- GPU offsets above roughly +200 core / +300 mem caused stutter and crashes on an FX507ZC4 (Windows/G-Helper) — [g-helper #2104](https://github.com/seerge/g-helper/issues/2104)
- **[LOCAL]** `/proc/driver/nvidia/params` shows DynamicPowerManagement: 3, threshold 200, EnableS0ixPowerManagement: 0. The power proc file shows "Runtime D3 status: Enabled (fine-grained)" and Video Memory Active at sampling. The kernel cmdline is `quiet nowatchdog splash rw rootflags=subvol=/@ root=UUID=...`, with no nvidia or i915 tuning params.

### Inferences
- If stutter appears mostly at game start, alt-tab, or in light or menu scenes, test `options nvidia NVreg_DynamicPowerManagement=0x01` (or 0x00) in `/etc/modprobe.d/`. That removes fine-grained power-down while a client is open, at a small idle-power cost. During active rendering the GPU should stay awake regardless.
- For constant micro-stutter in Hybrid mode, compare against AsusMuxDgpu (reboot). If the stutter disappears, PRIME or iGPU composition is the cause.
- Check MangoHud frametimes alongside CPU clocks. If CPU clocks drop when the GPU is loaded, nvidia-powerd is lowering `scaling_max_freq`, or PL1 80 W / PL2 95 W is limiting. Either can cause CPU-bound frametime spikes.

### Gaps
- No 2025–2026 source found linking GSP firmware on Ampere laptops with 6xx open modules to stutter, nor any measured RTD3 wake-latency numbers.
- No source found on specific kernel parameters (for example i915/xe PSR, `nvidia-drm.fbdev`) helping stutter on this exact model.
