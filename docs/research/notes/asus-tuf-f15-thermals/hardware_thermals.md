# ASUS TUF Gaming F15 FX507ZC4 (i5-12500H + RTX 3050 Laptop): hardware, thermal design and power limits

Labeling convention: **[ZC]** = data measured on an FX507ZC / FX507ZC4 unit (RTX 3050). **[ZM]** = sibling FX507ZM (i7-12700H + RTX 3060 140 W), the only FX507Z with full English lab reviews (Notebookcheck, Ultrabookreview). **[2023 FX507V]** = 13th-gen/RTX 40 refresh. These are different SKUs: same chassis family, but the GPU power and the GPU-side cooling differ.

Method note: Notebookcheck, LaptopMedia and Ultrabookreview were read in full (via curl or the Wayback Machine, because WebFetch got 403s / Cloudflare blocks). I found no dedicated English lab review of the exact i5-12500H + RTX 3050 FX507ZC4. The closest is LaptopMedia's FX507 review: its spec page lists an i5-12500H + RTX 3050 95 W config, but its CPU temperature table is labelled i7-12700H.

---

## 1. RTX 3050 Laptop TGP in FX507ZC4 and GPU thermal target

### Takeaway
The FX507ZC/ZC4 RTX 3050 is ASUS's highest-power 3050 config: **80 W TGP + 15 W Dynamic Boost = 95 W max**, at 1740 MHz boost + 50 MHz OC (1790 MHz). In LaptopMedia's test a healthy FX507 RTX 3050 held **~95 W, ~1935-1954 MHz, 77-81 °C** in a 30-minute gaming load. A unit sitting at **36-40 W and 88 °C** in a game is running at less than half its rated power and above the temperature a new unit reaches at full power. NVIDIA laptop GPUs commonly have an ~87 °C target, so 88 °C fits thermal/power throttling.

### Cited Findings
- ASUS's official 2022 TGP table lists the FX507ZC/FX707ZC RTX 3050 at base clock 1740 MHz, OC 1790 MHz, **TGP 80 W, Dynamic Boost 15 W** (95 W max). The FX507ZE (RTX 3050 Ti) gets 1695/1745 MHz at the same 80 W + 15 W. The FX507ZM (RTX 3060) and FX507ZR (RTX 3070) get 115 W + 25 W (140 W). For comparison, the TUF Dash F15 FX517ZC RTX 3050 is only 60 W + 15 W = 75 W. — [ASUS ROG: Complete list of GeForce GPU TGP for 2022 ROG/TUF laptops](https://rog.asus.com/articles/rog-gaming-laptops/the-complete-list-of-geforce-gpu-tgp-for-2022-rog-tuf-laptops/)
- An FX507ZC4 retailer listing (copying ASUS's spec) says "1740MHz Boost Clock+50MHz OC, 80W+15W Dynamic Boost", max 95 W. — [Hacom FX507ZC4-HN099W](https://hacom.vn/laptop-asus-gaming-tuf-fx507zc4-hn099w); also the [ASUS TUF Gaming F15 (2022) techspec](https://www.asus.com/eg/laptops/for-gaming/tuf-gaming/asus-tuf-gaming-f15-2022/techspec/)
- LaptopMedia lists the FX507 GPU options as "RTX 3050 (95W), RTX 3060 (140W), and RTX 3070 (140W)", all with a MUX switch. The spec block includes an **Intel Core i5-12500H + RTX 3050 (Laptop, 95W)** config. — [LaptopMedia FX507 review p1](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-review-there-are-too-many-versions/)
- **[ZC] LaptopMedia RTX 3050 gaming stress:** "1954 MHz @ 77°C @ 95W" after 2 min and "1935 MHz @ 81°C @ 95W" after 30 min. For comparison, the Acer Nitro 5 AN515-58 ran 2009 MHz @ 73 °C @ 94 W. The reviewer: "the cooling solution can't really handle the RTX 3050 and runs it at high temperatures. While it still gives you high clocks, the fan noise is a bit loud." — [LaptopMedia FX507 review p7](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-review-there-are-too-many-versions/p7/)
- **[ZC]** Notebookcheck's summary of the LaptopMedia review says long gaming sessions bring "high noise and not a super comfortable temperature for the GPU" (it also notes that the external temperatures are good). — [Notebookcheck FX507ZC page](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZC.623509.0.html)
- **GPU temperature target:** an NVIDIA forum user reports that on a laptop the driver's GPU Target Temperature reads 87 °C on Windows (80 °C on Linux after reboot on that machine), with the slowdown threshold at 95 °C. Another user reports that, depending on the laptop's power mode when the nvidia module loads, the limit is 78, 79 or 87 °C. — [NVIDIA forums: Target Temperature 87 C -> 80 C](https://forums.developer.nvidia.com/t/diff-windows-linux-target-temperature-87-c-80-c-after-reboot/333497); [NVIDIA forums: nvidia-smi -gtt on laptops](https://forums.developer.nvidia.com/t/nvidia-smi-gtt-option-since-460-27-causes-major-performance-issues-on-laptops/176579)
- **[ZM]** On the quieter Performance mode, Ultrabookreview saw "GPU temperatures in the 85-87 C and GPU power throttling in most titles" with the laptop flat on a desk. Raising the rear removed the throttling: the GPU "continuously runs at 115W". — [Ultrabookreview FX507ZM review (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **Linux Dynamic Boost:** Dynamic Boost on Linux requires the `nvidia-powerd` daemon (systemd + D-Bus + cpufreq) and SBIOS support. You can check support with `nvidia-settings -q DynamicBoostSupport` or `/proc/driver/nvidia/gpus/<bus>/power`. Firmware can disable the controller. — [NVIDIA Linux driver README, ch. 23 Dynamic Boost](https://download.nvidia.com/XFree86/Linux-x86_64/595.80/README/dynamicboost.html)
- On other laptops, a GPU stuck at a low TGP on Linux was fixed by enabling `nvidia-powerd` and switching the platform profile to performance. — [EndeavourOS forum: Lenovo LOQ stuck at 35W or 55W](https://forum.endeavouros.com/t/lenovo-loq-15arp9-stuck-at-35w-or-55w-tpg/78348)

### Inferences
- Without `nvidia-powerd` the GPU should still reach the **80 W base TGP**, not 95 W. So missing Dynamic Boost explains at most a 15 W shortfall. 36-40 W is far below even the base.
- 88 °C at only 36-40 W means the GPU is sitting at its thermal target and the driver is cutting power to hold it. On a healthy unit, 95 W gives ~77-81 °C. That points to much worse heat transfer (dust-clogged fins/intakes, dried or pumped-out paste, poor pad contact) or to heat from a very hot CPU loading the shared heatpipes (see section 5). Two other things can lower the GPU limit and should be ruled out first: a quiet/Silent-like platform profile, or a cap set by firmware or the driver.
- A game that only needs ~40 W at a frame cap could also draw little power. But it would then not run at 88 °C on a healthy cooler. The high temperature at low power is the abnormal combination.

### Gaps
- I found no lab measurement of the exact FX507ZC4 under Linux, and no published GPU power per Armoury Crate mode specifically for the RTX 3050 SKU (only the [ZM] table, below).
- I found no NVIDIA-published thermal target specifically for the RTX 3050 Laptop GPU. The 87 °C figure comes from forum-reported `nvidia-smi` readings on other Ampere/laptop GPUs. Check on the unit with `nvidia-smi -q -d TEMPERATURE,POWER`.

---

## 2. CPU PL1/PL2 per Armoury Crate mode, fan behaviour per mode

### Takeaway
For the FX507Z with an i7-12700H, Notebookcheck published ASUS's targets:
- **Silent:** PL1 45 W / PL2 60 W
- **Performance:** PL1 70 W / PL2 105 W
- **Turbo:** PL1 90 W / PL2 115 W
- **Manual:** PL1 100 W / PL2 135 W

Noise targets are <35 / 40 / 48 / 52 dB(A). The i5-12500H's own Intel spec is 45 W base / 95 W max turbo, TjMax 100 °C. I found no i5-specific per-mode table.

### Cited Findings
- **[ZM] Notebookcheck table (manufacturer targets):**

  | Mode | CPU PL1 | CPU PL2 | GPU TGP | Max TDP+TGP | Noise target |
  |---|---|---|---|---|---|
  | Silent | 45 W | 60 W | <115 W (WhisperMode 2.0 on) | 25 W + <100 W (WhisperMode on) | <35 dB(A) |
  | Performance | 70 W | 105 W | 100 W + 15 W | 35 W + 100 W | 40 dB(A) |
  | Turbo | 90 W | 115 W | 115 W + 25 W | 45 W + 115 W | 48 dB(A) |
  | Manual | 100 W | 135 W | 115 W + 25 W | 45 W + 115 W | 52 dB(A) |

  — [Notebookcheck FX507ZM review](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html). The spec block lists the i7-12700H at "115 W PL2 / Short Burst, 90 W PL1 / Sustained".
- **[ZM] Ultrabookreview measured sustained CPU power:**
  - Silent: 45 W, CPU temperatures in the mid-70s °C
  - Performance: ~70 W, CPU still in the mid-90s °C
  - Turbo: ~90 W, ~95 °C, ~3.3 GHz P-cores, fans ~48 dB
  - Manual: ~90 W

  Combined CPU+GPU budgets: Silent ~100-120 W, Performance 135 W, Turbo 155 W, Manual 160 W. Fans reach 0-35 / 42 / 50 / 52 dB(A). (UBR's text swaps the PL1/PL2 labels: it calls 115 W "PL1" and 90 W "PL2"; Notebookcheck's labelling is the standard one.) — [Ultrabookreview FX507ZM (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **[ZM]** Turbo is available only on AC. On Silent the fans stop entirely while CPU/GPU stay under 60 °C ("0dB Technology"). On Turbo the fans already run at ~95 % rpm, so Manual at 100 % fans (52 dB) "barely changed anything". — [Ultrabookreview (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **[ZM]** Five fan modes exist in Armoury Crate: Windows, Silent, Performance, Turbo, Manual. Witcher 3 noise is 45.8 dB(A) on Performance vs 54.1 dB(A) on Turbo, with a maximum load of 57.2 dB(A). Performance mode costs 5-10 % GPU performance vs Turbo. — [Notebookcheck FX507ZM](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html)
- **[ZC] LaptopMedia (CPU column labelled i7-12700H):** CPU load at 0-10 s was 3.28 GHz P / 2.64 GHz E @ 69 °C @ 99 W; at 15-30 s, 3.48 / 2.67 GHz @ 82 °C @ 98 W; at 10-15 min, **2.28 / 1.82 GHz @ 61 °C @ 45 W**. The reviewer says the CPU "wanted to fall down to 2.30 GHz on the P-cores after no more than 1 minute" regardless of Armoury Crate mode, and suspects a driver/firmware issue: "hope that your CPU won't default at 45W after 30 seconds of stress." — [LaptopMedia p7](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-review-there-are-too-many-versions/p7/)
- **i5-12500H Intel spec:** 45 W base power, 95 W maximum turbo power, 35 W minimum assured, max temperature (TjMax) 100 °C. — [Notebookcheck i5-12500H](https://notebookcheck.info/Intel-Alder-Lake-P-i5-12500H-Notebook-Processor.677892.0.html); [Kelaptop i5-12500H](https://kelaptop.com/fr/processeur/intel-core-i5-12500h)

### Inferences
- On the i5-12500H, ASUS's Turbo PL2 of 115 W is above Intel's 95 W recommendation. The real ceiling is probably closer to 95 W short-term and ~70-90 W sustained, depending on firmware. This is unverified for the i5 SKU.
- The RTX 3050 SKU has less GPU-side copper than the ZM (see section 5), so the shared heat budget is likely tighter than the [ZM] figures suggest.
- On Linux, `asus-wmi`'s `throttle_thermal_policy` / platform_profile picks the equivalent of these EC modes. Their PL values are set by the EC/BIOS, not by the OS. Other research threads cover this.

### Gaps
- **Fan RPM ranges per mode:** I found no review that publishes fan RPM for the FX507Z. Only dB(A) values are available (above).
- No published per-mode PL table for the **i5-12500H** FX507ZC4.

---

## 3. Review measurements: temperatures, clocks, power, surface temperatures, noise

### Takeaway
Healthy-unit reference points:
- **Gaming:** CPU ~69-80 °C. [ZM] Turbo games draw only ~20 W of CPU power at 75-80 °C on Ultrabookreview's unit, and 69 °C on Notebookcheck's.
- **GPU:** 77-84 °C at full TGP (95 W on the 3050, 133-140 W on the 3060).
- **CPU stress:** CPU temperatures of **~95 °C appear only under all-core stress at 90-115 W**.
- **Surface:** keyboard below 40 °C, hot spot ~45-49 °C.
- **Noise:** Turbo gaming ~49-54 dB(A).

### Cited Findings
- **[ZM] Notebookcheck stress test:** Prime95 boosts to 3.8 GHz at **95 °C** for ~100 s at 115 W package power, then settles at **3.1 GHz, 83 °C, 90 W**. — [Notebookcheck FX507ZM](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html)
- **[ZM] Notebookcheck Witcher 3 (Turbo):** CPU **69 °C**, GPU **77 °C**, GPU 1927 MHz, 133.4 W board power. The previous-generation FX506 ran CPU 75 °C, GPU 81 °C at only 90.4 W. — [Notebookcheck FX507ZM](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html)
- **[ZM] Notebookcheck system power:** Prime95 spikes to 192 W, then 160 W. Prime95 + FurMark peaks at 242 W, average 198 W. Cinebench R15 loop is stable, "only drop by a few percentage points". — [Notebookcheck FX507ZM](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html)
- **[ZM] Notebookcheck surface temperatures:** in Witcher 3 the top hot spot reaches up to ~49 °C (FX506: 37 °C), but "the hot spot [moved] away from the keyboard keys". Maximum readings were 44.4 °C top / 48.8 °C bottom in one load set, at a room temperature of 20 °C. — [Notebookcheck FX507ZM](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html)
- **[ZM] Ultrabookreview gaming:** "On Turbo, with the laptop sitting on the desk… the CPU runs at ~20W in most titles, which translates to temperatures of 75-80 C". GPU 80-84 °C at up to 140 W. Raising the rear sheds 5-8 °C: CPU low-to-mid 70s, GPU mid-to-high 70s. — [Ultrabookreview (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **[ZM] Ultrabookreview surface:** on Turbo, a hot spot ~45 °C mid-chassis with keyboard temperatures in the 30s/20s °C. On Performance the contact areas "won't go over 40s C". — [Ultrabookreview (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **[ZC] LaptopMedia:** GPU 1935 MHz @ 81 °C @ 95 W after 30 minutes. "The fan noise is a bit high, but the keyboard remains pretty cool even in long gaming sessions." — [LaptopMedia p7](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-review-there-are-too-many-versions/p7/)
- **[2023 FX507V, RTX 4050, i7-13700H]:** CPU sustained at 2.29 GHz @ 57 °C @ 35 W. RTX 4050 at 2595 MHz @ 67-69 °C @ 89-90 W. Keyboard just below 40 °C, ~45 °C higher up. — [LaptopMedia FX507 2023 p7](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-2023-review-higher-price-but-better-performance/p7/)

### Inferences
- **Against the user's symptoms:**
  - **CPU at 94-98 °C at ~55 % load while gaming:** reference units sit at 69-80 °C in games. They reach ~95 °C only at full all-core Prime95 / Cinebench load and 90-115 W. Unless the CPU is actually drawing 70+ W in that game (check package power, e.g. RAPL/turbostat), 94-98 °C at moderate load is consistent with degraded heat transfer.
  - **GPU at 88 °C and 36-40 W:** the reference RTX 3050 runs 81 °C at 95 W. Hotter at less than half the power strongly suggests a degraded or obstructed cooler, or a GPU throttled by CPU heat in the shared pipes.
- A ~95 °C CPU peak under short all-core bursts is "by design" on this chassis (Ultrabookreview even saw mid-90s on Performance mode in Cinebench). A 95 °C reading alone is not proof of a fault; the power level at which it happens is what matters.

### Gaps
- No Jarrod'sTech or Hardware Unboxed numbers retrieved for the FX507ZC specifically (YouTube only, not searchable as text here).
- No measured noise or surface temperatures for the RTX 3050 SKU specifically.

---

## 4. Known thermal problems: dust, paste, liquid metal, repaste results, cooling pads

### Takeaway
The FX507 (2022 and 2023) uses **regular thermal paste on both CPU and GPU, not liquid metal**, according to ASUS's own table. So a DIY repaste carries no liquid-metal handling risk. The biggest design weakness reviewers document is **intake starvation**: low rubber feet leave ~2 mm under the laptop, and raising the rear cuts temperatures by 5-10 °C. I found no FX507-specific before/after repaste numbers from a reliable source.

### Cited Findings
- ASUS's TIM table: "TUF Gaming F15 (2022) | FX507 | January 2022 | **Paste | Paste**" (CPU | GPU). TUF Gaming F15 (2023), FX507, January 2023, is also Paste | Paste. Liquid metal is listed for ROG models. — [ASUS ROG: Celebrating five years of liquid metal in ROG laptops](https://rog.asus.com/uk/articles/rog-gaming-laptops/celebrating-three-years-of-liquid-metal-in-rog-laptops/)
- **[ZM]** "They're also still using regular thermal paste for this series, and not liquid metal as on the ROG models." — [Ultrabookreview (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **[ZM] Intake choking:** the low-profile rubber feet leave "only about 2 mm of space underneath", and most of the area around the fans is obstructed by feet. "Bumping the back of the laptop off the desk by an inch or two makes a big difference, allowing these internal temperatures to drop by as much as 10 degrees on both Turbo and Performance"; "Opting for an active cooling pad will help even more." The verdict criticises "the choked fan intakes with the laptop sitting on a desk". — [Ultrabookreview (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **Repaste anecdotes (other models, low reliability):**
  - A TechPowerUp user who repasted an older TUF laptop with MX-6 reported roughly −20 °C GPU and −10-15 °C CPU. — [TechPowerUp forum post](https://techpowerup.com/forums/goto/post?id=5311396)
  - A Steam forum user with an F15 (i7-12700H / RTX 3050 Ti) reported ~93 °C in games even ~2 months after a shop repaste. — [Steam Community thread](https://steamcommunity.com/discussions/forum/11/4328601129273000045/?l=french)
  - An ASUS community moderator advised against DIY replacement of factory thermal pads on the FX506HC. — [ASUS ZenTalk](https://zentalk.asus.com/t5/others/is-the-stock-thermal-paste-for-asus-tuf-f15-fx506hc-the-ptm7958/m-p/458792)
- **Disassembly:** 12 Phillips screws, the bottom-right one captive. 56 Wh battery in LaptopMedia's 3050 unit (90 Wh on other configs). Two fans and three heatsinks. — [LaptopMedia FX507 p8](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-review-there-are-too-many-versions/p8/)

### Inferences
- Since both CPU and GPU use paste, the usual age-related degradation applies: paste drying or pump-out, plus dust in the fin stacks and the already restricted intakes. Cleaning the fins and fans, replacing the paste, and checking the pad on VRAM/VRM (the 4th heatpipe) is the logical fix path. The size of the gain on FX507 is not documented; the 5-10 °C from simply raising the rear shows how much airflow alone matters on this chassis.
- A cooling pad or rear riser is unusually effective on this design because of the documented intake obstruction.

### Gaps
- No Reddit or forum FX507Z-specific before/after repaste or cleaning numbers found. Searches returned only other TUF models and anecdotes.
- No source on the specific factory paste type for the FX507.

---

## 5. Heatpipes shared between CPU and GPU

### Takeaway
Yes. The FX507 uses **three heatpipes shared between CPU and GPU**, a fourth for GPU memory/VRMs, three heatsinks and two fans (LaptopMedia, on its RTX 3050 unit). LaptopMedia also says the **RTX 3050 version lacks a dedicated heat pipe and heatsink that the RTX 3060/3070 models have**. So CPU heat directly raises GPU temperature and vice versa, and the 3050 SKU has the weakest cooler of the line.

### Cited Findings
- "There are three heat pipes shared between the CPU and the GPU. You will find a fourth one dealing with the graphics memory and the VRMs, while three heat sinks and two fans complete the cooling setup of the laptop." — [LaptopMedia FX507 p8 (Disassembly)](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-review-there-are-too-many-versions/p8/)
- "In contrast to the RTX 3060 and RTX 3070 models, this one [RTX 3050] lacks a dedicated heat pipe and a heat sink, which apparently proves crucial." Notebookcheck's summary of the same review: "Due to different cooling components, two versions of the same laptop might be a great and a not-so-great choice." — [LaptopMedia p7](https://laptopmedia.com/review/asus-tuf-gaming-f15-fx507-review-there-are-too-many-versions/p7/); [Notebookcheck FX507ZC](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZC.623509.0.html)
- **[ZM]** Compared with the FX506, the 2022 design added "an extra heat pipe and radiator on the CPU side, but almost nothing has changed on the GPU side, despite the much higher GPU power settings." — [Ultrabookreview (Wayback)](https://web.archive.org/web/2023/https://www.ultrabookreview.com/56362-asus-tuf-gaming-f15-review/)
- **[ZM]** Notebookcheck's teardown photo caption: "Asus FX506HM for comparison. Note the fewer copper heat pipes when compared to the FX507". — [Notebookcheck FX507ZM](https://www.notebookcheck.net/Asus-TUF-Gaming-F15-FX507ZM-laptop-review-Peak-GeForce-RTX-3060-performance.609347.0.html)

### Inferences
- With shared pipes, a CPU running at 94-98 °C saturates the common heatpipes and fin stack. That raises GPU temperature, and the NVIDIA driver then reduces GPU power to stay at its ~87 °C target. This mechanism plausibly explains "GPU 88 °C at only 36-40 W" alongside a hot CPU.
- Mitigations under this design:
  - lower the CPU power in games (cap PL1/PL2 or use a lower platform profile)
  - fix airflow (raise the rear, use a cooling pad, clean dust)
  - repaste

  Lowering CPU power should free thermal headroom for the GPU. This is an inference, not measured on this unit.
- LaptopMedia's two statements could be read as conflicting (3 shared + 1 VRAM/VRM pipe vs "lacks a dedicated heat pipe"). The most consistent reading is that the 3060/3070 boards carry an extra pipe/heatsink that the 3050 board omits. I found no side-by-side photo confirming the exact pipe count per SKU.

### Gaps
- Exact heatpipe count and layout for the FX507ZC4 vs the FX507ZM: no photo-verified side-by-side comparison found.
- No published data on heatpipe diameters, fin-stack size, or fan diameter or blade count.
