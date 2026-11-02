# kwin-effects-better-blur-dx

The AUR package of Better Blur DX (blur forced for the QML glass apps: System
Settings, System Monitor, Discover, EasyEffects...), plus its sources in
`/usr/src` and a pacman hook that rebuilds it after every KWin update. A KWin
effect only loads in the exact KWin it was built for: after KWin 6.8.0 ->
6.8.1 those apps stayed translucent without blur until it was rebuilt.
