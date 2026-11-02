#!/usr/bin/env python3
"""Completes a Plasma style made for Plasma 5 with the elements Plasma 6 needs.

Usage: plasma6-complete.py THEME_DIR [REFERENCE_DIR] [SKIP...]

Plasma looks for each element of a style by its id. A file that is missing
falls back to the reference style (Breeze), but a file that exists and lacks
an element draws nothing for it: blank tray icons (power profiles, the volume
warning, the window pin), no focus ring in text fields, no attention state in
the task manager, no shadows. For every SVG of the reference style this copies
the elements the theme's file lacks, with the gradients and filters they use
and the color-scheme stylesheet, so they follow the theme's colors. SKIP lists
files (relative paths, e.g. widgets/switch.svg) that are left alone.
Files the theme lacks entirely under icons/, widgets/ and weather/ are copied
whole, so they take the theme's colors too instead of Breeze's (the variants
under translucent/, opaque/ and solid/ fall back to the theme's own files).
"""
import shutil
import copy
import gzip
import os
import re
import sys
import xml.etree.ElementTree as ET

SVG = "http://www.w3.org/2000/svg"
XLINK = "http://www.w3.org/1999/xlink"
NS = {"svg": SVG}
for prefix, uri in (("", SVG), ("xlink", XLINK),
                    ("inkscape", "http://www.inkscape.org/namespaces/inkscape"),
                    ("sodipodi", "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd")):
    ET.register_namespace(prefix, uri)

# ids editors make up (path123, g45, layer1...) and leftovers that are not
# Plasma elements
NOISE = re.compile(r"^(?:[a-zA-Z]+\d+(?:[-_.]\d+)*|true|false|msc|[a-e]|s[blrt]|rad|line|base|"
                   r"current-color-scheme|svg\d*|defs\d*|metadata\d*|namedview\d*)$")


def load(path):
    data = gzip.open(path).read() if path.endswith(".svgz") else open(path, "rb").read()
    return ET.ElementTree(ET.fromstring(data))


def save(tree, path):
    data = ET.tostring(tree.getroot(), encoding="utf-8", xml_declaration=True)
    if path.endswith(".svgz"):
        with gzip.open(path, "wb") as f:
            f.write(data)
    else:
        with open(path, "wb") as f:
            f.write(data)


def find_file(root, rel):
    for ext in (".svg", ".svgz"):
        p = os.path.join(root, rel + ext)
        if os.path.exists(p):
            return p
    return None


def element_ids(tree):
    """Plasma element ids: elements with an id that is not editor noise and
    is not inside <defs>"""
    defs = {id(d) for d in tree.iter("{%s}defs" % SVG)}
    inside_defs = set()
    for d in tree.iter("{%s}defs" % SVG):
        for e in d.iter():
            inside_defs.add(id(e))
    out = {}
    for e in tree.iter():
        i = e.get("id")
        if i and not NOISE.match(i) and id(e) not in inside_defs and id(e) not in defs:
            out.setdefault(i, e)
    return out


def referenced(elem):
    refs = set()
    for e in elem.iter():
        for k, v in e.attrib.items():
            refs.update(re.findall(r"url\(#([^)]+)\)", v))
            if k in ("{%s}href" % XLINK, "href") and v.startswith("#"):
                refs.add(v[1:])
    return refs


def complete(theme_file, ref_file):
    ref = load(ref_file)
    tree = load(theme_file)
    have = element_ids(tree)
    ref_elems = element_ids(ref)
    missing = [i for i in ref_elems if i not in have]
    if not missing:
        return 0
    root = tree.getroot()
    all_ids = {e.get("id") for e in tree.iter() if e.get("id")}
    ref_by_id = {e.get("id"): e for e in ref.iter() if e.get("id")}
    copied = []
    for i in missing:
        e = ref_elems[i]
        # an element nested in another missing element comes with its parent
        if any(e is not o and any(x is e for x in o.iter()) for o in (ref_elems[m] for m in missing)):
            continue
        copied.append(copy.deepcopy(e))
    # gradients, filters and other definitions they use (and the ones those use)
    need, defs_out, seen = set(), [], set()
    for c in copied:
        need |= referenced(c)
    while need:
        r = need.pop()
        if r in seen or r not in ref_by_id:
            continue
        seen.add(r)
        d = copy.deepcopy(ref_by_id[r])
        need |= referenced(d)
        defs_out.append(d)
    # ids already used in the theme's file are renamed in what is copied
    rename = {}
    for d in defs_out:
        if d.get("id") in all_ids:
            rename[d.get("id")] = "p6-" + d.get("id")
    def fix(elem):
        """points the copied elements' references at the renamed definitions"""
        for e in elem.iter():
            for k, v in list(e.attrib.items()):
                nv = re.sub(r"url\(#([^)]+)\)", lambda m: "url(#%s)" % rename.get(m.group(1), m.group(1)), v)
                if k in ("{%s}href" % XLINK, "href") and v.startswith("#") and v[1:] in rename:
                    nv = "#" + rename[v[1:]]
                if nv != v:
                    e.set(k, nv)
    for d in defs_out:
        if d.get("id") in rename:
            d.set("id", rename[d.get("id")])
        fix(d)
    for c in copied:
        fix(c)
    if defs_out:
        defs = root.find("svg:defs", NS)
        if defs is None:
            defs = ET.SubElement(root, "{%s}defs" % SVG)
        defs.extend(defs_out)
    # the color-scheme stylesheet, which Plasma fills with the theme's colors
    uses_classes = any(e.get("class", "").startswith("ColorScheme") for c in copied for e in c.iter())
    if uses_classes and not any(e.get("id") == "current-color-scheme" for e in tree.iter()):
        style = ref_by_id.get("current-color-scheme")
        if style is not None:
            root.insert(0, copy.deepcopy(style))
    root.extend(copied)
    save(tree, theme_file)
    return len(copied)


def main():
    theme = sys.argv[1]
    reference = sys.argv[2] if len(sys.argv) > 2 else "/usr/share/plasma/desktoptheme/default"
    skip = set(sys.argv[3:])
    total = 0
    for dirpath, _, files in os.walk(reference):
        for name in files:
            if not re.search(r"\.svgz?$", name):
                continue
            ref_file = os.path.join(dirpath, name)
            rel = re.sub(r"\.svgz?$", "", os.path.relpath(ref_file, reference))
            if rel + ".svg" in skip:
                continue
            theme_file = find_file(theme, rel)
            if not theme_file and rel.split(os.sep)[0] in ("icons", "widgets", "weather"):
                dst = os.path.join(theme, rel + ".svg")
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                save(load(ref_file), dst)
                total += 1
                continue
            if theme_file:
                try:
                    total += complete(theme_file, ref_file)
                except ET.ParseError as e:
                    print("skipped %s: %s" % (rel, e), file=sys.stderr)
    print(total)


if __name__ == "__main__":
    main()
