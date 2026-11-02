# kwin-effect-redrog-glass

A small KWin effect for RedRog. KDE apps such as System Settings, Discover,
System Monitor, Info Center and EasyEffects paint an opaque background, so the only way to
make them translucent was a KWin opacity rule, which also fades the title bar:
title bar and content never matched. This effect makes only the **content**
translucent (at the title bar's opacity, 77 %), so with the blur behind it
the whole window is one glass like Dolphin or kitty, in the foreground and in
the background. KWin 6.8 ignores blur asked by another effect, so the blur
itself comes from Better Blur DX, which `modules/plasma-style` points at the
same apps.

Settings in `kwinrc`, group `[Effect-redrogglass]`: `WindowClasses` (one per
line) and `Opacity` (percent). `modules/window-decoration` enables it when the
package is installed.

```bash
cd packages/kwin-effect-redrog-glass && makepkg -si
```

A KWin effect only loads in the KWin it was built for. The package installs
its sources in `/usr/src/kwin-effect-redrog-glass` and a pacman hook that
rebuilds it by itself after every KWin update; if that build fails the effect
is removed (those apps turn opaque, nothing breaks) until the package is
rebuilt with `./install.sh --packages`.
