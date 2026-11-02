// EasyEffects in the system tray as a RedRog item: among the hardware items
// (the tray sorts by category, then name: "Ecualizador" falls between the
// keyboard layout and the graphics mode), instead of EasyEffects' own icon,
// which Plasma would keep with the application icons. Shown while EasyEffects
// runs. A click opens it; the context menu (right click) is EasyEffects' own,
// rebuilt: the output and input presets (the loaded ones checked) and the
// effects on or off (global bypass). It is read in the background (every few
// seconds and after each action), never while the menu is open: Plasma
// shrinks a menu whose actions change under it.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property bool running: false
    property var outputs: []
    property var inputs: []
    property string output: ""
    property string input: ""
    property bool bypassed: false

    Plasmoid.status: root.running ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

    toolTipMainText: i18n("Equalizer")
    toolTipSubText: root.running ? i18n("EasyEffects: click to open it") : i18n("EasyEffects is not running")

    // a cheap check every few seconds
    P5Support.DataSource {
        id: status
        engine: "executable"
        readonly property string cmd: "sh -c 'pgrep -x easyeffects >/dev/null && echo on || echo off'"
        connectedSources: [cmd]
        interval: 5000
        onNewData: (source, data) => root.running = (data["stdout"] || "").trim() === "on"
    }
    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            status.connectSource(status.cmd);
        }
    }
    function open() { run.connectSource("easyeffects"); }
    function bypass(on) {
        root.bypassed = on;
        run.connectSource("easyeffects --bypass " + (on ? "1" : "2"));
    }
    function load(name) {
        // single quotes in a preset name, escaped for the shell
        run.connectSource("easyeffects -l '" + name.replace(/'/g, "'\\''") + "'");
    }

    // the presets, from EasyEffects' own preset files (asking it with
    // "easyeffects -p", like "-b 3" for the bypass, closes its window), and
    // the loaded ones from "easyeffects -s", which leaves it alone. The bypass
    // state is the one set from this menu
    P5Support.DataSource {
        id: presets
        engine: "executable"
        readonly property string cmd: "sh -c 'D=\"${XDG_DATA_HOME:-$HOME/.local/share}/easyeffects\"; for k in output input; do echo \"#$k\"; ls \"$D/$k\" 2>/dev/null | sed -n \"s/[.]json$//p\"; done; echo @@; easyeffects -s'"
        onNewData: (source, data) => {
            disconnectSource(source);
            const parts = (data["stdout"] || "").split("@@");
            const lists = { output: [], input: [] };
            let kind = "";
            for (const line of (parts[0] || "").split("\n")) {
                const head = line.match(/^#(output|input)$/);
                if (head) { kind = head[1]; continue; }
                if (kind && line.trim() !== "")
                    lists[kind].push(line.trim());
            }
            root.outputs = lists.output;
            root.inputs = lists.input;
            const cur = parts[1] || "";
            root.output = ((cur.match(/output:\s*(.+)/) || [])[1] || "").trim();
            root.input = ((cur.match(/input:\s*(.+)/) || [])[1] || "").trim();
            // the menu is rebuilt only when the presets themselves change;
            // otherwise only its checks move
            const key = lists.output.join("|") + "#" + lists.input.join("|");
            if (key !== root.menuKey) {
                root.menuKey = key;
                root.buildMenu();
            } else {
                root.updateChecks();
            }
        }
    }
    function refresh() {
        if (root.running)
            presets.connectSource(presets.cmd);
    }
    onRunningChanged: refresh()
    Timer {
        interval: 8000
        repeat: true
        running: root.running
        onTriggered: root.refresh()
    }
    // a moment after an action, the new state
    Timer {
        id: soon
        interval: 700
        onTriggered: root.refresh()
    }

    Component {
        id: actionComponent
        PlasmaCore.Action {}
    }
    property var menuActions: []
    property string menuKey: ""
    function updateChecks() {
        for (const a of root.menuActions) {
            if (!a.checkable)
                continue;
            if (a.objectName === "bypass")
                a.checked = root.bypassed;
            else if (a.objectName === "output")
                a.checked = a.text === root.output;
            else if (a.objectName === "input")
                a.checked = a.text === root.input;
        }
    }
    function action(props, handler) {
        const a = actionComponent.createObject(root, props);
        if (handler)
            a.triggered.connect(handler);
        return a;
    }
    function buildMenu() {
        for (const a of root.menuActions)
            a.destroy();
        const list = [action({ text: i18n("Open EasyEffects") }, root.open)];
        list[0].icon.name = "com.github.wwmm.easyeffects";
        const section = (title, kind, names, current) => {
            if (!names.length)
                return;
            list.push(action({ isSeparator: true, text: title }));
            for (const n of names)
                list.push(action({ text: n, objectName: kind, checkable: true, checked: n === current },
                                 () => { root.load(n); soon.restart(); }));
        };
        section(i18n("Output presets"), "output", root.outputs, root.output);
        section(i18n("Input presets"), "input", root.inputs, root.input);
        list.push(action({ isSeparator: true }));
        list.push(action({ text: i18n("Bypass effects"), objectName: "bypass", checkable: true, checked: root.bypassed },
                         () => { root.bypass(!root.bypassed); soon.restart(); }));
        root.menuActions = list;
        Plasmoid.contextualActions = list;
    }
    Component.onCompleted: buildMenu()

    compactRepresentation: MouseArea {
        hoverEnabled: true
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        onClicked: root.open()

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.width, parent.height))
            height: width
            // EasyEffects' own symbolic icon, in one flat color: the theme's
            // text, or the one the top bar's colorizer sets over the wallpaper
            source: "com.github.wwmm.easyeffects-symbolic"
            isMask: true
            color: Kirigami.Theme.textColor
        }
    }

    // what a click on its name in the tray's hidden items opens
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        spacing: Kirigami.Units.smallSpacing

        PlasmaComponents.Label {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            text: i18n("Equalizer")
            font.weight: Font.DemiBold
        }
        RowLayout {
            Layout.alignment: Qt.AlignRight
            Layout.margins: Kirigami.Units.smallSpacing
            PlasmaComponents.ToolButton {
                text: i18n("Bypass effects")
                checkable: true
                checked: root.bypassed
                onClicked: root.bypass(!root.bypassed)
            }
            PlasmaComponents.ToolButton {
                text: i18n("Open EasyEffects")
                icon.name: "com.github.wwmm.easyeffects"
                onClicked: {
                    root.open();
                    root.expanded = false;
                }
            }
        }
    }
}
