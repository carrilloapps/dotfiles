// RedRog's light/dark switch in the system tray: a monochrome glyph (a moon
// while dark, a sun while light) in the theme's text color, turning as it
// changes. A click switches at once; the context menu (right click) offers
// Light / Dark / Automatic (following Plasma's automatic switch), the
// animated transition on or off, and the global theme settings. The panel
// with a preview of both variants opens from the tray's list of items.
//
// The switch itself is redrog-theme-switch (modules/theme-switch); the two
// palettes for the preview come from ~/.local/lib/redrog/theme/palettes.json.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property color red: Kirigami.Theme.highlightColor

    // an always-present tray item (no attention mark)
    Plasmoid.status: PlasmaCore.Types.ActiveStatus

    readonly property string tool: "$HOME/.local/lib/redrog/redrog-theme-switch"
    property string variant: "dark"
    property string mode: "manual"
    property bool busy: false
    property string pending: ""
    property bool transition: true
    property var palettes: ({})

    P5Support.DataSource {
        id: status
        engine: "executable"
        readonly property string cmd: "sh -c '\"" + root.tool + "\" status; echo; cat \"$HOME/.local/lib/redrog/theme/palettes.json\" 2>/dev/null | tr -d \"\\n\"'"
        connectedSources: [cmd]
        interval: root.expanded || root.busy ? 1000 : 4000
        onNewData: (source, data) => {
            const lines = (data["stdout"] || "").split("\n");
            try {
                const s = JSON.parse(lines[0] || "{}");
                root.variant = s.variant || "dark";
                root.mode = s.mode || "manual";
                root.transition = s.transition !== false;
            } catch (e) {}
            try {
                root.palettes = JSON.parse(lines.slice(1).join("") || "{}");
            } catch (e) {}
            if (root.busy && (root.pending === root.mode || root.pending === root.variant))
                root.busy = false;
        }
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            status.connectSource(status.cmd);
        }
    }
    function choose(what) {
        if (root.busy)
            return;
        root.busy = true;
        root.pending = what;
        run.connectSource("sh -c '\"" + root.tool + "\" " + what + "'");
    }
    function toggle() {
        choose(root.variant === "light" ? "dark" : "light");
    }
    // safety: the switch takes a few seconds at most
    Timer {
        running: root.busy
        interval: 15000
        onTriggered: root.busy = false
    }

    toolTipMainText: root.variant === "light" ? i18n("Light appearance") : i18n("Dark appearance")
    toolTipSubText: root.mode === "auto" ? i18n("Automatic: follows Plasma's light/dark schedule")
                                         : (root.variant === "light" ? i18n("Click for dark") : i18n("Click for light"))

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18n("Light")
            icon.name: "weather-clear"
            checkable: true
            checked: root.mode !== "auto" && root.variant === "light"
            onTriggered: root.choose("light")
        },
        PlasmaCore.Action {
            text: i18n("Dark")
            icon.name: "weather-clear-night"
            checkable: true
            checked: root.mode !== "auto" && root.variant === "dark"
            onTriggered: root.choose("dark")
        },
        PlasmaCore.Action {
            text: i18n("Automatic")
            icon.name: "chronometer"
            checkable: true
            checked: root.mode === "auto"
            onTriggered: root.choose("auto")
        },
        PlasmaCore.Action {
            isSeparator: true
        },
        PlasmaCore.Action {
            text: i18n("Transition effect")
            icon.name: "view-visible"
            checkable: true
            checked: root.transition
            onTriggered: {
                root.transition = !root.transition;
                run.connectSource("sh -c '\"" + root.tool + "\" transition " + (root.transition ? "on" : "off") + "'");
            }
        },
        PlasmaCore.Action {
            text: i18n("Theme settings…")
            icon.name: "preferences-desktop-theme-global"
            onTriggered: run.connectSource("kcmshell6 kcm_lookandfeel")
        }
    ]

    // ── System tray: a moon or a sun ─────────────────────────────────────────
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        // a click switches at once (the menu is on the right click)
        onClicked: root.toggle()

        Glyph {
            id: glyph
            anchors.centerIn: parent
            // the same box as the tray's other icons
            size: Math.round(Math.min(parent.width, parent.height))
            light: root.variant === "light"
            color: root.fg
            busy: root.busy
            auto: root.mode === "auto"
            accent: root.red
        }
    }

    // ── Panel ────────────────────────────────────────────────────────────────
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 21
        Layout.minimumWidth: Kirigami.Units.gridUnit * 19
        Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.maximumHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: 10

            Card {
                title: i18n("Appearance")
                note: root.mode === "auto" ? i18n("automatic") : (root.variant === "light" ? i18n("light") : i18n("dark"))
                shown: root.expanded
                order: 0
                Segmented {
                    model: [
                        { text: i18n("Light"), value: "light" },
                        { text: i18n("Dark"), value: "dark" },
                        { text: i18n("Automatic"), value: "auto" }
                    ]
                    current: root.mode === "auto" ? "auto" : root.variant
                    busy: root.busy
                    pendingValue: root.pending
                    onSelected: value => root.choose(value)
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: root.mode === "auto"
                          ? i18n("Follows Plasma: light by day, dark at night (the schedule of Night Light).")
                          : i18n("Stays as you chose it, also after restarting.")
                    color: root.dim
                    font.pixelSize: 11
                }
            }

            Card {
                title: i18n("Preview")
                note: "RedRog"
                shown: root.expanded
                order: 1
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Preview {
                        Layout.fillWidth: true
                        palette: root.palettes.light || ({})
                        label: i18n("Light")
                        current: root.variant === "light"
                        onPicked: root.choose("light")
                    }
                    Preview {
                        Layout.fillWidth: true
                        palette: root.palettes.dark || ({})
                        label: i18n("Dark")
                        current: root.variant === "dark"
                        onPicked: root.choose("dark")
                    }
                }
            }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignRight
                text: i18n("Global themes…")
                icon.name: "preferences-desktop-theme-global"
                onClicked: {
                    run.connectSource("kcmshell6 kcm_lookandfeel");
                    root.expanded = false;
                }
            }
        }
    }
}
