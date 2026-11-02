# EasyEffects 8.3.0 plugins for headphone bass: Bass Loudness, Equalizer, Bass Enhancer, Limiter

Method note: most findings come from reading the EasyEffects **v8.3.0** source (tag cloned from github.com/wwmm/easyeffects), the mda-lv2 source (gitlab.com/drobilla/mda-lv2), the LV2 TTL files installed on this machine (/usr/lib/lv2/calf.lv2), and the official LSP and Calf manuals. The Bass Loudness frequency-response numbers come from my own numerical simulation of the mda Loudness DSP code at 48 kHz (a Python port of `mdaLoudness::processReplacing` plus an FFT of the impulse response). They are labelled as such.

Local system facts (checked on this laptop on 2026-10-17): `easyeffects 8.3.0`, `lsp-plugins-lv2 1.2.35`, `calf 0.90.9`. **`mda.lv2` is NOT installed.** `/usr/lib/lv2` holds only `calf.lv2` and `lsp-plugins-lv2`. `mda.lv2 1.2.12` is available in the cachyos-extra-v3 repo.

## 1. What implements "Bass Loudness", its algorithm, and the meaning of loudness/output/link

### Takeaway
EasyEffects' "Bass Loudness" is **mda Loudness** (Paul Kellett's MDA plugin, ported to LV2 by David Robillard, URI `http://drobilla.net/plugins/mda/Loudness`). It is not LSP, x42 or Calf. EasyEffects shows its three normalized 0–1 controls as "dB" values (dB = 20·log10(normalized value)). As a result the default −3.1 / −6 / −9.1 dB are really 0.70 / 0.50 / 0.35, and the **actual** gain behaves very differently from what the dB labels suggest. Any value below about −6 dB on "Loudness" **cuts** bass instead of boosting it. Usable bass boost only starts at about −3.1 dB, and the effect grows very quickly toward 0 dB. Separately, the "Loudness" plugin entry is a different plugin (LSP `loud_comp_stereo`).

### Cited Findings
- `src/bass_loudness.cpp` (v8.3.0) builds the plugin with package `tags::plugin_package::Package::mda` and `lv2_plugin_uri = "http://drobilla.net/plugins/mda/Loudness"`. It binds the ports with `BIND_LV2_PORT_DB("loudness"…)`, `BIND_LV2_PORT_DB("output"…)` and `BIND_LV2_PORT_DB("link"…)`, and reports latency 0 — [EasyEffects v8.3.0 source](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_loudness.cpp)
- The separate "Loudness" plugin in EasyEffects uses `http://lsp-plug.in/plugins/lv2/loud_comp_stereo` (LSP Loudness Compensator) — [EasyEffects v8.3.0 src/loudness.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/loudness.cpp)
- `BIND_LV2_PORT_DB` converts the stored setting with `util::db_to_linear(db_v)` before writing it to the LV2 port — [EasyEffects v8.3.0 src/lv2_macros.hpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/lv2_macros.hpp)
- kcfg `easyeffects_db_bass_loudness.kcfg` defines:
  - `loudness`: min −100, max 0, default −3.1
  - `output`: min −100, max 0, default −6
  - `link`: min −100, max 0, default −9.1
  - `inputGain` / `outputGain`: −36…+36, default 0
  - [EasyEffects v8.3.0 kcfg](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/contents/kcfg/easyeffects_db_bass_loudness.kcfg)
- The QML UI (`BassLoudness.qml`) shows all three controls with `unit: Units.dB` and 1 decimal — [EasyEffects v8.3.0 BassLoudness.qml](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/contents/ui/BassLoudness.qml)
- mda Loudness LV2 ports:
  - `loudness`: 0–1, default 0.7. Comment: "Source level relative to listening level (based on a 100 dB SPL maximum level)".
  - `output`: 0–1, default 0.5.
  - `link`: 0–1, default 0.35.
  - [mda-lv2 Loudness.ttl](https://gitlab.com/drobilla/mda-lv2/-/blob/master/mda.lv2/Loudness.ttl)
- Algorithm, from `mdaLoudness.cpp`. The default program is named "Equal Loudness Contours", with the source comment "re. Stevens-Davis @ 100dB".
  - The plugin computes `igain = ±60·(2p−1)²` dB from Loudness and `ogain = ±60·(2p−1)²` dB from Output.
  - It interpolates a 14-row table of coefficients (A0 = corner frequency in Hz, A1 = amount, A2 = shape), one row per 10 dB from −60 dB to +60 dB.
  - `igain > 0` selects "boost" mode, with two cascaded one-pole low-pass filters added back to the dry signal. `igain ≤ 0` selects "cut" mode.
  - Link is a switch, ON when p > 0.5: `if(param[2]>0.5f) { tmp -= igain; if(tmp>0) tmp=0; }`. Output gain is then reduced by igain and capped at 0 dB.
  - The display shows igain/ogain in "dB", and Link shows "ON"/"OFF".
  - [mda-lv2 src/mdaLoudness.cpp](https://gitlab.com/drobilla/mda-lv2/-/blob/master/src/mdaLoudness.cpp)
- Plugin description: "equal loudness contouring for bass EQ and mix correction", based on Stevens-Davis contours. Lowering Loudness simulates how a mix sounds at a louder level — [MOD forum: MDA Loudness](https://forum.mod.audio/t/mda-loudness-mod-devices/2542); [mda Loudness.ttl (drobilla git)](https://git.drobilla.net/cgit.cgi/mda.lv2.git/plain/mda.lv2/Loudness.ttl?h=v1.0.0)
- EasyEffects behaviour when the LV2 plugin is missing: `packageInstalled = lv2_wrapper->found_plugin`. `setup()` returns early when the plugin is not found, so `ready` stays false and `process()` copies input to output (only output gain is applied). In other words, it is a **silent pass-through** — [EasyEffects v8.3.0 src/bass_loudness.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_loudness.cpp)

#### Mapping table: EasyEffects value → mda internal value (computed from the source formulas)
| EE "dB" shown | normalized p | mda igain / ogain (dB) |
|---|---|---|
| 0.0 | 1.000 | +60.0 |
| −1.0 | 0.891 | +36.7 |
| −1.5 | 0.841 | +28.0 |
| −2.0 | 0.794 | +20.8 |
| −2.5 | 0.750 | +15.0 |
| −3.1 (default) | 0.700 | +9.6 |
| −4.0 | 0.631 | +4.1 |
| −6.0 (Output default) | 0.501 | 0.0 |
| −9.1 (Link default) | 0.351 | −5.3 (Link: OFF, because p < 0.5) |
| −10 | 0.316 | −8.1 (cut mode) |
| −12 | 0.251 | −14.9 |

Link is ON for any EE value above about −6.02 dB (p > 0.5) and OFF below it. The −9.1 dB default means Link is **OFF**.

#### Simulated magnitude response of the Loudness control (my simulation of the mda code at 48 kHz, Output = −6 EE (0 dB), Link OFF)
| EE Loudness | 20 Hz | 40 Hz | 60 Hz | 100 Hz | 200 Hz | 500 Hz | 1 kHz |
|---|---|---|---|---|---|---|---|
| −10 | −7.2 | −6.2 | −5.0 | −2.9 | −0.8 | −0.2 | −0.2 |
| −9.1 | −9.9 | −7.3 | −5.0 | −2.3 | −0.6 | −0.2 | −0.1 |
| −6 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| −4 | −5.4 | −3.0 | −1.4 | −0.5 | −0.1 | 0 | 0 |
| −3.5 | −1.0 | **−10.3** (dip at 30–40 Hz) | −4.3 | −1.5 | −0.4 | −0.1 | 0 |
| −3.1 (default) | +3.5 | +3.5 | +2.7 | +1.5 | +0.4 | 0 | −0.1 |
| −3.0 | +4.1 | +4.9 | +4.2 | +2.6 | +0.9 | +0.1 | −0.1 |
| −2.8 | +4.7 | +5.4 | +4.9 | +3.5 | +1.4 | +0.2 | −0.1 |
| −2.5 | +7.3 | +6.8 | +6.0 | +4.5 | +2.0 | +0.3 | −0.1 |
| −2.0 | +13.1 | +12.1 | +10.7 | +7.6 | +2.7 | +0.1 | −0.2 |
| −1.5 | +19.0 | +17.4 | +15.3 | +11.2 | +5.0 | +0.8 | 0 |
| −1.0 | +27.2 | +24.3 | +21.2 | +15.9 | +8.5 | +2.2 | +0.4 |

### Inferences
- The "dB" units in the EasyEffects UI are misleading. The control is a normalized knob drawn on a log scale. Real bass boost is roughly +3.5 dB at the −3.1 default, about +7 dB at −2.5, and about +12 dB at −2.0 (sub-bass, 20–60 Hz). Above about −2 dB it becomes extreme and will clip.
- **The user's current preset ("RedRog JBL Quantum 350 Bass Loudness.json") uses `"loudness": -10.0`.** That sets cut mode (igain −8.1), which **removes** about 5–7 dB below 60 Hz. It also does nothing anyway, because mda.lv2 is not installed, so the plugin is passed through. `"link": -9.1` means Link is OFF, and `"output": -6.0` means 0 dB.
- Between about −6 and −3.2 EE dB, the interpolated table produces odd notches (for example −10 dB at 30–40 Hz at −3.5). Avoid that range. The table's "+0 dB row" (A0 = 1 Hz, A1 = 0) interpolates badly.
- Recommended values for strong but clean headphone bass:
  - Install `mda.lv2` first.
  - Loudness −3.1 to −2.5 EE dB gives about +3.5 to +7 dB centered at 20–60 Hz, with a gentle slope that reaches about 0 dB by 300–500 Hz.
  - Set Output to −6.0 (0 dB), or lower it to make headroom. For example, Output EE −7.0 (p 0.447) gives about −0.7 dB, and −8 gives −2.5 dB. Using EasyEffects' own `output-gain`/`input-gain` (true dB) for headroom is simpler.
  - Leave Link OFF (−9.1). With Link ON, the output is reduced by the nominal igain (for example −9.6 dB at the default), which is far more than the real boost (+3.5 dB). The result would sound much quieter.
- Because the curve's shape changes with the knob (it is level-dependent "equal loudness"), the Equalizer's Lo-shelf gives more predictable control than Bass Loudness. Bass Loudness is a quick, broad "loudness contour" style lift.

### Gaps
- No official EasyEffects documentation explains the dB mapping. The conclusions above come from reading the source.
- I did not measure the plugin with real audio. The response table is a simulation of the published DSP code, not a measurement.

## 2. Preset JSON keys (v8.3.0) for bass_loudness#0, equalizer#0, bass_enhancer#0, limiter#0

### Takeaway
Preset values are written and read by `src/*_preset.cpp`. Missing keys fall back to kcfg defaults. KConfig setters clamp out-of-range values to the kcfg min and max. Enum values are stored as label strings.

### Cited Findings

#### bass_loudness#0
- Keys: `bypass`, `input-gain`, `output-gain`, `loudness`, `output`, `link` — [bass_loudness_preset.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_loudness_preset.cpp)

#### equalizer#0
- Top-level keys: `bypass`, `input-gain`, `output-gain`, `mode`, `num-bands` (1–32, default 32), `split-channels`, `balance`, `pitch-left`, `pitch-right`, `decramp`, `left`, `right` — [equalizer_preset.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/equalizer_preset.cpp); [easyeffects_db_equalizer.kcfg](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/contents/kcfg/easyeffects_db_equalizer.kcfg)
- `mode` labels: `IIR, FIR, FFT, SPM`. `decramp` labels: `Off, x2, x3, x4, x6, x8` — same kcfg
- Per-band keys (`left.bandN` / `right.bandN`): `type`, `mode`, `slope`, `solo`, `mute`, `frequency` (10–24000 Hz), `q` (0–100), `width` (0–12, default 4), `gain`.
  - Band `type` labels: `Off, Bell, Hi-pass, Hi-shelf, Lo-pass, Lo-shelf, Notch, Resonance, Allpass, Bandpass, Ladder-pass, Ladder-rej`.
  - Band `mode` labels: `RLC (BT), RLC (MT), BWC (BT), BWC (MT), LRX (BT), LRX (MT), APO (DR)`.
  - `slope` labels: `x1, x2, x3, x4`.
  - [easyeffects_db_equalizer_channel.kcfg](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/contents/kcfg/easyeffects_db_equalizer_channel.kcfg)
- The equalizer is LSP `para_equalizer_x32_lr` (with a mid/side variant `para_equalizer_x32_ms`). Band gain goes through a dB→linear binding (`BIND_BANDS_PROPERTY_DB`) — [equalizer.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/equalizer.cpp)

#### bass_enhancer#0 (Calf BassEnhancer)
- Keys: `bypass`, `input-gain`, `output-gain`, `amount`, `harmonics`, `scope`, `floor`, `blend`, `floor-active`, `listen` — [bass_enhancer_preset.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_enhancer_preset.cpp)
- kcfg ranges and defaults:
  - `amount`: −100…+36 dB, default 0 dB. It is bound with `BIND_LV2_PORT_DB`, so 0 dB = Calf amount 1.0 (Calf's native range is 0–64, linear).
  - `harmonics`: 0.1–10, default 8.5. Maps to the Calf port `drive`.
  - `scope`: 10–250 Hz, default 100. Maps to the Calf port `freq`.
  - `floor`: 10–120 Hz, default 20.
  - `blend`: −10…+10, default 0.
  - `floorActive`: default false.
  - [easyeffects_db_bass_enhancer.kcfg](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/contents/kcfg/easyeffects_db_bass_enhancer.kcfg); [bass_enhancer.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_enhancer.cpp); local `/usr/lib/lv2/calf.lv2/BassEnhancer.ttl` (amount 0–64 default 1; drive 0.1–10 default 8.5; freq 10–250 default 100; floor 10–120 default 20; blend −10…10)

#### limiter#0 (LSP `sc_limiter_stereo`)
- Keys: `bypass`, `input-gain`, `output-gain`, `mode`, `oversampling`, `dithering`, `sidechain-type`, `lookahead`, `attack`, `release`, `threshold`, `gain-boost`, `sidechain-preamp`, `stereo-link`, `alr`, `alr-attack`, `alr-release`, `alr-knee`, `alr-knee-smooth`, plus routing keys (`input-to-sidechain`, `input-to-link`, `sidechain-to-input`, `sidechain-to-link`, `link-to-sidechain`, `link-to-input`) — [limiter_preset.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/limiter_preset.cpp)
- kcfg labels and ranges:
  - `mode`: `Herm Thin, Herm Wide, Herm Tail, Herm Duck, Exp Thin, Exp Wide, Exp Tail, Exp Duck, Line Thin, Line Wide, Line Tail, Line Duck` (default Herm Thin).
  - `oversampling`: `None, Half x2/16 bit … Full x8/24 bit, True Peak/16 bit, True Peak/24 bit` (default None).
  - `dithering`: `None, 7bit … 24bit`.
  - `sidechainType`: `Internal, External, Link`.
  - `lookahead`: 0.1–20 ms, default 5.
  - `attack`: 0.25–20 ms, default 5.
  - **`release`: 0.25–20 ms, default 5.**
  - `threshold`: −48…0 dB, default 0.
  - `gainBoost`: default **true**.
  - `stereoLink`: 0–100, default 100.
  - `alr`: default false. `alrAttack`: 0.1–200 ms, default 5. `alrRelease`: 10–1000 ms, default 50. `alrKnee`: −12…+12 dB, default 0. `alrKneeSmooth`: −48…0, default −5.
  - [easyeffects_db_limiter.kcfg](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/contents/kcfg/easyeffects_db_limiter.kcfg)
- Preset loading uses `settings->setX(json.value(key, default))` (macro `UPDATE_PROPERTY`). The setters come from KConfig XT generated code, which clamps to the kcfg min and max — [presets_macros.hpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/presets_macros.hpp)
- LSP: "Release can't exceed twice the Lookahead time" (larger values are truncated), and in some modes Attack can't exceed Lookahead — [LSP Limiter manual](https://lsp-plug.in/?page=manuals&section=sc_limiter_stereo)

### Inferences
- The user's preset has `"release": 50.0`. That is above the kcfg max of 20, so it gets clamped to 20, and LSP then truncates it to 2 × lookahead = 10 ms at lookahead 5. It also lacks `alr-knee-smooth`, `sidechain-type`, `decramp` and `floor-active`, so those use defaults. That is harmless.
- Note the 8.x key names (`gain-boost`, `alr-knee-smooth`). Older 6.x/7.x community presets may use different or missing keys, which load as defaults.

### Gaps
- I did not open the generated KConfig code to confirm the clamping. It is standard kconfig_compiler behaviour when min/max are declared (it clamps with a debug message), but it was not verified in a build.

## 3. Which EQ filter mode and processing mode to use for low shelves; IIR vs FIR; slope

### Takeaway
For a bass shelf or bell below about 200 Hz, **IIR + RLC (BT), slope x1, Lo-shelf Q around 0.5–0.7** is the right default. It adds no latency, sounds smooth, and the bilinear-transform warping only matters near Nyquist, not in the bass. FIR/FFT (linear phase) add latency and pre-ringing with no audible benefit for headphone listening. Higher slopes (x2–x4) make the shelf transition steeper and should only be used to focus a sub-bass shelf.

### Cited Findings
- Processing modes:
  - IIR is minimum phase and "in most cases does not add noticeable latency".
  - FIR is a linear-phase approximation that adds noticeable latency.
  - FFT is linear phase via FFT and adds noticeable latency.
  - SPM (spectral processor) changes the magnitude spectrum directly.
  - [LSP Parametric Equalizer manual](https://lsp-plug.in/?page=manuals&section=para_equalizer_x32_lr)
- Filter classes:
  - RLC = "very smooth filters based on cascades of RLC contours".
  - BWC = Butterworth-Chebyshev type 1.
  - LRX = Linkwitz-Riley.
  - APO = biquads as in EqualizerAPO.
  - Neither BWC nor LRX applies to Resonance or Notch.
  - [LSP Parametric Equalizer manual](https://lsp-plug.in/?page=manuals&section=para_equalizer_x32_lr)
- Pole/zero mapping:
  - BT (bilinear transform) warps the curve at high frequencies ("cramping" near Nyquist).
  - MT (matched Z-transform) matches the analog response but can alias near Nyquist, "usually not audible".
  - DR = direct digital design.
  - [LSP manual](https://lsp-plug.in/?page=manuals&section=para_equalizer_x32_lr)
- Slope: for low-pass filters, RLC and BWC give −12/−24/−36/−48 dB/oct for 2/4/6/8 poles. LRX doubles that (−24…−96). APO stays at 2 poles (−12 dB/oct) at every level — [LSP manual](https://lsp-plug.in/?page=manuals&section=para_equalizer_x32_lr)
- LSP's own defaults:
  - Double-clicking at 20–50 Hz creates a **Lo-shelf RLC (BT) with Q = 0.5**.
  - Shelves default to Q = 0.5, and bells between 50 Hz and 5 kHz to Q = 2.
  - Low Q suits wide boosts or cuts.
  - Too much Q adds non-linearity in the passband.
  - [LSP manual](https://lsp-plug.in/?page=manuals&section=para_equalizer_x32_lr)
- A community "Bass Boosted" preset uses IIR, RLC (BT), slope x1 and Bell bands at Q ≈ 1.5 (32 Hz +4, 64 Hz +2, 125 Hz +1 dB), with equalizer input gain −2 dB — [JackHack96 EasyEffects-Presets: Bass Boosted.json](https://github.com/JackHack96/EasyEffects-Presets/blob/master/Bass%20Boosted.json)

### Inferences
- BT vs MT makes essentially no difference at 20–200 Hz at 44.1 or 48 kHz. Either works, and RLC (BT) is the LSP and EasyEffects default.
- **APO (DR)** is the right choice when copying AutoEQ or EqualizerAPO / oratory1990 parametric presets ("LSC/PK" filters), because it reproduces the same biquad shapes. RBJ-style shelf Q semantics match APO more closely than RLC.
- BWC and LRX shelves are steeper or more "crossover-like". They are not needed for musical bass lift.
- For a sub-bass-focused shelf (boost below about 60–80 Hz without muddying 150–300 Hz), use a Lo-shelf around 80–105 Hz at Q 0.6–0.7 plus a small −1 to −2 dB bell around 200–300 Hz. Alternatively, use slope x2 on the shelf. The user's existing structure (45 Hz bell +2.5, 90 Hz shelf +6, 250 Hz −1.5) already follows this pattern.
- Linear-phase (FIR/FFT) bass boosts cause pre-ringing and a latency of tens of ms, which matters for video and games. There is no benefit for this use case.

### Gaps
- LSP does not document exactly how shelf "Q" maps to transition steepness for the RLC class versus APO. I could not find a numeric equivalence.

## 4. Bass Enhancer (Calf, harmonics) vs EQ shelf for headphones that already have bass

### Takeaway
Calf Bass Enhancer adds **synthetic harmonics** of the low band (psychoacoustic "missing fundamental") instead of raising low-frequency energy. That helps small drivers that cannot reproduce sub-bass. On closed headphones that already extend low (like the JBL Quantum series), an EQ shelf gives real sub-bass without distortion. The enhancer adds audible "grit" or saturation, and only small amounts are advisable.

### Cited Findings
- Calf Bass Enhancer "creates harmonic distortions of the input, limits them to a set range, and blends them with the original signal". It raises perceived low end without boosting low frequencies directly, "fuller rather than boomy". Controls:
  - Amount = how much harmonic content is mixed in.
  - Harmonics = how much new harmonic content is generated.
  - Blend = colour or octave of the harmonics.
  - Scope = frequency above which harmonics are produced.
  - Floor = frequency below which no harmonics are produced.
  - Listen = solo the harmonics.
  - [Calf Bass Enhancer docs](https://calf-studio-gear.org/doc/Bass%20Enhancer.html)
- The EasyEffects mapping is `amount` in dB (0 dB = Calf 1.0), `harmonics`→`drive`, `scope`→`freq` — [EasyEffects v8.3.0 bass_enhancer.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_enhancer.cpp)
- The JackHack96 "Bass Boosted" preset uses Bass Enhancer amount 5.0, harmonics 8.5, scope 80, floor 20 (inactive), placed after the EQ and before the maximizer — [JackHack96 Bass Boosted.json](https://github.com/JackHack96/EasyEffects-Presets/blob/master/Bass%20Boosted.json)

### Inferences
- Pros of the enhancer: it adds punch and audibility of bass at low volume, and on bass-light transducers, without large LF gain. That means less headroom loss and less driver excursion.
- Cons of the enhancer: it is distortion by design. It can sound fuzzy or "buzzy" on clean recordings and stacks with existing bass, and it is not a substitute for flat sub-bass extension.
- For headphones that already have bass, a conservative starting point:
  - Amount 0 to +3 dB.
  - Harmonics 4–8.5.
  - Scope 60–80 Hz, so only the lowest band is enhanced.
  - Floor active at about 20–30 Hz, to avoid generating harmonics from rumble.
  - Blend 0.
  - Check the result with "Listen".
- Alternatively, skip the enhancer and use the EQ shelf plus optionally Bass Loudness.
- In the JackHack96 preset, amount 5.0 was likely written for older versions, where the scale may differ. In 8.x, 5 dB equals Calf amount about 1.78. Treat this as an assumption.

### Gaps
- I found no measured or controlled comparison of the Calf enhancer vs a shelf on headphones. The pros and cons above are reasoned from the plugin's documented mechanism.

## 5. Plugin order and headroom handling (input gain, limiter threshold, inter-sample peaks)

### Takeaway
Order: **EQ (with negative input gain for headroom) → Bass Loudness / Bass Enhancer → Limiter last**. Set the pre-gain to about −(maximum boost) dB. Set the limiter threshold to −1 dB with lookahead around 5 ms. Turn gain-boost OFF so the limiter does not add make-up gain. Use "True Peak/24 bit" oversampling if inter-sample overs matter.

### Cited Findings
- Hydrogenaudio advice: put the limiter at the end of the DSP chain, because processing can raise peaks unpredictably. Even negative EQ settings can create higher peaks than the original — [Hydrogenaudio thread](https://hydrogenaudio.org/index.php?msg=662756)
- Forum opinion: minimum-phase (and sometimes linear-phase) EQ can raise peak level, and clippers or limiters go last — [KVR forum: Order of FX - Clipping and EQ](https://www.kvraudio.com/forum/viewtopic.php?p=8224203)
- LSP limiter:
  - Threshold is the maximum level allowed.
  - "Boost" applies gain equal to the threshold to the output. EasyEffects' `gain-boost` defaults to true.
  - Lookahead adds equal latency.
  - Release ≤ 2× lookahead.
  - Modes: Herm/Exp/Line = interpolation of the gain-reduction curve (cubic Hermite, exponential, linear). Thin/Wide/Tail/Duck = shape of the reduction "patch" around the peak.
  - ALR = a first-stage "compressor with infinite ratio" (Automatic Level Regulation) with attack, release, knee and smooth controls.
  - "True Peak" oversampling uses Lanczos oversampling of the sidechain "intended to eliminate true peaks". Half = oversamples the sidechain only, Full = oversamples the signal as well.
  - [LSP Limiter manual](https://lsp-plug.in/?page=manuals&section=sc_limiter_stereo)
- EasyEffects lets the user fully control effect order — [EasyEffects repo README](https://github.com/wwmm/easyeffects)
- The community preset uses equalizer input gain −2 dB and ends with a maximizer at threshold −3 dB — [JackHack96 Bass Boosted.json](https://github.com/JackHack96/EasyEffects-Presets/blob/master/Bass%20Boosted.json)

### Inferences
- PipeWire and EasyEffects process in 32-bit float, so intermediate stages above 0 dBFS do not hard-clip by themselves. Clipping happens at the device format conversion, or inside nonlinear plugins like the Calf enhancer and the limiter itself. I have no specific source for this; it is general knowledge of float DSP. Pre-gain still matters because the limiter will otherwise squash bass transients constantly, causing pumping and distortion.
- Headroom rule of thumb: set EQ `input-gain` to minus the largest summed low-frequency boost. For example, a +6 dB shelf plus a +2.5 dB bell at 45 Hz can stack to about +8 dB at 40–60 Hz, so use −7 to −8 dB. If Bass Loudness adds a further +3.5 to +7 dB, increase the pre-gain cut by that amount, or use a smaller shelf. The user's −7 dB pre-gain is appropriate for the EQ alone.
- Limiter settings for a bass preset:
  - Mode Herm Thin (default) or Herm Wide (gentler on bass).
  - Lookahead 5 ms, attack 5 ms, release 10 ms (2 × lookahead; the 20 ms kcfg max needs lookahead ≥ 10).
  - Threshold −1 dB, `gain-boost` false.
  - Oversampling "True Peak/24 bit" or "Full x2/24 bit" for inter-sample peaks (costs CPU).
  - ALR off, or on with a long release (≥ 50 ms) to reduce bass-induced gain pumping.
  - Stereo link 100.
- When the limiter is constantly reducing gain more than 1–2 dB, lower the pre-gain instead of relying on the limiter.

### Gaps
- No EasyEffects-official guidance on plugin order or headroom was found. The recommendations rest on general DSP forum consensus and LSP documentation.
- The exact sound difference between the Thin/Wide/Tail/Duck shapes is not described in detail by LSP.
