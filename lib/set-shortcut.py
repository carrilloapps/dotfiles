#!/usr/bin/env python3
"""Sets the global shortcuts of another application's action through
kglobalaccel, so the change applies immediately and is saved.

Usage: set-shortcut.py COMPONENT ACTION [SHORTCUT...]
  e.g. set-shortcut.py org.kde.krunner.desktop _launch Alt+F2 Search
With no SHORTCUT the action is left without shortcuts.
"""
import sys

from gi.repository import Gio, GLib

MODIFIERS = {"Shift": 0x02000000, "Ctrl": 0x04000000, "Alt": 0x08000000, "Meta": 0x10000000}
KEYS = {"Space": 0x20, "Search": 0x01000092, "Return": 0x01000004, "Tab": 0x01000001,
        "Escape": 0x01000000, "Calculator": 0x010000cb}
KEYS.update({f"F{n}": 0x01000030 + n - 1 for n in range(1, 36)})
KEYS.update({f"Launch{n}": 0x010000a2 + n for n in range(10)})   # e.g. ASUS Armoury Crate key


def key_code(shortcut):
    code = 0
    for part in shortcut.split("+"):
        if part in MODIFIERS:
            code |= MODIFIERS[part]
        elif part in KEYS:
            code |= KEYS[part]
        elif len(part) == 1:
            code |= ord(part.upper())
        else:
            raise SystemExit(f"unknown key: {part}")
    return code


component, action, *shortcuts = sys.argv[1:]
bus = Gio.bus_get_sync(Gio.BusType.SESSION)
# actionId: component, action, friendly component name, friendly action name
action_id = [component, action, "", ""]
# a(ai): one struct per shortcut, holding the key codes of its sequence
keys = [([key_code(s)],) for s in shortcuts]
# an app's launch action (COMPONENT.desktop) only exists once something
# registers it: register it first, which is a no-op when it already exists
bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel",
              "doRegister", GLib.Variant("(as)", (action_id,)),
              None, Gio.DBusCallFlags.NONE, -1, None)
if component.endswith(".desktop"):
    # An app launch action has no running owner, so it must be marked present
    # (SetPresent = 2) or KWin ignores the key press, even though invoking it
    # over D-Bus works; NoAutoloading = 4 takes these keys, not the saved ones.
    # This is what System Settings' Shortcuts page does.
    bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel",
                  "setShortcutKeys", GLib.Variant("(asa(ai)u)", (action_id, keys, 2 | 4)),
                  None, Gio.DBusCallFlags.NONE, -1, None)
else:
    bus.call_sync("org.kde.kglobalaccel", "/kglobalaccel", "org.kde.KGlobalAccel",
                  "setForeignShortcutKeys", GLib.Variant("(asa(ai))", (action_id, keys)),
                  None, Gio.DBusCallFlags.NONE, -1, None)
