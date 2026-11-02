# plasma6-applets-supergfxctl

The GPU mode widget (supergfxctl) for the top bar, built here against the
installed Plasma. CachyOS's binary package was built against libPlasma.so.7
and stopped loading on Plasma 6.8 (libPlasma.so.8): "the package format is
invalid (no metadata)". pkgrel 3 so it stays ahead of that package.
If a Plasma update breaks it again, rebuild it: ./install.sh --packages

RedRog look (redrog/): the popup redone in the style of the macOS Control
Center (header with the mode and the dedicated GPU's power, rounded rows,
the current mode as an accent pill with a check, an action pill on the
others), line icons in the text color with an accent dot when the dedicated
GPU is on, and a Spanish translation.
