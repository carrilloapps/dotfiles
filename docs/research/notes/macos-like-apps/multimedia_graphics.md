# macOS-Style Multimedia and Graphics Applications (CachyOS + KDE Plasma 6 Wayland)

**Hardware & Architecture Context:** Hybrid graphics (NVIDIA discrete GPU + Intel Iris Xe integrated GPU), PipeWire audio backend, native Arch/CachyOS package databases.

---

## 1. Recommendations and macOS Parity Matrix

### Key Takeaway
Adopt GNOME/GTK4 alternatives only where a mature, distinct Apple-like counterpart exists: **Showtime** (QuickTime Player), **Gapless / Amberol** (Local Apple Music player), **pwvucontrol** (Sound settings panel), **Snapshot** (Photo Booth), **Decibels** (Voice Memos), and **Gradia** (Quick markup). Preserve native KDE tools where performance and Wayland integration are paramount: Spectacle for screen captures, and pro-audio/video suites (OBS Studio, DaVinci Resolve, Audacity, EasyEffects).

---

## 2. Detailed Multimedia Findings

### Video Playback — macOS QuickTime Player
- **Showtime:** Default GNOME video player (GTK4 + GStreamer with hardware decoding). Features auto-hiding floating controls, gestures, and minimal window borders matching modern macOS QuickTime.
- **Haruna:** Maintained as a secondary power-user video player (Qt/Kirigami over libmpv) with hardware-accelerated subtitle rendering.
- **mpv:** CLI powerhouse retained for scriptable playback and high-bitrate testing.

### Local Audio Library — Apple Music
- **Gapless (formerly G4Music):** Fast GTK4 local music player with blurred album artwork backdrops, gapless playback, ReplayGain, and MPRIS integration.
- **Amberol:** Lightweight GNOME Circle audio player designed for simple drag-and-drop playlist listening with dynamic background color extraction.
- **Spotify:** Managed via `spotify-launcher` for cloud streaming.

### Audio Routing & Monitoring — Sound System Preferences
- **pwvucontrol:** PipeWire-native volume control written in Rust and GTK4/libadwaita. Lightweight, responsive replacement for legacy `pavucontrol`.
- **EasyEffects:** Retained as the system DSP engine for speaker correction, microphone noise suppression (RNNoise), and calibrated bass loudness.

### Screen Capture & Markup — macOS Screenshot & Preview
- **Spectacle:** The premier screen capture tool on KDE Wayland. Supports rectangular selection, window capture, active screen recording, canvas annotations, and on-the-fly OCR text recognition.
- **Gradia / Satty:** Auxiliary markup tools for rapid directional arrows, number callouts, and pixelation redaction.

### Photo Inspection & Management — Apple Photos
- **Koko:** Fast Kirigami photo viewer with folder organization, metadata inspection, and clean grid layouts.
- **Loupe:** Default GNOME image viewer (GTK4/Rust), providing smooth GPU-accelerated panning and zoom gestures.
