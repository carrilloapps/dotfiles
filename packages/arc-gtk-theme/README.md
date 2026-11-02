# arc-gtk-theme-git (fixed)

Based on the AUR `arc-gtk-theme-git` PKGBUILD. Changes:

- Builds only the GTK2/3/4 themes. The original also builds GNOME Shell 45 and
  Cinnamon 6.0 and fails because that folder no longer exists upstream.
- Builds serially (`-j 1`): Inkscape crashes when exporting in parallel (D-Bus clash).
