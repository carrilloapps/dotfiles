# RedRog: Claude desktop with macOS traffic lights (modules/apps/claude). Rewrites
# a copy of its app.asar: no Chromium window buttons, and a hook that loads
# redrog-main.js.
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


# ── Claude desktop patches (modules/apps/claude) ────────────────────────────
import re

def sub(b, old, new):
    if b.count(old) != 1:
        raise SystemExit("Claude desktop changed: patch no longer applies")
    return b.replace(old, new)

HOOK = (b'\n;try{require(require("path").join(require("os").homedir(),'
        b'".local/lib/redrog/claude/redrog-main.js"))}catch(e){console.error("RedRog Claude hook:",e)}\n')

def find_window_chunk(path):
    """the main-process chunk that creates the main window"""
    with open(path, "rb") as f:
        header, base = read_header(f)
        for p, n in walk(header):
            k = "/".join(p)
            if not (k.startswith(".vite/build/") and k.endswith(".js")) or "offset" not in n:
                continue
            f.seek(base + int(n["offset"]))
            if b'titleBarStyle:"hidden",titleBarOverlay:!0,trafficLightPosition' in f.read(n["size"]):
                return k
    raise SystemExit("Claude desktop changed: main window code not found")

if __name__ == "__main__":
    import json, sys
    src, dst = sys.argv[1:]
    with open(src, "rb") as f:
        header, base = read_header(f)
        pj = header["files"]["package.json"]
        f.seek(base + int(pj["offset"]))
        main = re.sub(r"^\./", "", json.loads(f.read(pj["size"]))["main"])
    chunk = find_window_chunk(src)
    # no Chromium window buttons: redrog-main.js draws macOS traffic lights
    ops = {chunk: lambda b: sub(b, b'titleBarStyle:"hidden",titleBarOverlay:!0,trafficLightPosition',
                                   b'titleBarStyle:"hidden",titleBarOverlay:!1,trafficLightPosition')}
    if main == chunk:
        raise SystemExit("unexpected layout")
    ops[main] = lambda b: b + HOOK
    patch(src, dst, ops)
