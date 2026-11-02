#!/usr/bin/env python3
"""Unpacks Arc's gtk.gresource into plain files so they can be recolored
(recolor.py works on text and PNG, not on the compiled bundle).

For each gtk-*/gtk.gresource in SOURCE, writes into DEST/gtk-*/ the CSS and
images it contains, with relative paths instead of resource:// URLs.
Usage: gtk-unpack.py SOURCE DEST
"""
import sys
from pathlib import Path

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio  # noqa: E402

src, dst = map(Path, sys.argv[1:3])
PREFIX = "/org/gnome/arc-theme/"


def walk(res, path):
    for name in res.enumerate_children(path, Gio.ResourceLookupFlags.NONE):
        child = path + name
        if name.endswith("/"):
            yield from walk(res, child)
        else:
            yield child


for gres in sorted(src.glob("gtk-*/gtk.gresource")):
    out_dir = dst / gres.parent.name
    res = Gio.Resource.load(str(gres))
    count = 0
    for rpath in walk(res, PREFIX):
        data = res.lookup_data(rpath, Gio.ResourceLookupFlags.NONE).get_data()
        rel = rpath[len(PREFIX):]
        if rel.endswith(".css"):
            data = data.replace(b"resource://" + PREFIX.encode(), b"")
        target = out_dir / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        count += 1
    print(f"{gres.parent.name}: {count} files extracted")
