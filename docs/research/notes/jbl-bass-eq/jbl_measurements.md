# JBL headphones: measured deviations from Harman and published parametric EQ corrections

Method note (applies to all sections): AutoEq numbers below come from the repository files themselves (ParametricEQ.txt and the per-model CSV). "Deviation" is AutoEq's `error_smoothed` column: the measured response minus AutoEq's target for that rig (a Harman over-ear 2018-derived target, calibrated per rig), normalized by AutoEq. **Positive means louder than target.** Harman already includes about +6 dB of bass shelf below roughly 105 Hz, so "+4 dB at 100 Hz" means about 4 dB *above Harman*, not above flat. Deviation values were read at single frequencies from the smoothed curve. I computed them from the downloaded CSVs; they are not quoted by any reviewer. All AutoEq presets use 10 filters: LSC = low shelf, PK = peaking, HSC = high shelf. Every preset includes the preamp shown.

AutoEq results root: https://github.com/jaakkopasanen/AutoEq/tree/master/results (index: https://github.com/jaakkopasanen/AutoEq/blob/master/results/INDEX.md)

## JBL Quantum 350 (and Quantum 600 / 910): measured response and AutoEq preset

### Takeaway
I found **no published frequency-response measurement or AutoEq/parametric preset for the Quantum 350, 600 or 910**. They are absent from AutoEq's INDEX.md, oratory1990 and Crinacle (none of these list a JBL Quantum model), every squig.link database checked, and RTINGS' review list. The nearest measured relatives are the Quantum 100, 400 and 800 (RTINGS, HMS II.3 rig). All three show the same pattern: a bass/mid-bass hump of +4 to +5 dB above Harman around 100–250 Hz, a deep 4–5 kHz dip of −7 to −15 dB, and +5 to +7 dB of treble excess at 7–10 kHz.

### Cited Findings
- AutoEq INDEX.md lists only these JBL Quantum entries: Quantum 100, Quantum 400, Quantum 800 and Quantum ONE, all "by Rtings on HMS II.3". It has no 350, 600 or 910 — [AutoEq INDEX.md](https://github.com/jaakkopasanen/AutoEq/blob/master/results/INDEX.md)
- oratory1990's AutoEq over-ear folder has only three JBL models: Duet NC (ANC Off and ANC On) and T450BT — [AutoEq oratory1990 over-ear](https://github.com/jaakkopasanen/AutoEq/tree/master/results/oratory1990/over-ear)
- These squig.link phone books were checked: graph.hangout.audio/headphones (Crinacle), squig.link, hbb, pw, sai, timmyv, bakkwatan, filk, kuulokenurkka and kr0mka. None lists a JBL Quantum model. Filk has Live 770NC, Tune 720BT, Tune 770NC and Tour One M2/M3. Kuulokenurkka has Live 780NC, Tune 530BT, Tune 770NC and Tour One M3 — [filk.squig.link](https://filk.squig.link/), [kuulokenurkka.squig.link](https://kuulokenurkka.squig.link/)
- An RTINGS site search returns only the Quantum ONE, 800 Wireless, 400 and 100 reviews. RTINGS calls the 400 "boomy bass-heavy" with "somewhat veiled treble", and says fit changes the sound — [RTINGS Quantum 400](https://www.rtings.com/headphones/reviews/jbl/quantum-400), [RTINGS Quantum 800](https://www.rtings.com/headphones/reviews/jbl/quantum-800-wireless), [RTINGS Quantum 100](https://www.rtings.com/headphones/reviews/jbl/quantum-100)
- SoundGuys, Quantum 350 Wireless (qualitative; no dB numbers in the page text, charts did not load):
  - Bass is boosted more than their house curve, "typical of JBL headphones".
  - "Sub-bass and bass notes sound more than twice as loud as the quietest mids around 400Hz", which is roughly a 10 dB perceived difference.
  - EQ is available in Windows-only QuantumENGINE.
  - [SoundGuys Quantum 350](https://www.soundguys.com/jbl-quantum-350-wireless-review-63655/)
- One reviewer says the Quantum 350's low end is weaker than the Quantum 610/810 — [Cogconnected](https://cogconnected.com/review/jbl-quantum-350-wireless-review/) (via search snippet; not verified in full text)
- Quantum 910 spec sheet: 50 mm drivers, 20 Hz–20 kHz active and 20 Hz–40 kHz passive. These are manufacturer specs, not measurements — [JBL support Q910](https://support.jbl.com/ca/en/headphones/headphones-gaming/QUANTUM910WIRELESS.html)

**Quantum relatives: deviation from target in dB (RTINGS HMS II.3 via AutoEq CSV)**

| Hz | 20 | 30 | 50 | 80 | 100 | 150 | 200 | 250 | 500 | 1k | 2k | 3k | 4k | 5k | 6k | 7k | 8k | 9k | 10k |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Quantum 100 | −1.4 | −3.1 | −3.1 | −1.1 | +1.9 | +4.5 | +5.4 | +5.0 | −2.7 | −1.9 | −4.4 | −0.1 | −11.5 | −5.2 | +2.7 | +5.3 | +6.1 | +5.4 | +3.5 |
| Quantum 400 | −5.9 | +0.4 | +2.7 | +3.9 | +4.3 | +3.3 | +2.0 | +0.6 | −0.5 | +0.1 | +0.1 | +2.0 | −14.0 | −11.8 | −0.4 | +3.9 | +4.9 | +5.3 | +4.4 |
| Quantum 800 | −2.8 | +1.3 | +2.4 | +3.9 | +4.4 | +4.1 | +2.5 | +1.0 | −1.6 | −1.5 | −0.6 | −0.2 | −7.1 | −9.9 | +2.4 | +3.4 | +5.8 | +7.1 | +6.4 |
| Quantum ONE | −8.1 | −1.4 | −0.9 | −1.1 | −1.2 | −1.9 | −0.9 | −0.3 | −1.1 | −3.0 | +1.3 | +3.3 | −0.3 | −0.6 | +3.9 | +3.0 | +3.5 | +3.6 | +2.7 |

Extremes between 2 and 10 kHz:

| Model | Largest dip | Largest peak |
|---|---|---|
| Quantum 100 | −15.4 @ 4398 Hz | +6.2 @ 8231 Hz |
| Quantum 400 | −14.7 @ 4268 Hz | +5.4 @ 8651 Hz |
| Quantum 800 | −10.9 @ 4668 Hz | +7.2 @ 9092 Hz |

Sources: [Q100](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Quantum%20100), [Q400](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Quantum%20400), [Q800](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Quantum%20800), [Quantum ONE](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Quantum%20ONE)

**AutoEq ParametricEQ presets, Quantum relatives (as published)**

Quantum 100 — Preamp −6.6 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | +1.7 | 0.70 |
| 2 | PK | 192 | −7.3 | 0.73 |
| 3 | PK | 1660 | +3.7 | 0.18 |
| 4 | PK | 50 | +3.0 | 0.91 |
| 5 | PK | 7901 | −8.6 | 1.68 |
| 6 | HSC | 10000 | −3.5 | 0.70 |
| 7 | PK | 4052 | +5.0 | 3.59 |
| 8 | PK | 2856 | −4.3 | 4.23 |
| 9 | PK | 552 | +3.3 | 3.18 |
| 10 | PK | 779 | −3.3 | 3.14 |

Quantum 400 — Preamp −6.5 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | +18.0 | 0.70 |
| 2 | PK | 8615 | −6.4 | 0.34 |
| 3 | PK | 47 | −20.0 | 0.30 |
| 4 | PK | 4612 | +11.1 | 1.76 |
| 5 | PK | 291 | +6.0 | 0.76 |
| 6 | HSC | 10000 | +0.3 | 0.70 |
| 7 | PK | 1580 | +1.1 | 1.42 |
| 8 | PK | 2869 | −2.7 | 3.79 |
| 9 | PK | 3833 | +1.5 | 4.28 |
| 10 | PK | 766 | −0.9 | 2.86 |

Quantum 800 — Preamp −6.2 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | +9.2 | 0.70 |
| 2 | PK | 10000 | −7.5 | 0.40 |
| 3 | PK | 59 | −12.1 | 0.30 |
| 4 | PK | 4339 | +10.0 | 1.93 |
| 5 | PK | 375 | +3.8 | 0.37 |
| 6 | HSC | 10000 | +3.6 | 0.70 |
| 7 | PK | 9190 | −2.0 | 3.27 |
| 8 | PK | 1529 | +1.6 | 2.86 |
| 9 | PK | 2660 | −1.4 | 3.70 |
| 10 | PK | 690 | −1.1 | 3.19 |

Source: the ParametricEQ.txt in each folder above.

### Inferences
- The Quantum 400 and 800 presets pair a large LSC boost (+18 / +9.2 dB) with a wide, deep cut near 50 Hz (−20 / −12.1 dB, Q 0.3). The net bass change is far smaller than either filter suggests. These are optimizer artifacts and should not be used as a base for bass EQ. Read the deviation table instead: the real need is about −4 dB at 80–200 Hz.
- The −11 to −15 dB dips at 4.3–4.7 kHz appear on all three Quantum models measured on HMS II.3. They are probably partly genuine JBL tuning, given the 4–5 kHz dips on the Tune/Live models below on other rigs, but partly a rig/fit artifact. The +10/+11 dB PK filters there should be scaled down (for example to +4–6 dB) on real heads.
- For a Quantum 350 with no measurement, the defensible base is the shared Quantum family pattern:
  - roughly −3 to −4 dB of mid-bass (100–250 Hz),
  - a moderate presence fill at about 4.5 kHz,
  - −3 to −5 dB in the 7–10 kHz region.
  
  Any bass boost should go below about 80 Hz, where these headsets already sit at or under target.

### Gaps
- No measurement exists anywhere I checked for the Quantum 350, 600 or 910, so there is no rolloff frequency or treble-peak data for them.
- RTINGS' numeric sound scores (bass accuracy, low-frequency extension and so on) are not in the static HTML. With Test Bench 2.0 they render client-side and partly sit behind a paywall, so I could not extract them for any model.

## Tune 520BT / 510BT / 750–770NC, Live 660/670/770NC: measurements, presets, and the common "Pure Bass" pattern

### Takeaway
There is no single "Pure Bass" curve. Most models sit **+2 to +9 dB above Harman between 50 and 150 Hz**, with the peak around 80–110 Hz. The exceptions are the Tune 520BT, close to target down to 50 Hz, and the Tune 770NC, which is at or below target from 100 to 250 Hz on RTINGS. Sub-bass under 30 Hz varies widely by model and rig, from −9 to +7.5 dB.

The recurring features are:
- a **dip of about −2.5 to −5 dB near 5.0–5.3 kHz**, which appears on almost every model;
- a narrow **peak near 6.4–6.7 kHz**, +3 to +6 dB, on many models;
- moderate excess at 7–10 kHz on the Tune 750/770NC and Live 660NC.

The newer Live 670NC and 770NC (B&K 5128) have the biggest bass bumps, +7.4 to +9.3 dB at 80–100 Hz.

### Cited Findings

**Deviation from target in dB (AutoEq CSV `error_smoothed`)**

| Model (rig) | 20 | 30 | 50 | 80 | 100 | 150 | 200 | 250 | 500 | 1k | 2k | 3k | 4k | 5k | 6k | 7k | 8k | 9k | 10k |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tune 510BT (RTINGS HMS II.3) | −5.3 | −0.6 | +3.8 | +4.1 | +2.9 | +0.1 | +1.2 | +1.6 | −2.0 | −1.7 | −4.2 | +0.2 | +1.9 | +2.1 | +2.6 | +4.9 | +2.5 | +1.3 | +0.4 |
| Tune 520BT (RTINGS B&K 5128) | −9.3 | −5.6 | +0.3 | +1.8 | +1.1 | 0.0 | +0.2 | +0.9 | −0.3 | +1.2 | −1.9 | +2.1 | +2.0 | −3.5 | −1.2 | −2.1 | −1.9 | −1.8 | −2.5 |
| Tune 750BTNC (RTINGS HMS II.3) | +0.9 | +2.0 | +3.3 | +3.0 | +2.3 | +0.3 | −0.3 | −0.7 | −1.1 | +0.7 | −1.6 | −0.3 | −2.1 | −2.7 | +0.8 | +3.7 | +3.2 | +4.5 | +5.2 |
| Tune 760NC (RTINGS 5128) | +1.9 | +6.1 | +4.9 | +2.6 | +2.8 | +0.8 | +0.6 | +1.6 | −0.3 | −1.7 | −2.3 | +3.6 | −0.1 | −2.6 | +2.7 | +1.3 | +1.4 | +1.6 | +1.5 |
| Tune 770NC (RTINGS 5128) | +3.2 | +4.7 | +3.6 | +0.8 | −0.4 | −1.4 | −0.7 | −0.4 | +1.9 | −1.6 | −1.5 | +0.9 | +0.4 | −2.0 | +1.2 | +2.4 | +3.5 | +4.5 | +4.5 |
| Tune 770NC ANC on (Filk) | −11.3 | −5.7 | −1.4 | +0.6 | −0.9 | −2.8 | −2.2 | −2.2 | +0.2 | +0.7 | +2.2 | +3.1 | −0.7 | −3.5 | −0.6 | +1.4 | +2.1 | +2.7 | +2.4 |
| Tune 770NC ANC on (Kuulokenurkka) | +4.3 | +4.8 | +3.3 | +1.3 | 0.0 | −1.5 | −0.6 | −0.3 | +1.8 | −0.4 | −1.6 | +2.5 | +2.2 | −2.0 | +0.5 | −0.8 | −0.8 | +1.0 | +1.9 |
| Live 660NC (RTINGS HMS II.3) | +1.0 | +1.9 | +3.7 | +3.3 | +2.0 | −1.9 | −1.7 | +0.1 | +0.1 | +1.0 | −0.7 | −0.6 | −1.6 | −3.3 | +3.4 | +4.0 | +1.8 | +2.6 | +3.0 |
| Live 670NC (RTINGS 5128) | +2.8 | +4.0 | +5.0 | +7.4 | +7.9 | +4.7 | +1.4 | −0.2 | −5.7 | +0.1 | −1.2 | −1.0 | +0.8 | +3.9 | +5.9 | +0.9 | −1.1 | −3.1 | −5.4 |
| Live 770NC (RTINGS 5128) | +7.5 | +7.5 | +6.3 | +8.2 | +9.3 | +4.5 | +1.3 | +1.5 | −2.9 | −0.4 | −2.4 | −5.0 | +1.0 | −2.8 | +0.8 | +2.6 | +0.8 | +0.5 | −0.2 |
| Live 770NC ANC on (Filk) | +0.5 | +4.2 | +4.9 | +7.5 | +7.3 | +2.5 | +0.1 | +0.9 | −3.5 | −0.2 | +1.2 | +0.8 | −1.4 | −3.8 | −2.4 | +1.2 | −0.7 | −0.7 | −0.9 |
| T450BT (oratory1990) | −8.1 | −4.9 | −1.2 | +1.9 | +3.8 | +5.3 | +4.8 | +3.0 | −0.4 | +1.5 | −2.9 | +0.3 | −0.5 | −1.6 | −6.4 | −5.9 | −6.4 | −6.2 | −6.1 |

Extremes between 2 and 10 kHz:

| Model | Largest dip | Largest peak |
|---|---|---|
| Tune 510BT | −4.2 @ 2004 Hz | +5.0 @ 6950 Hz |
| Tune 520BT | −3.6 @ 5208 Hz | +3.7 @ 3463 Hz |
| Tune 750BTNC | −2.9 @ 4858 Hz | +5.2 @ 9944 Hz |
| Tune 760NC | −3.3 @ 5208 Hz | +4.8 @ 6355 Hz |
| Tune 770NC (RTINGS) | −2.4 @ 5208 Hz | +4.7 @ 9556 Hz |
| Live 660NC | −4.0 @ 5208 Hz | +5.9 @ 6613 Hz |
| Live 670NC | −5.2 @ 9944 Hz | +6.0 @ 5927 Hz |
| Live 770NC (RTINGS) | −5.2 @ 2954 Hz | +4.5 @ 6679 Hz |
| T450BT | −7.7 @ 6547 Hz | (none listed) |

Source folders: [Tune 510BT](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Tune%20510BT), [Tune 520BT](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/Bruel%20&%20Kjaer%205128%20over-ear/JBL%20Tune%20520BT), [Tune 750BTNC](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20TUNE%20750BTNC), [Tune 760NC](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/Bruel%20&%20Kjaer%205128%20over-ear/JBL%20Tune%20760NC), [Tune 770NC RTINGS](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/Bruel%20&%20Kjaer%205128%20over-ear/JBL%20Tune%20770NC), [Tune 770NC Filk](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Filk/over-ear), [Tune 770NC Kuulokenurkka](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Kuulokenurkka/over-ear), [Live 660NC](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/HMS%20II.3%20over-ear/JBL%20Live%20660NC), [Live 670NC](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/Bruel%20&%20Kjaer%205128%20over-ear/JBL%20Live%20670NC), [Live 770NC](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Rtings/Bruel%20&%20Kjaer%205128%20over-ear/JBL%20Live%20770NC), [T450BT oratory1990](https://github.com/jaakkopasanen/AutoEq/tree/master/results/oratory1990/over-ear/JBL%20T450BT)

- **Tune 530BT** (successor to the 520BT), Kuulokenurkka squig raw data, which I compared against the AutoEq Harman over-ear 2018 target normalized at 1 kHz (my own calculation; the rig differs from Harman's GRAS, so treat it as approximate). Left channel:

  | Hz | 20 | 30 | 50 | 80 | 100 | 150 | 200 | 300 | 2k | 3k | 4k | 5k | 6k | 7k | 8k | 9k | 10k |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Deviation (dB) | −5.4 | −1.8 | +2.1 | +3.8 | +4.5 | +2.7 | +0.9 | −1.5 | −4.6 | −5.1 | −3.3 | −4.0 | +0.7 | +0.4 | −2.7 | +1.5 | −5.1 |

  The right channel is similar. In short: mid-bass hump at about 100 Hz, presence recessed about 4–5 dB at 2–5 kHz, sub-bass rolls off below about 40 Hz — [kuulokenurkka.squig.link](https://kuulokenurkka.squig.link/) (files "Tune 530BT ** L/R"), [AutoEq Harman over-ear 2018 target](https://github.com/jaakkopasanen/AutoEq/tree/master/targets)
- AutoEq has no entry for the Tune 750BT (non-NC), Tune 760NC from other sources, Quantum 600/910/350, or Live 660NC/670NC beyond RTINGS — [AutoEq INDEX.md](https://github.com/jaakkopasanen/AutoEq/blob/master/results/INDEX.md)

**AutoEq ParametricEQ presets, Tune / Live / T450 (as published)**

Tune 520BT (RTINGS 5128) — Preamp −6.4 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | +8.0 | 0.70 |
| 2 | PK | 62 | −8.3 | 0.79 |
| 3 | PK | 3532 | −6.8 | 2.66 |
| 4 | PK | 2056 | +2.0 | 2.83 |
| 5 | PK | 4892 | +3.8 | 0.93 |
| 6 | HSC | 10000 | +3.0 | 0.70 |
| 7 | PK | 944 | −1.5 | 3.44 |
| 8 | PK | 173 | +0.9 | 3.12 |
| 9 | PK | 48 | −1.0 | 2.47 |
| 10 | PK | 60 | +1.4 | 4.62 |

Tune 510BT (RTINGS HMS II.3) — Preamp −4.6 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | +7.9 | 0.70 |
| 2 | PK | 53 | −12.2 | 0.69 |
| 3 | PK | 1873 | +3.3 | 0.30 |
| 4 | PK | 6973 | −5.3 | 2.35 |
| 5 | PK | 3979 | −4.3 | 1.79 |
| 6 | HSC | 10000 | −3.7 | 0.70 |
| 7 | PK | 402 | −1.2 | 0.27 |
| 8 | PK | 1875 | +2.3 | 3.70 |
| 9 | PK | 429 | +4.3 | 4.17 |
| 10 | PK | 153 | +3.0 | 3.92 |

Tune 750BTNC (RTINGS HMS II.3) — Preamp −3.0 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −1.0 | 0.70 |
| 2 | PK | 62 | −2.8 | 0.85 |
| 3 | PK | 373 | +1.4 | 0.79 |
| 4 | PK | 1740 | +2.2 | 2.18 |
| 5 | PK | 1052 | −1.4 | 1.73 |
| 6 | HSC | 10000 | −8.3 | 0.70 |
| 7 | PK | 5014 | +3.2 | 4.41 |
| 8 | PK | 6829 | −3.0 | 5.76 |
| 9 | PK | 8983 | −1.6 | 3.97 |
| 10 | PK | 3814 | +1.5 | 3.62 |

Tune 760NC (RTINGS 5128) — Preamp −3.9 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −4.5 | 0.70 |
| 2 | PK | 1609 | +4.0 | 1.67 |
| 3 | PK | 2953 | −4.7 | 4.02 |
| 4 | PK | 716 | +3.3 | 3.98 |
| 5 | PK | 6417 | −4.1 | 4.96 |
| 6 | HSC | 10000 | −1.5 | 0.70 |
| 7 | PK | 273 | −1.5 | 2.21 |
| 8 | PK | 4607 | +3.2 | 5.05 |
| 9 | PK | 9429 | −1.0 | 2.03 |
| 10 | PK | 73 | +0.5 | 2.48 |

Tune 770NC (RTINGS 5128) — Preamp −2.5 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −3.8 | 0.70 |
| 2 | PK | 8989 | −4.6 | 1.76 |
| 3 | PK | 1646 | +2.9 | 1.03 |
| 4 | PK | 111 | +2.9 | 1.24 |
| 5 | PK | 2845 | −2.6 | 2.14 |
| 6 | HSC | 10000 | −1.8 | 0.70 |
| 7 | PK | 514 | −2.6 | 2.09 |
| 8 | PK | 5044 | +3.0 | 4.22 |
| 9 | PK | 806 | +1.4 | 2.84 |
| 10 | PK | 6424 | −2.3 | 6.00 |

Tune 770NC ANC on (Filk) — Preamp −6.6 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | +8.3 | 0.70 |
| 2 | PK | 131 | +7.2 | 0.59 |
| 3 | PK | 4434 | −7.6 | 0.57 |
| 4 | PK | 75 | −12.0 | 0.68 |
| 5 | PK | 4775 | +11.0 | 1.63 |
| 6 | HSC | 10000 | −5.6 | 0.70 |
| 7 | PK | 8844 | +1.8 | 1.66 |
| 8 | PK | 482 | −0.8 | 3.09 |
| 9 | PK | 299 | +0.7 | 3.22 |
| 10 | PK | 1528 | +1.0 | 5.61 |

Tune 770NC ANC on (Kuulokenurkka) — Preamp −1.9 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −5.0 | 0.70 |
| 2 | PK | 103 | +3.1 | 0.74 |
| 3 | PK | 3370 | −4.3 | 3.21 |
| 4 | PK | 502 | −2.2 | 1.63 |
| 5 | PK | 1786 | +2.0 | 1.72 |
| 6 | HSC | 10000 | −7.5 | 0.70 |
| 7 | PK | 7862 | +3.2 | 2.47 |
| 8 | PK | 4900 | +2.4 | 6.00 |
| 9 | PK | 6562 | −2.9 | 5.99 |
| 10 | PK | 33 | −0.3 | 3.08 |

Live 660NC (RTINGS HMS II.3) — Preamp −3.1 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −0.8 | 0.70 |
| 2 | PK | 62 | −3.6 | 1.03 |
| 3 | PK | 167 | +3.7 | 3.08 |
| 4 | PK | 6729 | −6.6 | 4.38 |
| 5 | PK | 2391 | +0.9 | 1.87 |
| 6 | HSC | 10000 | −5.2 | 0.70 |
| 7 | PK | 4403 | +2.6 | 2.05 |
| 8 | PK | 3508 | −3.4 | 6.00 |
| 9 | PK | 951 | −1.4 | 4.24 |
| 10 | PK | 727 | +0.8 | 3.59 |

Live 670NC (RTINGS 5128) — Preamp −7.2 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −2.8 | 0.70 |
| 2 | PK | 549 | +5.8 | 0.76 |
| 3 | PK | 100 | −6.6 | 0.74 |
| 4 | PK | 5661 | −6.5 | 3.75 |
| 5 | PK | 1224 | −5.3 | 2.78 |
| 6 | HSC | 10000 | +7.2 | 0.70 |
| 7 | PK | 2523 | +1.6 | 2.46 |
| 8 | PK | 39 | −1.4 | 3.51 |
| 9 | PK | 4595 | −1.7 | 4.39 |
| 10 | PK | 53 | +1.0 | 4.19 |

Live 770NC (RTINGS 5128) — Preamp −3.5 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −7.0 | 0.70 |
| 2 | PK | 110 | −6.0 | 1.69 |
| 3 | PK | 504 | +3.7 | 1.02 |
| 4 | PK | 2450 | +3.5 | 3.16 |
| 5 | PK | 283 | −2.0 | 2.09 |
| 6 | HSC | 10000 | +3.5 | 0.70 |
| 7 | PK | 6563 | −5.0 | 5.67 |
| 8 | PK | 3647 | −4.6 | 6.00 |
| 9 | PK | 4853 | +3.2 | 4.50 |
| 10 | PK | 9256 | −1.8 | 2.55 |

Live 770NC ANC on (Filk) — Preamp −3.9 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −2.8 | 0.70 |
| 2 | PK | 89 | −6.2 | 1.13 |
| 3 | PK | 631 | +4.8 | 1.18 |
| 4 | PK | 1458 | −2.3 | 0.73 |
| 5 | PK | 4974 | +4.3 | 3.94 |
| 6 | HSC | 10000 | −3.1 | 0.70 |
| 7 | PK | 36 | −0.8 | 2.68 |
| 8 | PK | 183 | +1.7 | 3.72 |
| 9 | PK | 275 | −1.0 | 2.72 |
| 10 | PK | 6598 | −1.3 | 6.00 |

Tune 720BT wireless (Filk) — Preamp −6.4 dB

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | +5.6 | 0.70 |
| 2 | PK | 517 | −3.8 | 1.35 |
| 3 | PK | 4658 | +6.0 | 3.26 |
| 4 | PK | 2792 | −3.8 | 2.21 |
| 5 | PK | 1291 | +2.3 | 1.49 |
| 6 | HSC | 10000 | −6.5 | 0.70 |
| 7 | PK | 87 | −2.3 | 1.95 |
| 8 | PK | 169 | +2.3 | 2.39 |
| 9 | PK | 47 | +1.4 | 3.72 |
| 10 | PK | 378 | −0.8 | 4.04 |

Tune 660NC (RTINGS HMS II.3) — Preamp −5.2 dB. Contains ±20 dB opposing filters, so it is not usable as-is.

| # | Type | Fc (Hz) | Gain (dB) | Q |
|---|---|---|---|---|
| 1 | LSC | 105 | −2.5 | 0.70 |
| 2 | PK | 6878 | −19.1 | 0.66 |
| 3 | PK | 5367 | +20.0 | 0.83 |
| 4 | PK | 114 | −7.1 | 0.65 |
| 5 | PK | 143 | +5.4 | 0.46 |
| 6 | HSC | 10000 | +1.7 | 0.70 |
| 7 | PK | 1811 | +1.3 | 2.09 |
| 8 | PK | 2875 | −1.7 | 3.60 |
| 9 | PK | 615 | −0.8 | 2.30 |
| 10 | PK | 381 | +0.6 | 3.72 |

Source: the ParametricEQ.txt in each AutoEq folder linked above.

### Inferences
- **Recurring JBL fingerprint** across rigs:
  1. A mid-bass shelf/hump centered about 80–110 Hz, typically +2 to +4 dB over Harman on Tune models and +7 to +9 dB on the Live 670NC/770NC.
  2. A 5.0–5.3 kHz dip of −2.5 to −5 dB. It shows up at exactly 5208 Hz on several RTINGS units, so it may partly be a measurement-grid point.
  3. A narrow 6.3–6.9 kHz peak of +3 to +6 dB (Live 660NC, Tune 760NC, Live 670NC, 770NC Kuulokenurkka passive).
  4. Mild treble excess at 7–10 kHz on the Tune 750BTNC, Tune 770NC and Live 660NC (+3 to +5 dB).
- I see no consistent 3–5 kHz *peak*. The 2–4 kHz region is model-specific: slightly hot on the Tune 760NC (+3.6 at 3 kHz) and 770NC Filk, and recessed on the Tune 530BT and Live 770NC RTINGS (−5 at 3 kHz).
- **Presets to avoid as a base.** Several presets "fix" bass with a big LSC plus an opposing wide PK near 50–75 Hz (for example the Tune 510BT and 520BT +8 LSC with −8 to −12 PK, and the 770NC Filk). Their net bass effect is small, and they waste headroom (preamp −6 dB).
- **Bass-focused EQ strategy.** First apply the treble/presence corrections from the preset that matches the user's rig and source. Then shape the bass yourself, starting from the deviation tables. The bass need depends on the model:
  - Tune 520BT and 770NC: these need a sub-bass boost below 50 Hz.
  - Live 670NC and 770NC: these need a −4 to −7 dB cut around 80–120 Hz rather than a boost.

### Gaps
- No oratory1990 or Crinacle measurement exists for any current Tune, Live or Quantum model. The only oratory1990 JBL over-ear measurements are the T450BT and Duet NC.
- No AutoEq data exists for the Tune 750BT (non-NC) or Live 670NC from a second source.
- RTINGS scalar scores (bass accuracy, low-frequency extension in Hz) could not be extracted.

## Unit variation and pad seal / fit effects

### Takeaway
Measurements of the same model differ by rig more than the published presets suggest. On the Tune 770NC with ANC on, deviation at 20–30 Hz ranges from −11.3 dB (Filk) to +4.8 dB (Kuulokenurkka). At 100–250 Hz the three sources agree within about 2–3 dB. Left/right mismatch on the Tune 530BT is about 1–2.4 dB in the bass and under 1 dB above 2 kHz. Seal is the main sub-bass variable.

### Cited Findings
- Tune 770NC deviation from target at 20/30/50 Hz differs by source. Above about 100 Hz the sources converge within about 2–3 dB, except in the treble.

  | Source | 20 Hz | 30 Hz | 50 Hz |
  |---|---|---|---|
  | RTINGS 5128 | +3.2 | +4.7 | +3.6 |
  | Kuulokenurkka (ANC on) | +4.3 | +4.8 | +3.3 |
  | Filk (ANC on) | −11.3 | −5.7 | −1.4 |

  — AutoEq CSVs linked above
- Tune 530BT left-minus-right difference (Kuulokenurkka raw, my calculation): +2.4 dB @ 20 Hz, +2.3 @ 80 Hz, +1.1 @ 100 Hz, +0.9 @ 200 Hz, and within ±0.7 dB at 2–9 kHz — [kuulokenurkka.squig.link](https://kuulokenurkka.squig.link/)
- RTINGS notes that sound on the Quantum ONE and Quantum 400 varies with fit and positioning — [RTINGS Quantum ONE](https://www.rtings.com/headphones/reviews/jbl/quantum-one), [RTINGS Quantum 400](https://www.rtings.com/headphones/reviews/jbl/quantum-400)
- Filk publishes a "leak" measurement for the Tour One M3, showing the reviewer measures seal breakage. I did not analyze it numerically — [filk.squig.link](https://filk.squig.link/)

### Inferences
- The Filk Tune 770NC sub-bass shortfall, compared with the other two rigs, is most plausibly a seal/rig difference rather than unit variation alone. Bass boosts below about 60 Hz should be set conservatively (+3 to +6 dB) and tuned by ear. With glasses or a weak seal, the same boost may be needed and still be insufficient.

### Gaps
- No source measured multiple units of the same JBL model. No numeric glasses/leak data for these specific models was found. RTINGS' "Frequency Response Consistency" values could not be extracted.

## Effect of ANC mode, wired/passive mode, JBL app EQ, and Bluetooth

### Takeaway
On the Tune 770NC and Live 770NC, the powered/ANC-on response differs greatly from wired-passive. Powered ANC-on mode adds **+5 to +12 dB below 100 Hz** and **+3 to +6 dB at 2–5 kHz** compared with passive (wired, unpowered). That means the DSP applies much of the "Pure Bass" tuning, and an EQ must match the mode in use. The JBL app's "Bass" preset on the Tune 770NC adds about +4.8 dB at 80–100 Hz, +3 to +4 dB at 150–200 Hz, and slightly cuts the treble (about −1 dB).

### Cited Findings
- Tune 770NC, ANC on minus passive (my calculation from AutoEq raw columns, normalized at 1 kHz):

  | Source | 20 | 30 | 50 | 80 | 100 | 150 | 2k | 3k | 4k | 5k | 9k | 10k |
  |---|---|---|---|---|---|---|---|---|---|---|---|---|
  | Filk | +10.7 | +11.8 | +11.7 | +9.7 | +6.8 | +1.5 | +4.0 | +4.1 | +4.1 | +3.3 | +4.4 | +3.8 |
  | Kuulokenurkka | +8.0 | +7.5 | +4.8 | +2.7 | +0.9 | — | +2.9 | +3.4 | +3.9 | +2.7 | — | — |

  — [AutoEq Filk](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Filk/over-ear), [AutoEq Kuulokenurkka](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Kuulokenurkka/over-ear)
- Live 770NC (Filk), ANC on minus passive: +5.8 @ 20 Hz, +7.1 @ 30, +6.1 @ 50, +7.2 @ 80, +6.1 @ 100, −1.6 @ 150, −3.3 @ 200, then +6.4/+6.5/+6.2/+5.7 at 2/3/4/5 kHz and +2.3 to +4.8 dB at 6–10 kHz — [AutoEq Filk](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Filk/over-ear)
- Tune 770NC passive (Filk) sits −20.4 dB below target at 20 Hz, −11.5 at 50 and −6.2 at 100 Hz. Passive mode effectively has no bass shelf — [AutoEq Filk 770NC passive](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Filk/over-ear)
- JBL app "Bass" preset minus default (Filk, Tune 770NC, ANC on), my calculation: −1.7 @ 20 Hz, +1.3 @ 30, +3.6 @ 50, +4.8 @ 80, +4.8 @ 100, +3.9 @ 150, +3.0 @ 200, +2.2 @ 300, +0.5 @ 500, −0.9 @ 2k, −0.8 @ 4k, −1.1 @ 8k. The AutoEq preset to correct this bass-EQ mode (Preamp −7.0 dB):

  | # | Type | Fc (Hz) | Gain (dB) | Q |
  |---|---|---|---|---|
  | 1 | LSC | 105 | +5.5 | 0.70 |
  | 2 | PK | 68 | −9.9 | 1.10 |
  | 3 | PK | 4751 | +5.3 | 1.96 |
  | 4 | PK | 2985 | −3.7 | 1.91 |
  | 5 | PK | 26 | +3.1 | 5.12 |
  | 6 | HSC | 10000 | −4.5 | 0.70 |
  | 7 | PK | 358 | +0.9 | 0.89 |
  | 8 | PK | 99 | −1.0 | 2.93 |
  | 9 | PK | 466 | −0.7 | 2.82 |
  | 10 | PK | 159 | +0.6 | 2.53 |

  — [AutoEq Filk "JBL Tune 770NC (ANC on, bass EQ)"](https://github.com/jaakkopasanen/AutoEq/tree/master/results/Filk/over-ear)
- Filk passive presets, for wired use:

  Tune 770NC passive — Preamp −6.0 dB

  | # | Type | Fc (Hz) | Gain (dB) | Q |
  |---|---|---|---|---|
  | 1 | LSC | 105 | +5.9 | 0.70 |
  | 2 | PK | 598 | −4.0 | 0.91 |
  | 3 | PK | 108 | +2.9 | 1.34 |
  | 4 | PK | 4477 | +4.8 | 4.03 |
  | 5 | PK | 275 | +2.2 | 2.63 |
  | 6 | HSC | 10000 | −3.1 | 0.70 |
  | 7 | PK | 6477 | −3.1 | 6.00 |
  | 8 | PK | 1636 | +1.2 | 2.61 |
  | 9 | PK | 1024 | −0.4 | 1.69 |
  | 10 | PK | 2730 | −1.2 | 4.60 |

  Live 770NC passive — Preamp −6.1 dB

  | # | Type | Fc (Hz) | Gain (dB) | Q |
  |---|---|---|---|---|
  | 1 | LSC | 105 | +1.2 | 0.70 |
  | 2 | PK | 169 | −7.3 | 0.59 |
  | 3 | PK | 3852 | +4.9 | 0.75 |
  | 4 | PK | 418 | +5.3 | 1.14 |
  | 5 | PK | 1044 | −3.7 | 1.86 |
  | 6 | HSC | 10000 | +0.6 | 0.70 |
  | 7 | PK | 45 | −0.8 | 2.11 |
  | 8 | PK | 6608 | −3.3 | 6.00 |
  | 9 | PK | 5055 | +2.2 | 5.07 |
  | 10 | PK | 111 | +0.6 | 3.17 |

  — same folder
- Kuulokenurkka squig labels its Live 780NC and Tour One M3 measurements separately for "Maximum ANC", "ANC OFF", "Minimum ANC" and app presets ("Studio", "Club"). The measurer evidently found these modes audibly different; I did not analyze them numerically — [kuulokenurkka.squig.link](https://kuulokenurkka.squig.link/)
- AutoEq also holds separate Filk entries for the Tune 720BT in "wireless" and "passive" modes, and for the Tour One M2 "ANC on", "ANC on, studio EQ" and "passive" — [AutoEq INDEX.md](https://github.com/jaakkopasanen/AutoEq/blob/master/results/INDEX.md)

### Inferences
- "Passive" in Filk/Kuulokenurkka means wired with the headphone powered off (no DSP). The large bass difference therefore reflects JBL's DSP tuning (plus ANC loop effects), not ANC alone.
- For Bluetooth use, base the EQ on the "ANC on" or wireless measurement. The passive/wired measurements need a bass shelf about 6–12 dB larger.
- The JBL app's Bass preset behaves roughly like a +5 dB low shelf near 100–150 Hz. Stacking a PC/phone bass EQ on top of it will double the boost.

### Gaps
- I found no measurement isolating ANC on vs ANC off *while powered* (ANC off but DSP active) for the Tune 770NC or Live 770NC.
- I found no data on whether the Bluetooth codec (SBC vs AAC vs LDAC/LC3) changes frequency response on these models. Codec effects on FR are generally negligible, but I found no JBL-specific measurement to confirm that.
- I could not confirm the RTINGS measurement mode (ANC on or off, app EQ default) for each model because the page text did not render.
