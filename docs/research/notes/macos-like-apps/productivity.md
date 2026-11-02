# Productivity and Personal Information Management: macOS-Style Applications for CachyOS / KDE Plasma 6 (Wayland)

**System Baseline:** Arch Linux / CachyOS, KDE Plasma 6 Wayland session, native package archives (`extra`, `cachyos-extra-v3`, AUR).

---

## 1. Recommendations and macOS Parity Analysis

### Key Takeaway
Modern open-source desktop ecosystems provide robust, mature equivalents for almost every macOS productivity utility. The closest Apple-aligned applications (GTK4/libadwaita and GNOME Circle) include **Papers** (Preview), **Planify** (Reminders), **GNOME Clocks / Weather / Maps**, **Iotas** (Notes), **Secrets** (Keychain), **Rnote** (Freeform), and **Dialect** (Translate). For email, **Thunderbird** remains the premier full-featured suite. In office productivity, **ONLYOFFICE** maintains the highest fidelity with Microsoft OOXML formats, while **LibreOffice** provides native Qt integration on KDE Plasma.

---

## 2. Category-by-Category Findings

### Office Suite — Apple iWork (Pages / Numbers / Keynote)
- **ONLYOFFICE Desktop Editors:** Packaged via `onlyoffice-bin`. Features near-flawless OOXML file rendering, integrated tabbed editing, and AI agent extensions via MCP servers.
- **LibreOffice:** Packaged as `libreoffice-fresh`. Employs Qt-native widget rendering in KDE Plasma with customizable Notebookbar layouts.

### Document Inspection (PDF) — Apple Preview
- **Papers:** Modern GNOME Core document viewer replacing legacy Evince. Clean, high-performance GTK4 rendering with text search and annotation capabilities.
- **Okular:** Preserved as a specialized technical viewer for digital cryptographic signatures and form fill-in.

### Notes — Apple Notes
- **Iotas:** Clean, distraction-free markdown note manager written in GTK4. Integrates seamlessly with SQLite local storage and optional Nextcloud Notes REST API synchronization.
- **Folio:** Notebook-based markdown editor featuring live previews and search indexing.
- **Obsidian / Joplin:** Power-user alternatives for extensive knowledge graphs and end-to-end encrypted personal wikis.

### Task Management — Apple Reminders
- **Planify:** Full-featured task and project manager matching Apple Reminders geometry. Supports Todoist, Nextcloud Tasks, subtasks, tags, recurring reminders, and time blocking.
- **Errands:** Minimalist GTK4 checklist manager for quick daily to-do lists.

### Calendar & Contacts — Apple Calendar & Contacts
- **Thunderbird:** Unified messaging, CalDAV calendar, and CardDAV contact management without forcing GNOME Online Accounts or pulling `xdg-desktop-portal-gnome`.
- **GNOME Calendar / Contacts:** Clean visual stand-ins for local, single-user schedules.

### Vector Sketching & Whiteboarding — Apple Freeform
- **Rnote:** Vector-based sketching and note-taking application designed for digital pens and touchscreens. Smooth ink engine with PDF import, infinite canvas, and shape smoothing.
- **Xournal++:** Retained for technical academic PDF markup and mathematical formulas.

### Password Management — Apple Keychain / Passwords
- **Secrets:** Clean GTK4 password manager utilizing standard KeePass (KDBX v4) encryption.
- **KeePassXC:** Full-featured cross-platform credential safe with browser integration and auto-type.
- **Bitwarden / Proton Pass:** Cloud-synchronized alternatives with iOS/macOS cross-device parity.

### Translation — Apple Translate
- **Dialect:** GTK4 translation utility connecting to LibreTranslate, Google Translate, and offline translation models.
