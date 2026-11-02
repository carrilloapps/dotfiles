# macOS-Style System Utilities for CachyOS / KDE Plasma 6 (Wayland): Evaluation and Parity Matrix

**System Baseline:** Arch Linux / CachyOS, KDE Plasma 6 Wayland session, native package archives (`extra`, `cachyos-extra-v3`, AUR), `xdg-desktop-portal-kde` active.

---

## 1. Recommendations and macOS Parity Analysis

### Key Takeaway
Preserve the vast majority of KDE core system management tools: **Dolphin** (Finder), **Ark** (Archive Utility), **Partition Manager** (Disk Utility), **KInfoCenter** (System Information), **KWallet** (Keychain backend), and **Btrfs Assistant / Snapper** (System rollback snapshots). These utilities integrate deeply with Wayland and KIO, surpassing GNOME equivalents in performance and feature depth. 

Selectively adopt GTK4/libadwaita utilities only where they deliver significant visual elegance without sacrificing functionality: **Mission Center** (Activity Monitor), **Pika Backup** (Time Machine user data backups to external drives), **GNOME Calculator** / **Qalculate!**, and **virt-manager / GNOME Boxes** (virtualization via native KVM).

---

## 2. Detailed Utility Findings

### File Manager — Apple Finder
- **Dolphin (RETAIN):** Unmatched multi-tabbing, dual-pane file management (F3), integrated terminal drawer (`F4`), KIO network protocols, and robust context menu extensibility. Enhanced with `dolphin-plugins`, `kio-extras`, `ffmpegthumbs`, and `kdegraphics-thumbnailers`.
- **Nautilus (REJECT):** Pulls `xdg-desktop-portal-gnome`, disrupting global KDE file picker dialogues and causing occasional Wayland compositor disconnections in Plasma sessions.
- **Quick Look in Dolphin:** Dolphin lacks a spacebar-triggered popup preview. Community tools like Kiview remain incomplete; the proven macOS-like approach is enabling Dolphin's Information Panel (`F11`) with rich thumbnail generators.

### Activity Monitoring — Apple Activity Monitor
- **Mission Center (ADOPT):** Modern GTK4/Rust performance monitor featuring per-core CPU usage graphs, GPU utilization tracking, real-time battery charge/discharge rates, and per-process memory hierarchies.
- **btop (RETAIN):** Lightweight terminal-based system monitor styled with RedRog's `neongrid` color scheme.

### Archiving — Apple Archive Utility
- **Ark (RETAIN):** Native Qt6 archive utility supporting 7z, tar, zstd, and zip with seamless drag-and-drop extraction in Dolphin.

### Disk Management — Apple Disk Utility
- **KDE Partition Manager (RETAIN):** Advanced partition editor supporting Btrfs subvolumes, ext4, swap, and NVMe sector alignment.
- **GNOME Disks (OPTIONAL):** Slower release cadence; retained purely as an optional secondary GUI for quick ISO flashing.

### Storage Visualization — Apple Storage / DaisyDisk
- **Filelight (RETAIN):** Fast multi-threaded sunburst disk visualization integrated into Dolphin.
- **Baobab (OPTIONAL):** Clean GNOME disk analyzer alternative.

### System Rollback & Backups — Apple Time Machine
- **Btrfs Assistant + Snapper (RETAIN):** Instant, atomic copy-on-write system snapshots integrated into the Limine bootloader menu for bare-metal boot rollback.
- **Pika Backup (ADOPT):** Scheduled, encrypted hourly/daily incremental backups of `/home` to external drives via Borg, replicating Apple Time Machine's user-file backup workflow.

### Virtualization — Apple Parallels / UTM
- **GNOME Boxes / virt-manager (ADOPT):** Native Linux KVM hypervisor frontend providing near-native guest performance without requiring out-of-tree kernel DKMS compilation delays (avoiding VirtualBox host driver breakage across rolling-release kernels).
- **WinBoat:** Containerized Windows VM environment running under Docker via FreeRDP RemoteApp.
