#!/usr/bin/env python3
"""Performance settings of the Craft apps sized for this machine.

Usage: tune.py

The apps ship with budgets meant for small machines (PhotoCraft 8 GB of
memory and a 768 MB effect cache, FilmCraft and EffectCraft 768 MB-3 GB of
frame caches) and some fall back to slower paths on their own after a start
that did not finish (LightCraft turns GPU rendering off, documented to trip
falsely when the app is closed while it starts). From the machine's memory:

- PhotoCraft: half the RAM for documents, a 4 GB effect cache, 100 history
  states, 6 cache levels, GPU on with 75 % of the graphics memory, and the system title bar (RedRog's
  traffic lights like the other Craft apps, not its own buttons).
- FilmCraft: 4 GB frame cache, 12 GB kept free, multithreaded waveforms,
  hardware decoding.
- EffectCraft: 4 GB layer and footage caches, a RAM preview of a quarter of
  the RAM, 12 GB kept free, frames cached while idle.
- LightCraft: GPU rendering on.

Values are only raised (a larger budget set by hand stays), and a file is
changed only while its app is closed (the apps save their settings when they
quit). Prints what changed.
"""
import json
import os
import subprocess

HOME = os.path.expanduser("~")
CONFIG = os.environ.get("XDG_CONFIG_HOME", HOME + "/.config")
DATA = os.environ.get("XDG_DATA_HOME", HOME + "/.local/share")
RAM_MB = os.sysconf("SC_PAGE_SIZE") * os.sysconf("SC_PHYS_PAGES") // 2**20
try:
    VRAM_MB = int(subprocess.run(["nvidia-smi", "--query-gpu=memory.total", "--format=csv,noheader,nounits"],
                                 capture_output=True, text=True, timeout=10).stdout.split()[0])
except (OSError, ValueError, IndexError, subprocess.SubprocessError):
    VRAM_MB = 0
BIG = RAM_MB >= 30000   # 32 GB machines and up


def running(app):
    return subprocess.run(["pgrep", "-x", app[:15]], capture_output=True).returncode == 0


def tune(app, path, changes):
    """changes: [(dotted key, value, "max" | "set")]"""
    if not os.path.isfile(path):
        return
    if running(app):
        print(f"{app}: open, left for the next run")
        return
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    done = []
    for key, value, how in changes:
        *parents, leaf = key.split(".")
        node = data
        for p in parents:
            node = node.setdefault(p, {})
        old = node.get(leaf)
        if how == "max" and isinstance(old, (int, float)) and not isinstance(old, bool) and old >= value:
            continue
        if old == value:
            continue
        node[leaf] = value
        done.append(f"{key} {old} → {value}")
    if done:
        tmp = path + ".redrog-tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, ensure_ascii=False)
        os.replace(tmp, path)
        print(f"{app}: " + "; ".join(done))


tune("photocraft", f"{CONFIG}/photocraft/preferences.json", [
    ("performance.memoryUsageMb", RAM_MB // 2, "max"),
    ("performance.effectCacheMb", 4096 if BIG else 1536, "max"),
    ("performance.historyStates", 100, "max"),
    ("performance.cacheLevels", 6, "max"),
    ("performance.useGpu", True, "set"),
    # three quarters of the graphics memory (0 = the app decides)
    ("performance.gpuMemoryMb", VRAM_MB * 3 // 4, "set"),
    # the system title bar: RedRog's traffic lights, as in the rest of the
    # suite, instead of its own ✕ – □ buttons
    ("interface.systemTitleBar", True, "set"),
])
tune("filmcraft", f"{DATA}/filmcraft/preferences.json", [
    ("memory.frameCacheMb", 4096 if BIG else 1536, "max"),
    ("memory.ramReservedGb", 12 if BIG else 4, "set"),
    ("audio.multithreadedWaveforms", True, "set"),
    ("media.hardwareDecoding", True, "set"),
])
tune("effectcraft", f"{CONFIG}/effectcraft/prefs.json", [
    ("memory.layerCacheMb", 4096 if BIG else 1024, "max"),
    ("memory.mediaCacheMb", 4096 if BIG else 1024, "max"),
    ("memory.previewCacheMb", RAM_MB // 4, "max"),
    ("memory.ramReservedGb", 12 if BIG else 6, "set"),
    ("previews.cacheFramesWhenIdle", True, "set"),
])
tune("lightcraft", f"{CONFIG}/lightcraft/ui.json", [
    ("settings.gpu", True, "set"),
])
