# Headphone Bass Equalization: Evidence-Based Engineering Practice (Targets, Filters, Headroom, Loudness)

**Methodology Note:** Harman target curve figures were derived by calculating differential offsets between AutoEq standardized CSV curves ("Harman over-ear 2018.csv" minus "Harman over-ear 2018 without bass.csv", etc.). Equal-loudness level metrics were evaluated using the ISO 226:2003 acoustic formulation (matching MathWorks and `pydsm` coefficient implementations).

---

## 1. Harman Over-Ear Target (2018) & Bass Preference Distribution

### Key Takeaway
The Harman 2018 Over-Ear target incorporates a built-in bass shelf of **+6.0 dB centered at 105 Hz with Q ≈ 0.7**. Across the acoustic spectrum, this delivers +3.0 dB at 105 Hz, +4.4 dB at 80 Hz, and +5.7 to +6.0 dB below 50 Hz, with near-zero elevation above 200 Hz. In Harman listener clustering studies, the "More Bass Is Better" subgroup (approximately 15% of listeners, predominantly younger males) preferred **+3.0 to +6.0 dB above the baseline target below 300 Hz**, translating to an effective +9.0 to +12.0 dB total low-shelf envelope.

### Cited Findings
- **Harman OE2018 Bass Shelf (Calculated Delta):**
  - 20 Hz: +6.0 dB
  - 30 Hz: +6.0 dB
  - 50 Hz: +5.7 dB
  - 80 Hz: +4.4 dB
  - 105 Hz: +3.0 dB
  - 150 Hz: +1.2 dB
  - 200 Hz: +0.4 dB
  - 300 Hz: +0.1 dB
  *(Matches standard Butterworth low-shelf: Gain = +6 dB, Fc = 105 Hz, Q ≈ 0.7)* — [AutoEq Targets](https://github.com/jaakkopasanen/AutoEq/tree/master/targets)
- **Harman Listener Clustering Demographics:**
  - *Harman Target Baseline:* 64% of listener cohorts.
  - *More Bass Is Better:* 15% of listener cohorts (+3 to +6 dB below 300 Hz, +1 dB above 1 kHz; 4:1 male-skewed).
  - *Less Bass Is Better:* 21% of listener cohorts (−2 to −3 dB in low frequencies; older demographics and female-skewed; contains zero trained listeners). — [SoundStage Solo](https://mail.soundstagesolo.com/index.php/features/217-where-are-we-at-with-the-harman-curve); [GRAS/Harman Case Study](https://www.grasacoustics.com/fileadmin-gras/Images/Consumer_Audio/Household_Appliances/GRAS_Case_Harman_Final_02182021pdf.pdf); [Olive, Acoustics Today](https://acousticstoday.org/issues/2022AT/Spring2022/files/basic-html/page66.html)
- **Corner Frequency Rationale:** Dr. Sean Olive selected 105 Hz because standard studio subwoofers cross over near or slightly below this frequency. Moving the low-shelf cutoff above 105 Hz compromises vocal fundamentals and lower-midrange timbre. — [PEQdB White Paper](https://peqdb.com/wiki/PEQdB-White-Paper.pdf)

---

## 2. Common Elevated-Bass Target Variations

- **Harman In-Ear 2019:** Features a steeper +9.0 dB shelf (+9.0 dB at 20 Hz, +4.5 dB at 105 Hz) designed to compensate for lack of tactile chest resonance in IEMs.
- **Crinacle IEF Preference (2025 Revision):** 
  - On the B&K 5128 fixture, Crinacle lowered the shelf corner from 105 Hz down to **80 Hz (Q = 0.71, +10 dB)**. Lowering the corner frequency preserves dynamic sub-bass slam while eliminating upper-bass chestiness and bloat. — [Crinacle 2025 IEF Target](https://crinacle.com/2025/02/05/the-new-2025-ief-target/)
- **Oratory1990 Optimum HiFi:** Neutral baseline providing approximately 5 dB less bass than Harman OE2018 (−5.5 dB at 20 Hz relative to Harman).

---

## 3. Sub-Bass vs. Mid-Bass: Controlling Muddiness (200–400 Hz)

### Key Takeaway
Visceral low-frequency punch without muddiness requires isolating boost energy below 80–100 Hz. Resonant bloom and vocal masking originate between 100 Hz and 250 Hz.
- An 80–105 Hz low-shelf (Q = 0.7) adds merely +0.4 dB at 200 Hz and +0.1 dB at 300 Hz, completely bypassing the muddiness band.
- Audio engineering mix conventions consistently identify 200–500 Hz as the primary source of mix congestion, frequently applying wide parametric cuts (−2 to −4 dB, Q = 0.7–1.0) on kick drums and bass guitars. — [Violet Recording](https://violetrecording.com/how-to-fix-muddy-low-end/)
- **Upward Spread of Masking:** High-SPL low-frequency fundamentals broaden their psychoacoustic masking curves upward into higher octaves. A bloated 150 Hz peak severely masks clarity in the 500 Hz to 2 kHz vocal band. — [QSC Auditory Masking](https://blogs.qsc.com/live-sound/auditory-masking-and-its-effect-on-our-perception-of-sound/)
- **Presence Definition (2–5 kHz):** Transient kick attack and transient definition reside between 2 kHz and 5 kHz. Pairing low-frequency shelves with mild presence retention prevents soundstage dullness.

---

## 4. Filter Topologies, Q Factors, and Infrasonic Limiting

- **Low-Shelf vs. Peaking:** Standard practice dictates a Butterworth low-shelf (Q ≈ 0.71) at 60–80 Hz. Unlike low-Q bell curves centered at 30 Hz (which continuously escalate downward), a Butterworth shelf flattens below 40 Hz, preventing infinite gain escalation.
- **Driver Excursion Safeguards:** Boosting sub-bass on dynamic driver headphones dramatically increases diaphragm excursion, risking magnetic gap bottoming and voice-coil heating. Adding a high-pass Butterworth filter at **18 Hz (12 dB/oct)** attenuates inaudible DC subsonic rumble without degrading perceived 30–40 Hz punch. — [USPTO 10818310](https://image-ppubs.uspto.gov/dirsearch-public/print/downloadPdf/10818310)

---

## 5. ISO 226 Equal-Loudness Contours & Listening Levels

Human auditory perception compresses dynamic range in low frequencies as volume drops. Evaluating ISO 226:2003 equal-loudness contours indicates:

| Playback Level Transition | 20 Hz Boost | 31.5 Hz Boost | 50 Hz Boost | 100 Hz Boost | 200 Hz Boost |
|---|---|---|---|---|---|
| **80 phon → 60 phon** (Quiet Listening) | +10.5 dB | +9.4 dB | +8.2 dB | +6.2 dB | +3.9 dB |
| **85 phon → 70 phon** (Moderate Listening) | +7.9 dB | +7.1 dB | +6.2 dB | +4.7 dB | +3.0 dB |

A static low-shelf boost of +6 to +8 dB below 60 Hz naturally replicates the 85 → 70 phon ISO loudness compensation curve for typical desktop listening levels.

---

## 6. Preamp Gain Normalization and Limiter Stages

1. **Digital Headroom Preamp:** The digital preamp attenuation must match the cumulative peak gain of the EQ curve:
   $$\text{Preamp Gain} = - \max(\text{Total Cumulative EQ Gain})$$
   Setting a −7.0 to −10.0 dB digital preamp completely eliminates digital clipping across DAC stages.
2. **Safety Limiter:** Placed at the end of the DSP chain as an inter-sample peak safety barrier:
   - **Ceiling:** −1.0 dBTP (True Peak).
   - **Lookahead:** 2.0 ms.
   - **Release:** 100–200 ms (rapid releases below 40 ms directly distort low-frequency waveforms).
   - **Gain Reduction Target:** 0 dB under normal listening, catching only extreme mastering transients.
