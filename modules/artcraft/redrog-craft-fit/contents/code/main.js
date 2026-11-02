// The ArtCraft apps (egui) reopen at the size they last had, Antigravity
// opens at 1400x900 and Audacity 4 over the whole screen: on the laptop panel
// at 125 % (1536x864 usable points) they hang off its edges or fill it. Such
// a window, larger than its screen's usable area (panels left out) or as
// large as all of it, is brought down to 90 % of it and centered; one that
// fits with room to spare is left where the app put it.
// KWin coordinates are logical, so each screen's own scale is counted.
var FILL = 0.9;

var CLASSES = [/^ai\.storyteller\./, /^io\.tangencylabs\./, /^antigravity$/, /^audacity4$/i];

function isCraft(w) {
    var cls = String(w.resourceClass || "");
    return w.normalWindow && CLASSES.some(function (re) { return re.test(cls); });
}

function fit(w) {
    if (!isCraft(w) || w.fullScreen) return;
    var area = workspace.clientArea(KWin.MaximizeArea, w);
    var g = w.frameGeometry;
    var inside = g.x >= area.x && g.y >= area.y &&
                 g.x + g.width <= area.x + area.width && g.y + g.height <= area.y + area.height;
    var filling = g.width >= area.width - 2 && g.height >= area.height - 2;
    if (inside && !filling) return;
    var width = Math.min(g.width, Math.round(area.width * FILL));
    var height = Math.min(g.height, Math.round(area.height * FILL));
    if (filling || g.width > area.width || g.height > area.height) {
        w.setMaximize(false, false);
    }
    w.frameGeometry = {
        x: area.x + Math.round((area.width - width) / 2),
        y: area.y + Math.round((area.height - height) / 2),
        width: width,
        height: height
    };
}

function watch(w) {
    if (!isCraft(w)) return;
    fit(w);
    // the app can set its saved size just after the window appears
    var checks = 0;
    var once = function () {
        if (++checks > 3 || w.move || w.resize) {
            w.frameGeometryChanged.disconnect(once);
            return;
        }
        fit(w);
    };
    w.frameGeometryChanged.connect(once);
}

workspace.windowAdded.connect(watch);
