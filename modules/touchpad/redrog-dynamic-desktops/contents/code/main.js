// RedRog: desktops like macOS Spaces (modules/touchpad).
// - always at least MIN desktops
// - the last desktop is kept empty: when a window lands on it, a new empty
//   one is added after it, so swiping right keeps finding a free desktop
// - empty desktops that are not the current one close by themselves (never
//   going below MIN)
const MIN = 3;

// desktops are compared by id: each access to them can give a new JS wrapper
function same(a, b) { return a && b && a.id === b.id; }
function isCurrent(d) { return same(d, workspace.currentDesktop); }
function counts(desktop) {
    return workspace.windowList().some(function (w) {
        return w.normalWindow && !w.skipTaskbar && !w.onAllDesktops
            && w.desktops.some(function (d) { return same(d, desktop); });
    });
}

let busy = false;
function tidy() {
    if (busy) return;
    busy = true;
    try {
        let ds = workspace.desktops;
        while (ds.length < MIN) {
            workspace.createDesktop(ds.length, "");
            ds = workspace.desktops;
        }
        // a free desktop at the end
        if (counts(ds[ds.length - 1])) {
            workspace.createDesktop(ds.length, "");
            ds = workspace.desktops;
        }
        // empty desktops close, except the current one and the free last one
        for (let i = ds.length - 2; i >= 0; i--) {
            if (workspace.desktops.length <= MIN) break;
            const d = ds[i];
            if (!isCurrent(d) && !counts(d)) workspace.removeDesktop(d);
        }
        // only one free desktop at the end
        ds = workspace.desktops;
        while (ds.length > MIN && !counts(ds[ds.length - 1]) && !counts(ds[ds.length - 2])
               && !isCurrent(ds[ds.length - 1]) && !isCurrent(ds[ds.length - 2])) {
            workspace.removeDesktop(ds[ds.length - 1]);
            ds = workspace.desktops;
        }
    } finally {
        busy = false;
    }
}

function watch(w) {
    w.desktopsChanged.connect(tidy);
}
workspace.windowList().forEach(watch);
workspace.windowAdded.connect(function (w) { watch(w); tidy(); });
workspace.windowRemoved.connect(tidy);
workspace.currentDesktopChanged.connect(tidy);
tidy();
