# Host: ASUS TUF Gaming F15 (FX507ZC4)

i5-12500H, RTX 3050 Laptop, Iris Xe, CachyOS, KDE Plasma 6 (Wayland),
Limine.

This directory keeps the machine-specific setup that is not part of the RedRog
theme: `asusd` power limits and fan curves per profile, an 80 % charge limit,
the Armoury Crate key opening ROG Control Center, clock and locale tweaks, and
selected system files. `manifest.txt` lists every captured path.

```bash
scripts/capture.sh    # copy the current configuration into home/ and system/
scripts/restore.sh    # put it back (system files ask for sudo)
```

Power profiles (`system/etc/asusd/asusd.ron`), within the firmware limits
(CPU PL1 28-90 W, PL2 28-135 W, Dynamic Boost 5-15 W):

| Profile | On AC: PL1 / PL2 / Boost | On battery | Use |
|---|---|---|---|
| Quiet | 30 / 45 / 5 W | 28 / 40 / 5 W | Office, browsing; fans off below 55 °C |
| Balanced | 55 / 95 / 10 W | 35 / 55 / 5 W | Everyday work, light games |
| Performance | 80 / 115 / 15 W | 45 / 70 / 10 W | Games, rendering, compiling |

```bash
sudo scripts/apply-asusd.sh   # install them (asusd is restarted)
```

Hybrid graphics: `home/.local/bin/Xwayland` makes Xwayland use only the
Intel GPU, so the RTX 3050 sleeps until a game or app asks for it (Xwayland
would otherwise keep it awake all session). Installed by `scripts/restore.sh`.

Do not apply it to a different model: power limits and fan curves are specific
to this hardware.

`scripts/apply-asusd.sh` checks the model first and refuses to run on another
laptop. The generic parts (the NVIDIA card sleeping on hybrid graphics, the
Armoury Crate key) are also installed for any ASUS laptop by
`modules/asus-laptop`.
