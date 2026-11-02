---
name: artcraft
description: Controls ArtCraft suite apps (PhotoCraft, VectorCraft, FilmCraft, LightCraft, PdfCraft, EffectCraft, DesignCraft, FigCraft, SoundCraft, WordCraft, GridCraft, DeckCraft, SolidCraft) via their MCP servers to edit photos, vectors, video, RAW development, PDF, motion graphics, publishing layout, UI design, audio, documents, spreadsheets, presentations, and parametric 3D CAD modeling. Use whenever the user requests creating, editing, converting, or exporting these file formats, or controlling any of these apps.
metadata:
  icon: 🎨
---

# ArtCraft Suite

Each Craft application provides an MCP server under its name (`photocraft`, `vectorcraft`, `filmcraft`,
`lightcraft`, `pdfcraft`, `effectcraft`, `designcraft`, `figcraft`, `soundcraft`, `wordcraft`,
`gridcraft`, `deckcraft`, `solidcraft`). All are launched via `~/.local/bin/artcraft-mcp <app>`.

| Task | Server |
|---|---|
| Photos, layers, PSD, retouching | photocraft |
| Vector illustration, SVG, AI | vectorcraft |
| Video editing, color grading, audio sync | filmcraft |
| Photo catalog and RAW development | lightcraft |
| Read, edit, merge, sign PDF | pdfcraft |
| Motion graphics and visual effects | effectcraft |
| Publication layout and typesetting | designcraft |
| UI/UX design (Figma-style) | figcraft |
| Audio recording, editing, and mixing | soundcraft |
| Word processing documents (DOCX, ODT) | wordcraft |
| Spreadsheets (XLSX, CSV) | gridcraft |
| Presentations (PPTX) | deckcraft |
| Parametric 3D CAD (sketches, extrusions, STEP, STL) | solidcraft |

## Two Operating Modes

- **App Open:** If the application window is running when the client starts the MCP server, the server attaches to that live window (via the local control port of each application) and the user observes all mutations in real time. Additional UI control tools become available (screenshots, clicks, keypresses).
- **Headless (No Window):** Otherwise, the application engine runs headlessly in the background, with file system access restricted to the user's home directory.

If the user launches the application after the session starts, the server remains in headless mode until reconnected (`/mcp` → reconnect in the agent client). To work live interactively, prompt the user to launch the app beforehand, or launch it directly via `gtk-launch ai.storyteller.<app>` (for SolidCraft: `gtk-launch io.tangencylabs.solidcraft`) and reconnect the server.

## Best Practices

- Validate paths before passing them to file tools: relative paths are resolved against the active working directory.
- For batch mutations or multi-command sequences, favor the `batch` tool on supported servers to minimize round-trip latency.
- In headless mode, always save explicitly via `save_document` / `save_project` or an equivalent export tool; no implicit autosave runs in headless mode.
