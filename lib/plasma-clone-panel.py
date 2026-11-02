#!/usr/bin/env python3
"""Gives every screen a copy of the top bar of the main screen.

Usage: plasma-clone-panel.py APPLETSRC PLASMASHELLRC SCREENS

Plasma keeps panels per screen and its scripting API cannot place a new panel
on a given screen, so the top bar (plugin org.kde.panel at the top edge) of
screen 0 is copied in Plasma's own files for each screen from 1 to SCREENS-1
that has no top bar yet: the panel, its widgets and the system tray inside it,
with new ids (and the references to them: widget order, Panel Colorizer's
lists), on that screen. The copy has no global shortcuts (the launcher's
Alt+F1 stays on the main screen's bar). The dock (bottom panel) is not copied.
Plasma must not be running while the files change. Prints how many bars were
added.
"""
import re
import sys

HEADER = re.compile(r"^\[(.+)\]$")


def read_groups(path):
    """[(header, [lines])], keeping the file's order"""
    groups, current = [], (None, [])
    try:
        lines = open(path, encoding="utf-8").read().split("\n")
    except FileNotFoundError:
        lines = []
    for line in lines:
        if HEADER.match(line):
            groups.append(current)
            current = (line, [])
        else:
            current[1].append(line)
    groups.append(current)
    return groups


def write_groups(path, groups):
    out = []
    for header, lines in groups:
        if header is not None:
            out.append(header)
        out.extend(lines)
    open(path, "w", encoding="utf-8").write("\n".join(out))


def value(lines, key):
    for line in lines:
        if line.startswith(key + "="):
            return line.split("=", 1)[1]
    return None


def main():
    appletsrc, shellrc, screens = sys.argv[1], sys.argv[2], int(sys.argv[3])
    groups = read_groups(appletsrc)
    top = {}   # containment id -> lastScreen
    for header, lines in groups:
        m = header and re.match(r"^\[Containments\]\[(\d+)\]$", header)
        if m and value(lines, "plugin") == "org.kde.panel" and value(lines, "location") == "3":
            top[m.group(1)] = int(value(lines, "lastScreen") or 0)
    source = next((c for c, s in top.items() if s == 0), None)
    missing = [s for s in range(1, screens) if s not in top.values()]
    if source is None or not missing:
        print(0)
        return
    used = {int(n) for h, _ in groups if h for n in re.findall(r"\]\[(\d+)\]", h)}
    used |= {int(n) for h, _ in groups if h for n in re.findall(r"^\[Containments\]\[(\d+)\]", h)}
    next_id = max(used) + 1
    prefix = "[Containments][%s]" % source
    subtree = [(h, l) for h, l in groups if h and (h == prefix or h.startswith(prefix + "["))]
    old_ids = [source] + sorted({n for h, _ in subtree for n in re.findall(r"\[Applets\]\[(\d+)\]", h)}, key=int)
    shell = read_groups(shellrc)
    added = 0
    for screen in missing:
        ids = {}
        for old in old_ids:
            ids[old] = str(next_id)
            next_id += 1
        def renumber_header(h):
            h = h.replace("[Containments][%s]" % source, "[Containments][%s]" % ids[source], 1)
            return re.sub(r"\[Applets\]\[(\d+)\]", lambda m: "[Applets][%s]" % ids.get(m.group(1), m.group(1)), h)
        def renumber_value(line):
            line = re.sub(r'"id":(\d+)', lambda m: '"id":%s' % ids.get(m.group(1), m.group(1)), line)
            if line.startswith("AppletOrder="):
                line = "AppletOrder=" + ";".join(ids.get(i, i) for i in line.split("=", 1)[1].split(";"))
            return line
        for h, lines in subtree:
            if h.endswith("[Configuration][Shortcuts]"):
                continue   # no duplicate global shortcuts
            nh = renumber_header(h)
            nl = [renumber_value(x) for x in lines]
            if h == prefix:
                nl = ["lastScreen=%d" % screen if x.startswith("lastScreen=") else x for x in nl]
            groups.append((nh, nl))
        # the panel's size and other view settings
        for h, lines in list(shell):
            if h and (h == "[PlasmaViews][Panel %s]" % source or h.startswith("[PlasmaViews][Panel %s][" % source)):
                shell.append((h.replace("[Panel %s]" % source, "[Panel %s]" % ids[source], 1), list(lines)))
        added += 1
    write_groups(appletsrc, groups)
    write_groups(shellrc, shell)
    print(added)


if __name__ == "__main__":
    main()
