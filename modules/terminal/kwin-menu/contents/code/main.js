// RedRog: the terminal context menu (a small QML window titled
// "RedRog terminal menu") opens with its top-left corner at the pointer and
// moves left or up when it would leave the screen, like a real menu.
const TITLE = "RedRog terminal menu";

function place(w) {
    if (!w || w.caption !== TITLE)
        return;
    w.skipTaskbar = true;
    w.skipPager = true;
    w.skipSwitcher = true;
    w.keepAbove = true;
    const c = workspace.cursorPos;
    const area = workspace.clientArea(KWin.PlacementArea, w);
    const g = w.frameGeometry;
    let x = c.x + 2, y = c.y + 2;
    if (x + g.width > area.x + area.width)
        x = Math.max(area.x, c.x - g.width - 2);
    if (y + g.height > area.y + area.height)
        y = Math.max(area.y, area.y + area.height - g.height);
    w.frameGeometry = { x: x, y: y, width: g.width, height: g.height };
}

workspace.windowAdded.connect(place);
