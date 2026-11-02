# RedRog: Antigravity with the RedRog traffic lights (modules/apps/antigravity).
# Rewrites a copy of its app.asar: no Windows-style caption buttons (Electron's
# title bar overlay, used off macOS), and a hook that loads redrog-main.js.
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




# ── Antigravity patches (modules/apps/antigravity) ──────────────────────────
import re

def sub(b, old, new):
    if b.count(old) != 1:
        raise SystemExit("Antigravity changed: patch no longer applies")
    return b.replace(old, new)

HOOK = (b'\n;try{require(require("path").join(require("os").homedir(),'
        b'".local/lib/redrog/antigravity/redrog-main.js"))}catch(e){console.error("RedRog Antigravity hook:",e)}\n')

if __name__ == "__main__":
    import sys
    src, dst = sys.argv[1:]
    with open(src, "rb") as f:
        header, base = read_header(f)
        pj = header["files"]["package.json"]
        f.seek(base + int(pj["offset"]))
        main = re.sub(r"^\./", "", json.loads(f.read(pj["size"]))["main"])
    # the overlay of caption buttons only where Antigravity puts it on macOS:
    # nowhere (redrog-main.js draws the traffic lights)
    ops = {"dist/utils.js": lambda b: sub(b, b"titleBarOverlay: isMacOS()", b"titleBarOverlay: true || isMacOS()")}
    if main in ops:
        raise SystemExit("unexpected layout")
    ops[main] = lambda b: b + HOOK
    patch(src, dst, ops)
