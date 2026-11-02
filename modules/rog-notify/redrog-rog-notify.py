#!/usr/bin/env python3
"""Localized notifications for ASUS laptops (asusd).

ROG Control Center ships its notifications hardcoded in English. This small
user service listens to asusd on the system bus and shows the same events
through the desktop notification service, translated with gettext into the
user's language (domain "redrog", see i18n/redrog/).

Events: platform profile, charge limit, dGPU on/off and GPU MUX mode, only
when the value really changes. While the RedRog panel is open its changes make
no bubble (the panel shows them) and other apps' banners are held until it
closes, so none lands on top of it.
"""
import gettext
import os
import sys

import gi
gi.require_version("Gio", "2.0")
from gi.repository import Gio, GLib  # noqa: E402

LOCALEDIR = os.path.expanduser("~/.local/share/locale")
_ = gettext.translation("redrog", LOCALEDIR, fallback=True).gettext

ASUSD = "xyz.ljones.Asusd"
PLATFORM_PATH, PLATFORM_IFACE = "/xyz/ljones", "xyz.ljones.Platform"
ARMOURY_IFACE = "xyz.ljones.AsusArmoury"
APP_NAME = "ROG"
ICON = "rog-control-center"

PROFILES = {  # asusd PlatformProfile values
    0: (lambda: _("Balanced"), "power-profile-balanced-symbolic"),
    1: (lambda: _("Performance"), "power-profile-performance-symbolic"),
    2: (lambda: _("Quiet"), "power-profile-power-saver-symbolic"),
    3: (lambda: _("Low power"), "power-profile-power-saver-symbolic"),
}

session = Gio.bus_get_sync(Gio.BusType.SESSION)
system = Gio.bus_get_sync(Gio.BusType.SYSTEM)
last_id = {}   # one bubble per event kind: newer ones replace older ones


def notify(kind, summary, body="", icon=ICON):
    params = GLib.Variant("(susssasa{sv}i)", (
        APP_NAME, last_id.get(kind, 0), icon, summary, body, [],
        {"desktop-entry": GLib.Variant("s", "org.opengamingcollective.rog-control-center"),
         "category": GLib.Variant("s", "device")}, 4000))
    try:
        reply = session.call_sync("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                                  "org.freedesktop.Notifications", "Notify", params,
                                  GLib.VariantType("(u)"), Gio.DBusCallFlags.NONE, -1, None)
        last_id[kind] = reply.unpack()[0]
    except GLib.Error as err:
        print(f"notification failed: {err.message}", file=sys.stderr)


# asusd re-announces values that did not change (setting the same profile
# again, as redrog-asusd-profile does at every start): only real changes
# make a bubble. Seeded with the current values, so startup is quiet too.
last_value = {}


def changed_value(kind, value):
    if last_value.get(kind) == value:
        return False
    last_value[kind] = value
    return True


def current(path, iface, prop):
    try:
        reply = system.call_sync(ASUSD, path, "org.freedesktop.DBus.Properties", "Get",
                                 GLib.Variant("(ss)", (iface, prop)), GLib.VariantType("(v)"),
                                 Gio.DBusCallFlags.NONE, -1, None)
        return reply.unpack()[0]
    except GLib.Error:
        return None


last_value["profile"] = current(PLATFORM_PATH, PLATFORM_IFACE, "PlatformProfile")
last_value["charge"] = current(PLATFORM_PATH, PLATFORM_IFACE, "ChargeControlEndThreshold")
last_value["dgpu"] = current(PLATFORM_PATH + "/asus_armoury/dgpu_disable", ARMOURY_IFACE, "CurrentValue")
last_value["mux"] = current(PLATFORM_PATH + "/asus_armoury/gpu_mux_mode", ARMOURY_IFACE, "CurrentValue")

# The RedRog panel (org.redrog.batterypercent) renews this file every few
# seconds while it is open. Meanwhile its own changes show in the panel, so
# they make no bubble, and other apps' banners are held (Inhibit) instead of
# landing on top of it; Plasma lists them once the panel closes. Critical
# ones still show (CriticalInDndMode, modules/notifications).
PANEL_MARK = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "redrog-panel-open")
inhibit_cookie = None


def panel_open():
    try:
        return GLib.get_real_time() / 1e6 - os.stat(PANEL_MARK).st_mtime < 8
    except OSError:
        return False


def hold_banners():
    global inhibit_cookie
    want = panel_open()
    try:
        if want and inhibit_cookie is None:
            reply = session.call_sync("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                                      "org.freedesktop.Notifications", "Inhibit",
                                      GLib.Variant("(ssa{sv})", ("org.kde.plasmashell", _("RedRog panel open"), {})),
                                      GLib.VariantType("(u)"), Gio.DBusCallFlags.NONE, -1, None)
            inhibit_cookie = reply.unpack()[0]
        elif not want and inhibit_cookie is not None:
            session.call_sync("org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                              "org.freedesktop.Notifications", "UnInhibit", GLib.Variant("(u)", (inhibit_cookie,)),
                              None, Gio.DBusCallFlags.NONE, -1, None)
            inhibit_cookie = None
    except GLib.Error as err:
        print(f"holding banners failed: {err.message}", file=sys.stderr)
        inhibit_cookie = None
    return True   # keep polling


def on_platform(changed):
    if "PlatformProfile" in changed and changed_value("profile", changed["PlatformProfile"]) \
            and not panel_open():
        name, icon = PROFILES.get(changed["PlatformProfile"], (lambda: _("Custom"), ICON))
        notify("profile", _("Power profile: %s") % name(), icon=icon)
    if "ChargeControlEndThreshold" in changed and changed_value("charge", changed["ChargeControlEndThreshold"]) \
            and not panel_open():
        limit = changed["ChargeControlEndThreshold"]
        body = _("The battery will stop charging at %d %%.") % limit if limit < 100 else \
            _("The battery will charge to 100 %.")
        notify("charge", _("Charge limit: %d %%") % limit, body, "battery-good-charging-symbolic")


def on_armoury(path, changed):
    if "CurrentValue" not in changed:
        return
    value = changed["CurrentValue"]
    attr = path.rsplit("/", 1)[-1]
    kind = {"dgpu_disable": "dgpu", "gpu_mux_mode": "mux"}.get(attr)
    if kind is None or not changed_value(kind, value) or panel_open():
        return
    if attr == "dgpu_disable":
        notify("dgpu", _("Dedicated GPU disabled") if value else _("Dedicated GPU enabled"),
               _("Changes take effect after a reboot or logout."), "video-display")
    elif attr == "gpu_mux_mode":
        notify("mux", _("GPU mode: %s") % (_("Hybrid") if value else _("Ultimate (dGPU only)")),
               _("Reboot to apply the change."), "video-display")


def on_signal(_conn, _sender, path, _iface, _signal, params):
    iface, changed, _invalidated = params.unpack()
    if iface == PLATFORM_IFACE:
        on_platform(changed)
    elif iface == ARMOURY_IFACE:
        on_armoury(path, changed)


system.signal_subscribe(ASUSD, "org.freedesktop.DBus.Properties", "PropertiesChanged",
                        None, None, Gio.DBusSignalFlags.NONE, on_signal)
GLib.timeout_add_seconds(1, hold_banners)
GLib.MainLoop().run()
