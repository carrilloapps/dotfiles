# plasma6-applets-appgrid (Plasma 6.8 patch)

Based on the AUR `plasma6-applets-appgrid` 1.9.3 PKGBUILD. Plasma 6.8 removed
`Plasma::Applet::globalConfig()`; `plasma68-globalconfig.patch.py` adds an
equivalent helper (the `AppletGlobals/<plugin id>` group in the Corona config,
the same logic Plasma used). Switch back to the AUR package once upstream
releases a Plasma 6.8 compatible version.
