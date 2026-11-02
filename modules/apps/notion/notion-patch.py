# RedRog: Notion like the macOS app (modules/apps/notion). Rewrites a copy of
# Notion's app.asar: no Windows-style window buttons, room for traffic lights
# at the start of the tab bar, and a hook that loads redrog-main.js.
"""Rewrites an asar archive with some files replaced (sizes may change)."""
import hashlib, json, struct

def read_header(f):
    f.seek(0)
    f.read(4)
    hsize = struct.unpack("<I", f.read(4))[0]
    f.read(4)
    jlen = struct.unpack("<I", f.read(4))[0]
    return json.loads(f.read(jlen)), 8 + hsize

def walk(node, path=()):
    for name, child in node.get("files", {}).items():
        if "files" in child:
            yield from walk(child, path + (name,))
        else:
            yield path + (name,), child

def integrity(data, block=4 * 1024 * 1024):
    return {"algorithm": "SHA256", "hash": hashlib.sha256(data).hexdigest(), "blockSize": block,
            "blocks": [hashlib.sha256(data[i:i + block]).hexdigest() for i in range(0, max(len(data), 1), block)]}

def patch(src, dst, replace):
    """replace: {"a/b/c.js": function(bytes) -> bytes}"""
    with open(src, "rb") as f:
        header, base = read_header(f)
        entries = [(p, n) for p, n in walk(header) if "offset" in n and not n.get("unpacked")]
        entries.sort(key=lambda e: int(e[1]["offset"]))
        chunks, offset = [], 0
        for path, node in entries:
            f.seek(base + int(node["offset"]))
            data = f.read(node["size"])
            key = "/".join(path)
            if key in replace:
                data = replace.pop(key)(data)
                node["integrity"] = integrity(data)
            node["offset"] = str(offset)
            node["size"] = len(data)
            offset += len(data)
            chunks.append(data)
    if replace:
        raise SystemExit("not found: " + ", ".join(replace))
    js = json.dumps(header, separators=(",", ":")).encode()
    pad = (4 - len(js) % 4) % 4
    hp = struct.pack("<II", 4 + len(js) + pad, len(js)) + js + b"\0" * pad
    with open(dst, "wb") as out:
        out.write(struct.pack("<II", 4, len(hp)) + hp)
        for c in chunks:
            out.write(c)


# ── Notion patches (modules/apps/notion) ────────────────────────────────────
def sub(b, old, new):
    if b.count(old) != 1:
        raise SystemExit("Notion changed: patch no longer applies")
    return b.replace(old, new)

HOOK = (b'\n;try{require(require("path").join(require("os").homedir(),'
        b'".local/lib/redrog/notion/redrog-main.js"))}catch(e){console.error("RedRog Notion hook:",e)}\n')

def main_js(b):
    # no Chromium window buttons: redrog-main.js draws macOS traffic lights
    b = sub(b, b'titleBarStyle:"hidden",titleBarOverlay:(0,m.windowControlCustomizationsSelector)(y)',
            b'titleBarStyle:"hidden"')
    return b + HOOK

def tabs_js(b):
    # room for the traffic lights at the start of the tab bar (as on macOS), none at the end
    b = sub(b, b'(0,r.areLocaleDirectionsAligned)(a)?12:(0,n.getWindowControlsPaddingWin)(s)', b'78')
    return sub(b, b'(0,r.areLocaleDirectionsAligned)(a)?(0,n.getWindowControlsPaddingWin)(l):void 0', b'void 0')

if __name__ == "__main__":
    import sys
    patch(sys.argv[1], sys.argv[2], {".webpack/main/index.js": main_js, ".webpack/renderer/tabs/index.js": tabs_js})
