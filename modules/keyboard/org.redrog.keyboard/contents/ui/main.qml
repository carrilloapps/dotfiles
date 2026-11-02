// Keyboard layout in the system tray, the RedRog way: a key cap with the
// layout's short label ("ES", "EN"), next to the other hardware items (the
// GPU mode), its outline in the accent color while the automatic keyboard
// (redrog-keyboard-layout: KEYBOARD_AUTO_DEVICES) is connected. The wheel
// switches layouts; a click opens a panel with the current layout, a selector
// for all of them, the automatic switch (its keyboard, on or off) and the
// keyboards connected now.
//
// Layouts come from Plasma (org.kde.plasma.workspace.keyboardlayout); what the
// automatic switch sees, from ~/.local/state/redrog/keyboard-status.json.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.plasma.workspace.keyboardlayout as KL
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property string mono: "JetBrainsMono Nerd Font"

    KL.KeyboardLayout { id: kb }

    // on the top bar only with more than one keyboard connected (the
    // laptop's and another): with one there is nothing to choose; it then
    // waits among the tray's hidden items
    Plasmoid.status: root.keyboards.length > 1 || root.expanded ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

    readonly property int count: kb.layoutsList.length
    readonly property var current: count > 0 && kb.layout < count ? kb.layoutsList[kb.layout] : null
    readonly property string shortLabel: current ? (current.displayName || current.shortName).toUpperCase() : "—"
    readonly property string longLabel: current ? current.longName : ""

    // ── What the automatic switch sees (written by redrog-keyboard-layout) ──
    readonly property string stateDir: "${XDG_STATE_HOME:-$HOME/.local/state}/redrog"
    property var keyboards: []
    property var autoKeyboards: []
    property var autoDevices: []
    property bool autoEnabled: true
    readonly property bool autoConnected: autoKeyboards.length > 0

    P5Support.DataSource {
        id: status
        engine: "executable"
        readonly property string cmd: "sh -c 'cat \"" + root.stateDir + "/keyboard-status.json\" 2>/dev/null'"
        connectedSources: [cmd]
        // every few seconds closed (the key's color), every second open
        interval: root.expanded ? 1000 : 4000
        onNewData: (source, data) => {
            try {
                const s = JSON.parse(data["stdout"] || "{}");
                root.keyboards = s.keyboards || [];
                root.autoKeyboards = s.auto_keyboards || [];
                root.autoDevices = s.auto_devices || [];
                root.autoEnabled = s.auto_enabled !== false;
            } catch (e) {}
        }
    }

    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => disconnectSource(source)
    }
    function setAuto(on) {
        root.autoEnabled = on;
        run.connectSource("sh -c '" + (on ? "rm -f" : "mkdir -p \"" + root.stateDir + "\" && touch")
                          + " \"" + root.stateDir + "/keyboard-auto-off\"'");
    }

    toolTipMainText: longLabel || i18n("Keyboard layout")
    toolTipSubText: autoConnected && autoEnabled ? i18n("%1 connected: automatic layout", autoKeyboards[0])
                                                : i18n("Meta+Alt+K switches layouts")

    // ── System tray ──────────────────────────────────────────────────────────
    // A key cap: the layout's label inside a rounded key outline, sized like
    // the tray icons around it. While the automatic keyboard is in charge, the
    // outline takes the accent color.
    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        Layout.minimumWidth: Kirigami.Units.iconSizes.small + 6
        Layout.preferredWidth: Math.max(Kirigami.Units.iconSizes.small + 6, cap.width)
        onClicked: mouse => {
            if (mouse.button === Qt.MiddleButton)
                kb.switchToNextLayout();
            else
                root.expanded = !root.expanded;
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y > 0)
                kb.switchToPreviousLayout();
            else if (wheel.angleDelta.y < 0)
                kb.switchToNextLayout();
        }

        Rectangle {
            id: cap
            readonly property bool auto: root.autoConnected && root.autoEnabled
            anchors.centerIn: parent
            height: Math.round(Math.min(parent.height, Kirigami.Units.iconSizes.small) * 0.92)
            width: Math.max(height + 2, label.implicitWidth + 7)
            radius: 4
            color: compact.containsMouse || root.expanded ? Qt.alpha(Kirigami.Theme.textColor, 0.12) : "transparent"
            border.width: 1.5
            border.color: auto ? root.red : Qt.rgba(root.fg.r, root.fg.g, root.fg.b, 0.85)
            Behavior on border.color { ColorAnimation { duration: 250 } }
            Behavior on color { ColorAnimation { duration: 150 } }
            // the key's lower edge, as on a real key cap
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 2
                width: parent.width - 8
                height: 1
                radius: 0.5
                color: parent.border.color
                opacity: 0.35
            }
            Text {
                id: label
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -0.5
                text: root.shortLabel
                color: root.fg
                font.pixelSize: Math.max(8, Math.round(cap.height * 0.52))
                font.bold: true
                font.letterSpacing: 0.2
                // a quick fade when the layout changes
                Behavior on text {
                    SequentialAnimation {
                        NumberAnimation { target: label; property: "opacity"; to: 0.15; duration: 90 }
                        PropertyAction {}
                        NumberAnimation { target: label; property: "opacity"; to: 1; duration: 140 }
                    }
                }
            }
        }
    }

    // ── Panel ────────────────────────────────────────────────────────────────
    fullRepresentation: Item {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 22
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.preferredHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.minimumHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2
        Layout.maximumHeight: content.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: 10

            // Current layout, big, and the selector
            Card {
                title: i18n("Keyboard layout")
                note: "Meta+Alt+K"
                shown: root.expanded
                order: 0
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    Rectangle {
                        width: 46; height: 46; radius: 12
                        color: Qt.rgba(root.red.r, root.red.g, root.red.b, 0.16)
                        border.width: 1
                        border.color: Qt.rgba(root.red.r, root.red.g, root.red.b, 0.45)
                        Text {
                            anchors.centerIn: parent
                            text: root.shortLabel
                            color: root.fg
                            font.family: root.mono
                            font.pixelSize: 16
                            font.bold: true
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            Layout.fillWidth: true
                            text: root.longLabel
                            color: root.fg
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.autoConnected && root.autoEnabled
                                  ? i18n("Set by %1", root.autoKeyboards[0])
                                  : i18n("Chosen by you: it stays until you change it")
                            color: root.dim
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
                Segmented {
                    model: {
                        const m = [];
                        for (let i = 0; i < root.count; i++) {
                            const l = kb.layoutsList[i];
                            m.push({ text: (l.displayName || l.shortName).toUpperCase() + "  ·  " + l.longName.replace(/\s*\(.*\)/, ""),
                                     value: String(i) });
                        }
                        return m;
                    }
                    current: String(kb.layout)
                    onSelected: value => kb.layout = parseInt(value)
                }
            }

            // The automatic switch
            Card {
                title: i18n("Automatic layout")
                note: root.autoDevices.length ? root.autoDevices.join(", ") : i18n("no keyboard set")
                shown: root.expanded
                order: 1
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: root.autoConnected ? root.red : Qt.alpha(Kirigami.Theme.textColor, 0.25)
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: root.autoConnected
                              ? (root.autoEnabled ? i18n("%1 connected: English while it stays connected", root.autoKeyboards[0])
                                                  : i18n("%1 connected (automatic switch off)", root.autoKeyboards[0]))
                              : i18n("Not connected: Spanish. Connecting it switches to English")
                        color: root.fg
                        font.pixelSize: 12
                    }
                    QQC2.Switch {
                        checked: root.autoEnabled
                        onToggled: root.setAuto(checked)
                    }
                }
                Text {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: i18n("Only this keyboard switches the layout; any other keyboard changes nothing.")
                    color: root.dim
                    font.pixelSize: 10
                }
            }

            // Keyboards connected now
            Card {
                title: i18n("Keyboards connected")
                note: String(root.keyboards.length)
                shown: root.expanded
                order: 2
                Repeater {
                    model: root.keyboards
                    RowLayout {
                        required property string modelData
                        readonly property bool isAuto: root.autoKeyboards.indexOf(modelData) >= 0
                        Layout.fillWidth: true
                        spacing: 8
                        Kirigami.Icon {
                            source: modelData.indexOf("AT Translated") >= 0 ? "computer-laptop" : "input-keyboard"
                            implicitWidth: 16; implicitHeight: 16
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.indexOf("AT Translated") >= 0 ? i18n("Laptop keyboard") : modelData
                            color: root.fg
                            font.pixelSize: 12
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: parent.isAuto
                            text: "AUTO"
                            color: root.red
                            font.family: root.mono
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
            }

            PlasmaComponents.ToolButton {
                Layout.alignment: Qt.AlignRight
                text: i18n("Keyboard settings…")
                icon.name: "preferences-desktop-keyboard"
                onClicked: {
                    run.connectSource("kcmshell6 kcm_keyboard");
                    root.expanded = false;
                }
            }
        }
    }
}
