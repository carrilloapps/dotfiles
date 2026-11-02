// macOS-like layout for Plasma 6. Run by modules/layout/install.sh, which first
// defines:
//   DOCK_STYLE, CLEAR_STYLE, FROSTED_STYLE  Panel Colorizer styles (JSON string) or null
//   TOP_AUTOLOAD           Panel Colorizer preset auto-loading rules (JSON string)
//   LAUNCHERS              dock launchers ("applications:<id>.desktop")
if (typeof DOCK_STYLE === "undefined") { var DOCK_STYLE = null; }
if (typeof CLEAR_STYLE === "undefined") { var CLEAR_STYLE = null; }
if (typeof TOP_AUTOLOAD === "undefined") { var TOP_AUTOLOAD = "{}"; }
if (typeof LAUNCHERS === "undefined") { var LAUNCHERS = []; }
// Removes the existing panels and creates a slim top bar and a centered
// floating dock.

// The dock the user already has survives a reinstall: the apps they pinned
// (and not the ones they unpinned), in their order. DOCK_APPS only fills a
// first dock. Downloads and Trash always go last
var pinned = [];
panels().forEach(function (p) {
    p.widgets().forEach(function (w) {
        if (w.type !== "org.kde.plasma.icontasks" && w.type !== "org.kde.plasma.taskmanager") return;
        w.currentConfigGroup = ["General"];
        String(w.readConfig("launchers", "")).split(",").forEach(function (l) {
            if (l && pinned.indexOf(l) < 0) pinned.push(l);
        });
    });
});
var isFolder = function (l) { return /redrog-(downloads|trash)\.desktop$/.test(l); };
var merged = pinned.filter(function (l) { return !isFolder(l); });
if (merged.length === 0)
    LAUNCHERS.forEach(function (l) { if (!isFolder(l)) merged.push(l); });
LAUNCHERS.forEach(function (l) { if (isFolder(l)) merged.push(l); });
LAUNCHERS = merged;

panels().forEach(function (p) { p.remove(); });

// ── Top bar: menu, global app menu, tray, battery, clock, notifications ────
var top = new Panel;
top.location = "top";
top.height = Math.round(gridUnit * 2.0);   // includes vertical padding (8 physical px per side)
top.floating = false;
top.opacity = "translucent";
top.hiding = "normal";

top.addWidget("org.kde.plasma.marginsseparator");   // breathing room at the left edge
var kickoff = top.addWidget("org.kde.plasma.kickoff");
kickoff.currentConfigGroup = ["General"];
kickoff.writeConfig("icon", "redrog-arch");   // the Arch logo, like the Apple logo on macOS
kickoff.currentConfigGroup = ["Shortcuts"];
kickoff.writeConfig("global", "Alt+F1");

var appmenu = top.addWidget("org.kde.plasma.appmenu");
appmenu.currentConfigGroup = ["General"];
appmenu.writeConfig("allScreens", false);   // each screen's bar shows the menus of its own windows
top.addWidget("org.kde.plasma.panelspacer");

var tray = top.addWidget("org.kde.plasma.systemtray");
// Network and volume always visible
tray.currentConfigGroup = ["General"];
// (and the keyboard layout key cap of modules/keyboard, when installed)
if (knownWidgetTypes.indexOf("org.redrog.keyboard") >= 0) {
    tray.writeConfig("shownItems", ["org.kde.plasma.networkmanagement", "org.kde.plasma.volume", "org.redrog.keyboard"]);
} else {
    tray.writeConfig("shownItems", ["org.kde.plasma.networkmanagement", "org.kde.plasma.volume"]);
}
// battery and notifications live outside the tray, as their own widgets
tray.writeConfig("hiddenItems", ["org.kde.plasma.battery", "org.kde.plasma.notifications",
                                 "org.kde.plasma.keyboardlayout"]);   // org.redrog.keyboard shows it
tray.writeConfig("iconSpacing", 2);   // compact, like the macOS menu bar
// GPU mode lives in the battery popup: the supergfxctl tray widget, which the
// tray would add by itself once installed, stays out ("known", not shown)
tray.writeConfig("knownItems", ["dev.jhyub.supergfxctl"]);

// Battery like macOS: "85 %" as text (own widget) followed by the icon
if (knownWidgetTypes.indexOf("org.redrog.batterypercent") >= 0) {
    top.addWidget("org.redrog.batterypercent");
}
var battery = top.addWidget("org.kde.plasma.battery");
battery.currentConfigGroup = ["General"];
battery.writeConfig("showPercentage", false);   // the percentage comes from org.redrog.batterypercent

// Clock: date and time in one line ("Vie 16 oct. 3:43 PM"); Plasma's clock
// as a fallback
if (knownWidgetTypes.indexOf("org.redrog.clock") >= 0) {
    top.addWidget("org.redrog.clock");
} else {
    var clock = top.addWidget("org.kde.plasma.digitalclock");
    clock.currentConfigGroup = ["Appearance"];
    clock.writeConfig("showDate", true);
    clock.writeConfig("dateDisplayFormat", 1);   // beside the time
}
// Notification Center (history) at the far right, like macOS; Meta+N opens it
var bell = top.addWidget("org.kde.plasma.notifications");
bell.currentConfigGroup = ["Shortcuts"];
bell.writeConfig("global", "Meta+N");
top.addWidget("org.kde.plasma.marginsseparator");   // breathing room at the right edge

// ── Dock: Launchpad · apps · Downloads · Trash ──────────────────────────────
var dock = new Panel;
dock.location = "bottom";
dock.height = Math.round(gridUnit * 2.95);  // icon size + 8 px bottom padding
dock.floating = true;
dock.lengthMode = "fit";
dock.alignment = "center";
dock.opacity = "translucent";
dock.hiding = "dodgewindows";   // hides when a window covers it (e.g. maximized)

// Launchpad: full-screen AppGrid (packages/appgrid) if installed; otherwise
// Plasma's Application Dashboard
if (knownWidgetTypes.indexOf("dev.xarbit.appgrid") >= 0) {
    var appgrid = dock.addWidget("dev.xarbit.appgrid");
    appgrid.currentConfigGroup = ["General"];
    // Frosted, rounded panel from the RedRog Plasma style, like the
    // notifications and popups
    appgrid.writeConfig("useThemeBackground", true);
    appgrid.writeConfig("overrideRadius", true);
    appgrid.writeConfig("cornerRadius", 18);
    // Calm and flat: no dividers, icon shadows, green "new" badges or shaking
    appgrid.writeConfig("showDividers", false);
    appgrid.writeConfig("iconShadow", false);
    appgrid.writeConfig("showNewAppBadge", false);
    // still icons like macOS Launchpad: no grow, shake or highlight on hover
    appgrid.writeConfig("hoverAnimation", 0);
    appgrid.writeConfig("hoverHighlight", false);
    appgrid.writeConfig("shakeOnOpen", false);
    appgrid.writeConfig("openAnimation", 2);       // scale
    appgrid.writeConfig("checkForUpdates", false);
    // Alt+Space opens it (install.sh moves KRunner to Alt+F2 and Search)
    appgrid.currentConfigGroup = ["Shortcuts"];
    appgrid.writeConfig("global", "Alt+Space");
} else {
    var launchpad = dock.addWidget("org.kde.plasma.kickerdash");
    launchpad.currentConfigGroup = ["General"];
    launchpad.writeConfig("icon", "appgrid");
}

var tasks = dock.addWidget("org.kde.plasma.icontasks");
tasks.currentConfigGroup = ["General"];
tasks.writeConfig("launchers", LAUNCHERS);
tasks.writeConfig("iconSpacing", 0);          // tight icons, like the macOS dock
tasks.writeConfig("maxStripes", 1);
tasks.writeConfig("groupingStrategy", 1);      // group windows by application
tasks.writeConfig("separateLaunchers", false); // a running app stays on its pinned icon
tasks.writeConfig("indicateAudioStreams", true);
tasks.writeConfig("wheelEnabled", false);
tasks.writeConfig("highlightWindows", true);
tasks.writeConfig("showOnlyCurrentDesktop", false);   // like the macOS Dock: apps of every desktop

// Downloads and Trash are launchers at the end of LAUNCHERS, so they have
// exactly the same size as the other icons.

// No background, icons only (Panel Colorizer, "Transparent" preset)
if (DOCK_STYLE !== null && knownWidgetTypes.indexOf("luisbocanegra.panel.colorizer") >= 0) {
    var colorizer = dock.addWidget("luisbocanegra.panel.colorizer");
    colorizer.currentConfigGroup = ["General"];
    colorizer.writeConfig("globalSettings", DOCK_STYLE);
    colorizer.writeConfig("lastPreset", "Transparent");
    colorizer.writeConfig("hideWidget", true);
}

// Top bar (Panel Colorizer): clear while no window is maximized, frosted
// (translucent + blur) when one is, with an animated transition. The menu
// button (RedRog emblem), tray and battery icons are drawn as white
// silhouettes, like the macOS menu bar.
if (CLEAR_STYLE !== null && knownWidgetTypes.indexOf("luisbocanegra.panel.colorizer") >= 0) {
    var topColorizer = top.addWidget("luisbocanegra.panel.colorizer");
    topColorizer.currentConfigGroup = ["General"];
    topColorizer.writeConfig("globalSettings", CLEAR_STYLE);
    topColorizer.writeConfig("presetAutoloading", TOP_AUTOLOAD);
    topColorizer.writeConfig("animatePropertyChanges", true);
    topColorizer.writeConfig("animationDuration", 300);
    topColorizer.writeConfig("hideWidget", true);
    var mask = { mask: true, multiEffect: false };
    topColorizer.writeConfig("forceForegroundColor", JSON.stringify({
        widgets: [
            { id: kickoff.id, name: "org.kde.plasma.kickoff", method: mask, reload: false },
            { id: tray.id, name: "org.kde.plasma.systemtray", method: mask, reload: false },
            { id: battery.id, name: "org.kde.plasma.battery", method: mask, reload: false }
        ],
        reloadInterval: 250
    }));
}
