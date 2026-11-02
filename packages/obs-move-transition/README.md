# obs-move-transition

The AUR PKGBUILD, building with `CMAKE_COMPILE_WARNING_AS_ERROR=OFF`: OBS 32
marks `obs_properties_add_button` as deprecated (it still works) and the
plugin's build treats that warning as an error, so the AUR package fails.
