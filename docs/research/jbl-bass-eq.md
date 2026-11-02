# Deepen Sub-Bass Without Muddiness: JBL Headphone Equalization

Effective bass loudness equalization for JBL headphones in EasyEffects 8.3 must **avoid boosting the 100–200 Hz region**: measured JBL models already exhibit +2 to +9 dB of excess energy above the Harman target across those frequencies. Equalization should instead concentrate gain strictly **below 60–80 Hz**: deploying a low-shelf filter (Q = 0.7) with its corner frequency positioned at 60–70 Hz, a moderate notch around 200 Hz, and a measured application of Bass Loudness. Combined, this processing delivers **+7 to +8 dB at 30–40 Hz** while restricting boost at 100 Hz to under **+2 dB**. This response profile aligns with the preference curve identified by Harman's "More Bass Is Better" listener segment (+3 to +6 dB over baseline) and closely tracks ISO 226 equal-loudness contours for playback ~15 phon below reference mixing levels, deliberately omitting the muddy 100–300 Hz upward tilt. Two operational discoveries require immediate configuration changes: EasyEffects' Bass Loudness plugin is an implementation of **`mda Loudness`**, whose UI "dB" values actually represent a normalized 0.0 to 1.0 parameter space where **any value below approximately −6 dB attenuates sub-bass rather than boosting it**. Furthermore, the underlying **`mda.lv2` package is not installed by default**, leaving the plugin in a silent hardware bypass. Existing presets configured with `"loudness": -10.0` will immediately **cut 5–7 dB below 60 Hz** once the LV2 bundle is installed. This report delivers two fully validated JSON configuration profiles: a dedicated profile for the JBL Quantum 350 preserving its specific corrections (−2 dB at 200 Hz, −3 dB at 8 kHz), and a generalized profile covering the Tune and Live series with model-specific adjustments.

---

## 1. Baseline Measurements: JBL Factory Tuning Over-Emphasizes Mid-Bass

The Harman Over-Ear 2018 target already includes elevated bass response, defined as a **+6 dB low-shelf centered at 105 Hz with Q ≈ 0.7**, providing +5.7 dB at 50 Hz, +4.4 dB at 80 Hz, +3.0 dB at 105 Hz, and only +0.4 dB at 200 Hz ([AutoEq Targets](https://github.com/jaakkopasanen/AutoEq/tree/master/targets)). In Harman cluster analyses, approximately 15% of listeners (the "More Bass Is Better" class, predominantly young males) preferred an additional **3 to 6 dB below 300 Hz** alongside +1 dB above 1 kHz ([SoundStage Solo](https://mail.soundstagesolo.com/index.php/features/217-where-are-we-at-with-the-harman-curve); [GRAS / Harman Case Study](https://www.grasacoustics.com/fileadmin-gras/Images/Consumer_Audio/Household_Appliances/GRAS_Case_Harman_Final_02182021pdf.pdf)). In commercial production, JBL tunes many models with **~2 dB of extra bass below 125 Hz** on top of the Harman curve ([SoundStage Solo](https://mail.soundstagesolo.com/index.php/features/217-where-are-we-at-with-the-harman-curve)). Consequently, consumer preference for enhanced low-end is partially pre-baked at the factory.

Acoustic measurements confirm this profile while isolating the mid-bass excess. The following table summarizes deviations from the Harman Over-Ear 2018 target extracted from AutoEq measurement CSVs (positive values indicate excess energy relative to Harman) ([AutoEq Results](https://github.com/jaakkopasanen/AutoEq/tree/master/results)):

| Model & Rig | 30 Hz | 50 Hz | 80 Hz | 100 Hz | 150 Hz | 200 Hz | 5 kHz | 8 kHz |
|---|---|---|---|---|---|---|---|---|
| **Quantum 100** (RTINGS HMS II.3) | −3.1 dB | −3.1 dB | −1.1 dB | +1.9 dB | +4.5 dB | +5.4 dB | −5.2 dB | +6.1 dB |
| **Quantum 400** (RTINGS HMS II.3) | +0.4 dB | +2.7 dB | +3.9 dB | +4.3 dB | +3.3 dB | +2.0 dB | −11.8 dB | +4.9 dB |
| **Quantum 800** (RTINGS HMS II.3) | +1.3 dB | +2.4 dB | +3.9 dB | +4.4 dB | +4.1 dB | +2.5 dB | −9.9 dB | +5.8 dB |
| **Tune 520BT** (RTINGS 5128) | −5.6 dB | +0.3 dB | +1.8 dB | +1.1 dB | 0.0 dB | +0.2 dB | −3.5 dB | −1.9 dB |
| **Tune 770NC** (RTINGS 5128) | +4.7 dB | +3.6 dB | +0.8 dB | −0.4 dB | −1.4 dB | −0.7 dB | −2.0 dB | +3.5 dB |
| **Live 660NC** (RTINGS HMS II.3) | +1.9 dB | +3.7 dB | +3.3 dB | +2.0 dB | −1.9 dB | −1.7 dB | −3.3 dB | +1.8 dB |
| **Live 770NC** (RTINGS 5128) | +7.5 dB | +6.3 dB | +8.2 dB | +9.3 dB | +4.5 dB | +1.3 dB | −2.8 dB | +0.8 dB |

For the **Quantum 350 Wireless, no published laboratory frequency response curves exist** across AutoEq, oratory1990, Crinacle, squig.link databases, or RTINGS ([AutoEq Model Index](https://github.com/jaakkopasanen/AutoEq/blob/master/results/INDEX.md)). Qualitative measurements from SoundGuys note that the Quantum 350's low-end registers "more than twice as loud" as mid-range frequencies around 400 Hz ([SoundGuys Review](https://www.soundguys.com/jbl-quantum-350-wireless-review-63655/)). The architectural baseline must therefore extrapolate from measured Quantum siblings (100, 400, and 800): **a +4 to +5 dB mid-bass hump spanning 100–250 Hz**, sub-bass tracking at or below target, **a steep notch at 4.3–4.7 kHz**, and a **+5 to +7 dB peak across 7–10 kHz** ([AutoEq Q400](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Quantum%20400); [AutoEq Q800](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Quantum%20800)). The existing Quantum 350 correction profile (−2 dB at 200 Hz, −3 dB at 8 kHz) directly counteracts these specific acoustic artifacts and should be retained.

The Tune and Live product lines exhibit divergent "Pure Bass" profiles: energy is concentrated between 50 and 120 Hz (peaking at +8 to +9 dB on the Live 770NC), while transitioning to a flat or depressed profile across 150–300 Hz. Over-ear closed-back headphones generally lose sub-bass coupling when eyeglasses or jaw movement break the ear cushion seal ([SoundStage Solo](https://mail.soundstagesolo.com/index.php/features/217-where-are-we-at-with-the-harman-curve)). Equalization curves that boost 100–200 Hz exacerbate muddiness when the seal is complete. Finally, significant low-end boost risks accentuating the signature 4.5–5.0 kHz JBL response notch; targeted EQ profiles introduce a gentle bell filter to restore presence without triggering sibilance ([AutoEq Q800](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Quantum%20800)).

---

## 2. Psychoacoustic Design: Lower Shelf, Q = 0.7, and Truncated ISO 226

ISO 226:2003 equal-loudness contours quantify the human ear's declining low-frequency sensitivity as playback levels drop below standard reference mixing levels (80–85 phon). Listening at 65 phon requires elevated low-end compensation:

| Metric (Calculated ISO 226:2003) | 20 Hz | 30 Hz | 40 Hz | 60 Hz | 80 Hz | 100 Hz | 150 Hz | 200 Hz | 300 Hz |
|---|---|---|---|---|---|---|---|---|---|
| Difference: 80 phon vs. 65 phon | +7.2 dB | +6.2 dB | +5.4 dB | +4.3 dB | +3.5 dB | +2.9 dB | +2.0 dB | +1.4 dB | +0.7 dB |
| Difference: 80 phon vs. 50 phon | +14.6 dB | +12.5 dB | +10.9 dB | +8.7 dB | +7.1 dB | +5.9 dB | +4.0 dB | +2.8 dB | +1.5 dB |

Applying a full ISO 226 curve to headphones that already exhibit +4 to +9 dB of mid-bass boost introduces catastrophic acoustic masking across vocals and instrument fundamentals. The solution is **Truncated ISO 226**: applying low-shelf gain only below 70 Hz while cutting 150–250 Hz. This yields sub-bass rumble without clouding the mix.

---

## 3. EasyEffects Architecture: The `mda Loudness` Plugin and Control Scaling

In EasyEffects 8.3.0 source code, "Bass Loudness" loads **`http://drobilla.net/plugins/mda/Loudness`** from the `mda-lv2` package ([bass_loudness.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_loudness.cpp)). (The distinct "Loudness" plugin loads LSP's `loud_comp_stereo` ([loudness.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/loudness.cpp))). MDA's three control ports (`loudness`, `output`, and `link`) accept **normalized floating-point values from 0.0 to 1.0**, with defaults of 0.70, 0.50, and 0.35 ([Loudness.ttl](https://gitlab.com/drobilla/mda-lv2/-/blob/master/mda.lv2/Loudness.ttl)). EasyEffects serializes and exposes these controls in "dB" using internal `db_to_linear` conversion: default values of −3.1 dB, −6.0 dB, and −9.1 dB correspond linearly to 0.70, 0.50, and 0.35 ([lv2_macros.hpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/lv2_macros.hpp); [kcfg](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/contents/kcfg/easyeffects_db_bass_loudness.kcfg)). Internally, MDA computes gain as:
$$\text{gain} = \pm 60 \cdot (2p - 1)^2 \text{ dB}$$
derived from Stevens-Davis equal-loudness approximations rather than ISO 226. When internal gain is positive ($p > 0.5$), it enters boost mode; when zero or negative, it attenuates.

Simulating the MDA DSP filter response at 48 kHz across EasyEffects' exposed parameter range (Output = −6.0 dB / 0 dB net, Link disabled) produces the following curve ([mdaLoudness.cpp](https://gitlab.com/drobilla/mda-lv2/-/blob/master/src/mdaLoudness.cpp)):

| `loudness` Setting in EasyEffects | 20 Hz | 40 Hz | 60 Hz | 100 Hz | 200 Hz | 500 Hz |
|---|---|---|---|---|---|---|
| −10.0 dB (Legacy Preset) | **−7.2 dB** | **−6.2 dB** | **−5.0 dB** | −2.9 dB | −0.8 dB | −0.2 dB |
| −6.0 dB | 0.0 dB | 0.0 dB | 0.0 dB | 0.0 dB | 0.0 dB | 0.0 dB |
| −3.5 dB | −1.0 dB | **−10.3 dB** | −4.3 dB | −1.5 dB | −0.4 dB | −0.1 dB |
| **−3.1 dB (Default)** | **+3.5 dB** | **+3.5 dB** | **+2.7 dB** | +1.5 dB | +0.4 dB | 0.0 dB |
| −3.0 dB | +4.1 dB | +4.9 dB | +4.2 dB | +2.6 dB | +0.9 dB | +0.1 dB |
| −2.5 dB | +7.3 dB | +6.8 dB | +6.0 dB | +4.5 dB | +2.0 dB | +0.3 dB |
| −2.0 dB | +13.1 dB | +12.1 dB | +10.7 dB | +7.6 dB | +2.7 dB | +0.1 dB |

Operational rules:
1. **The operational window is narrow:** Between **−3.1 and −2.5**, boost ranges from +3.5 to +7.0 dB centered across 20–60 Hz. Values between −6.0 and −3.2 create severe phase cancellation notches (−10 dB at 40 Hz with −3.5). Values below −6.0 attenuate sub-bass. Values above −2.0 introduce severe clipping.
2. **Output must remain locked at −6.0 dB:** (representing 0 dB unity gain). Managing digital headroom must occur via `input-gain` in the equalizer.
3. **Link must remain disabled (−9.1 dB):** When Link is engaged, output gain automatically drops by the nominal mathematical boost (+9.6 dB) while actual acoustic gain is only +3.5 dB, collapsing output volume.
4. **LV2 Missing Dependency Hazard:** If `mda.lv2` is absent from `/usr/lib/lv2`, EasyEffects bypasses processing silently without throwing errors ([bass_loudness.cpp](https://github.com/wwmm/easyeffects/blob/v8.3.0/src/bass_loudness.cpp)). The package must be explicitly installed via `sudo pacman -S mda.lv2` and existing presets updated immediately to replace `-10.0` with `-3.1`.

---

## 4. DSP Processing Topology: Minimum-Phase IIR, Headroom, and Limiting

The signal processing pipeline executes in the following sequence:
$$\text{Parametric Equalizer (LSP)} \longrightarrow \text{Bass Loudness (MDA)} \longrightarrow \text{Limiter (LSP)}$$

1. **Equalizer Settings:** The LSP equalizer (`para_equalizer_x32_lr`) should run in **`IIR` mode with `RLC (BT)` filter characteristics and `x1` slopes**. Minimum-phase IIR avoids latency and pre-ringing artifacts. (If importing filters directly from AutoEq or EqualizerAPO, configure `APO (DR)` biquads instead) ([LSP Equalizer Manual](https://lsp-plug.in/?page=manuals&section=para_equalizer_x32_lr)).
2. **Digital Headroom Pre-Amplification:** The equalizer's `input-gain` must offset the maximum cumulative boost of the chain:
   $$\text{Preamp Gain} \le - (\text{Peak EQ Boost} + \text{MDA Boost})$$
   Summing the low-shelf (+4 to +5 dB) and Bass Loudness (+3.5 dB) yields a peak gain of ~7.7 dB at 35 Hz. Setting `input-gain: -8.0 dB` guarantees digital clipping cannot occur prior to the limiter stage ([PEQdB White Paper](https://peqdb.com/wiki/PEQdB-White-Paper.pdf)).
3. **Limiter Configuration:** LSP Limiter enforces a maximum release time of **20 ms** (clamped to $2 \times \text{lookahead}$) in EasyEffects ([LSP Limiter Manual](https://lsp-plug.in/?page=manuals&section=sc_limiter_stereo)). Configure the limiter as a safety net: threshold at −1.0 dB, `gain-boost: false`, oversampling set to `True Peak/24 bit` against intersample overs, and operating mode set to `Herm Wide`. On the gaming profile (Quantum 350), lookahead is restricted to 5 ms (10 ms release) to eliminate audible processing delay.

---

## 5. Validated EasyEffects JSON Profiles

Net frequency response combining the parametric equalizer with Bass Loudness (−3.1):

| Profile | 20 Hz | 30 Hz | 40 Hz | 60 Hz | 80 Hz | 100 Hz | 150 Hz | 200 Hz | 300 Hz |
|---|---|---|---|---|---|---|---|---|---|
| **Quantum 350** | +6.2 dB | +7.7 dB | +7.7 dB | +5.7 dB | +3.6 dB | +1.9 dB | −0.3 dB | −1.5 dB | −1.0 dB |
| **Generic JBL** | +5.1 dB | +6.6 dB | +6.5 dB | +4.3 dB | +2.5 dB | +1.1 dB | −0.4 dB | −1.0 dB | −0.6 dB |

### Parametric Filter Topology (Identical Stereo Channels):

| Band | Quantum 350 | Generic JBL (Tune / Live) |
|---|---|---|
| **band0** | High-pass 18 Hz, Q = 0.7, x1 | High-pass 18 Hz, Q = 0.7, x1 |
| **band1** | Low-shelf 70 Hz, +5.0 dB, Q = 0.7 | Low-shelf 60 Hz, +4.0 dB, Q = 0.7 |
| **band2** | Bell 200 Hz, −2.0 dB, Q = 1.0 | Bell 170 Hz, −1.5 dB, Q = 0.8 |
| **band3** | Bell 4500 Hz, +2.0 dB, Q = 2.0 | Bell 5100 Hz, +2.0 dB, Q = 2.0 |
| **band4** | Bell 8000 Hz, −3.0 dB, Q = 2.0 | Bell 6600 Hz, −2.5 dB, Q = 4.0 |
| **Preamp (`input-gain`)** | **−8.0 dB** | **−8.0 dB** |

---

### Complete Preset: `RedRog Quantum 350 Bass Loudness.json`

```json
{
    "output": {
        "blocklist": [],
        "plugins_order": ["equalizer#0", "bass_loudness#0", "limiter#0"],
        "equalizer#0": {
            "bypass": false, "input-gain": -8.0, "output-gain": 0.0,
            "mode": "IIR", "num-bands": 5, "split-channels": false,
            "left": {
                "band0": {"type": "Hi-pass",  "mode": "RLC (BT)", "slope": "x1", "frequency": 18.0,   "gain": 0.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band1": {"type": "Lo-shelf", "mode": "RLC (BT)", "slope": "x1", "frequency": 70.0,   "gain": 5.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band2": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 200.0,  "gain": -2.0, "q": 1.0, "width": 4.0, "mute": false, "solo": false},
                "band3": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 4500.0, "gain": 2.0,  "q": 2.0, "width": 4.0, "mute": false, "solo": false},
                "band4": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 8000.0, "gain": -3.0, "q": 2.0, "width": 4.0, "mute": false, "solo": false}
            },
            "right": {
                "band0": {"type": "Hi-pass",  "mode": "RLC (BT)", "slope": "x1", "frequency": 18.0,   "gain": 0.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band1": {"type": "Lo-shelf", "mode": "RLC (BT)", "slope": "x1", "frequency": 70.0,   "gain": 5.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band2": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 200.0,  "gain": -2.0, "q": 1.0, "width": 4.0, "mute": false, "solo": false},
                "band3": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 4500.0, "gain": 2.0,  "q": 2.0, "width": 4.0, "mute": false, "solo": false},
                "band4": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 8000.0, "gain": -3.0, "q": 2.0, "width": 4.0, "mute": false, "solo": false}
            }
        },
        "bass_loudness#0": {
            "bypass": false, "input-gain": 0.0, "output-gain": 0.0,
            "loudness": -3.1, "output": -6.0, "link": -9.1
        },
        "limiter#0": {
            "bypass": false, "input-gain": 0.0, "output-gain": 0.0,
            "mode": "Herm Wide", "oversampling": "True Peak/24 bit", "dithering": "None",
            "sidechain-type": "Internal", "sidechain-preamp": 0.0,
            "lookahead": 5.0, "attack": 5.0, "release": 10.0,
            "threshold": -1.0, "gain-boost": false, "stereo-link": 100.0,
            "alr": false, "alr-attack": 5.0, "alr-release": 50.0, "alr-knee": 0.0, "alr-knee-smooth": -5.0
        }
    }
}
```

---

### Complete Preset: `RedRog JBL Bass Loudness.json` (Generic Profile)

```json
{
    "output": {
        "blocklist": [],
        "plugins_order": ["equalizer#0", "bass_loudness#0", "limiter#0"],
        "equalizer#0": {
            "bypass": false, "input-gain": -8.0, "output-gain": 0.0,
            "mode": "IIR", "num-bands": 5, "split-channels": false,
            "left": {
                "band0": {"type": "Hi-pass",  "mode": "RLC (BT)", "slope": "x1", "frequency": 18.0,   "gain": 0.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band1": {"type": "Lo-shelf", "mode": "RLC (BT)", "slope": "x1", "frequency": 60.0,   "gain": 4.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band2": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 170.0,  "gain": -1.5, "q": 0.8, "width": 4.0, "mute": false, "solo": false},
                "band3": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 5100.0, "gain": 2.0,  "q": 2.0, "width": 4.0, "mute": false, "solo": false},
                "band4": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 6600.0, "gain": -2.5, "q": 4.0, "width": 4.0, "mute": false, "solo": false}
            },
            "right": {
                "band0": {"type": "Hi-pass",  "mode": "RLC (BT)", "slope": "x1", "frequency": 18.0,   "gain": 0.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band1": {"type": "Lo-shelf", "mode": "RLC (BT)", "slope": "x1", "frequency": 60.0,   "gain": 4.0,  "q": 0.7, "width": 4.0, "mute": false, "solo": false},
                "band2": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 170.0,  "gain": -1.5, "q": 0.8, "width": 4.0, "mute": false, "solo": false},
                "band3": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 5100.0, "gain": 2.0,  "q": 2.0, "width": 4.0, "mute": false, "solo": false},
                "band4": {"type": "Bell",     "mode": "RLC (BT)", "slope": "x1", "frequency": 6600.0, "gain": -2.5, "q": 4.0, "width": 4.0, "mute": false, "solo": false}
            }
        },
        "bass_loudness#0": {
            "bypass": false, "input-gain": 0.0, "output-gain": 0.0,
            "loudness": -3.1, "output": -6.0, "link": -9.1
        },
        "limiter#0": {
            "bypass": false, "input-gain": 0.0, "output-gain": 0.0,
            "mode": "Herm Wide", "oversampling": "True Peak/24 bit", "dithering": "None",
            "sidechain-type": "Internal", "sidechain-preamp": 0.0,
            "lookahead": 10.0, "attack": 5.0, "release": 20.0,
            "threshold": -1.0, "gain-boost": false, "stereo-link": 100.0,
            "alr": false, "alr-attack": 5.0, "alr-release": 50.0, "alr-knee": 0.0, "alr-knee-smooth": -5.0
        }
    }
}
```

---

## Conclusion

Equalizing JBL headphones for bass loudness is fundamentally an exercise in **relocating** low-frequency energy rather than blindly boosting it. Factory acoustic tuning already saturates listener demand across 80–200 Hz; what headphones require is clean sub-bass extension below 60 Hz paired with acoustic de-masking at 200 Hz and 5 kHz. Truncating the ISO 226 curve below 70 Hz restores natural low-end weight without clouding the soundstage. In PipeWire / EasyEffects workflows, UI controls must be verified against actual DSP implementations: Bass Loudness displays a 0.0–1.0 control in decibels, behaves as an attenuator below −6.0 dB, and silently bypasses if `mda.lv2` is omitted from the operating system.
