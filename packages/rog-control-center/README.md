# rog-control-center-redrog

ROG Control Center (from [asusctl](https://github.com/OpenGamingCollective/asusctl),
MPL-2.0) built with the RedRog look. Same source and checksum as Arch's
`asusctl` package; `redrog-theme.py` changes only the Slint UI before building:

- Glass: translucent window and cards, so KWin's blur (Better Blur DX) shows
  through, with crisp text. The KWin script `redrog-menu-placement` makes the
  blur reach the window as soon as it opens.
- `sidebar.slint`: a macOS-style source list with icons (`icons/`), a red glass
  pill on the active page, section titles and the ROG brand.
- `rr.slint`: modern controls with the same API as Slint's (button, switch,
  checkbox, slider, drop-down, text field, segmented control, group box,
  section title, icon button); Cupertino style for the rest.
- `fans.py`: the fan curves page with segmented controls instead of nested tabs.
- `colour_picker.slint`: Aura colours with a large preview, presets and
  rounded hue, saturation and brightness tracks.
- Spanish from `i18n/rog-control-center/es.po`, and an "RedRog edition" note
  in About.

Build and install (takes a few minutes, Rust with LTO):

```bash
cd packages/rog-control-center && makepkg -si
```

When asusctl updates, bump `pkgver` and `sha256sums` to match Arch's PKGBUILD
and rebuild; the theme script re-applies itself.
