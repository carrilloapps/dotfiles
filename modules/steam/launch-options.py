#!/usr/bin/env python3
"""RedRog (modules/steam): gives every installed Steam game without launch
options of its own the RedRog ones (NVIDIA GPU, performance profile).
Tools (Proton, runtimes, redistributables) are skipped. Run with Steam
closed: it rewrites localconfig.vdf when it quits."""
import glob, os, re, vdf

OPTS = ("__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only "
        "__GLX_VENDOR_LIBRARY_NAME=nvidia %command%")
# Earlier RedRog options, replaced by the current ones: game-performance went
# through power-profiles-daemon, which put the profile back to Balanced when
# the game closed, fighting asusd (the ASUS profile is the gaming mode)
OLD = {"__NV_PRIME_RENDER_OFFLOAD=1 __VK_LAYER_NV_optimus=NVIDIA_only "
       "__GLX_VENDOR_LIBRARY_NAME=nvidia game-performance %command%"}
TOOLS = re.compile(r"Proton|Steam Linux Runtime|Steamworks|Redistributable|SteamVR|Steam Play", re.I)
steam = os.path.expanduser("~/.local/share/Steam")

libraries = [steam]
lf = os.path.join(steam, "config/libraryfolders.vdf")
if os.path.exists(lf):
    for entry in vdf.load(open(lf, encoding="utf-8")).get("libraryfolders", {}).values():
        if isinstance(entry, dict) and entry.get("path"):
            libraries.append(entry["path"])
games = {}
for lib in set(libraries):
    for acf in glob.glob(os.path.join(lib, "steamapps/appmanifest_*.acf")):
        state = vdf.load(open(acf, encoding="utf-8")).get("AppState", {})
        if state.get("appid") and not TOOLS.search(state.get("name", "")):
            games[state["appid"]] = state.get("name", "")

for cfg in glob.glob(os.path.join(steam, "userdata/*/config/localconfig.vdf")):
    d = vdf.load(open(cfg, encoding="utf-8"), mapper=vdf.VDFDict)
    root = d["UserLocalConfigStore"]
    soft = root.get("Software") or root.get("software")
    apps = soft["Valve"]["Steam"]["apps"] if "Valve" in soft else soft["valve"]["steam"]["apps"]
    changed = []
    for appid, name in games.items():
        if appid not in apps:
            apps[appid] = vdf.VDFDict()
        if not apps[appid].get("LaunchOptions") or apps[appid].get("LaunchOptions") in OLD:
            apps[appid]["LaunchOptions"] = OPTS
            changed.append(name)
    if changed:
        os.replace(cfg, cfg + ".before-redrog") if not os.path.exists(cfg + ".before-redrog") else None
        vdf.dump(d, open(cfg, "w", encoding="utf-8"), pretty=True)
        print("launch options:", ", ".join(changed))
