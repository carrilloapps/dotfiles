/*
    SPDX-FileCopyrightText: 2021 Janghyub Seo <jhyub06@gmail.com>
    SPDX-License-Identifier: MPL-2.0

    RedRog (packages/plasma6-applets-supergfxctl): the popup redone in the
    style of the macOS Control Center, in the RedRog colors. Same plasmoid
    API as upstream's main.qml (candidates, realizeCandidate, revert...).
*/

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: mainWindow
    Plasmoid.icon: plasmoid.iconName
    switchWidth: Kirigami.Units.gridUnit * 10
    switchHeight: Kirigami.Units.gridUnit * 10

    function tint(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }
    readonly property color accent: Kirigami.Theme.highlightColor
    readonly property color text: Kirigami.Theme.textColor
    readonly property int radius: Kirigami.Units.cornerRadius > 0 ? Kirigami.Units.cornerRadius * 2 : 10

    Binding {
        target: plasmoid
        property: "status"

        function isPlasmoidActive() {
            if (plasmoid.power.isActive) {
                if (plasmoid.isCharging) {
                    return plasmoid.configuration.statusActiveOnChargeDGPUActive === 0
                } else {
                    return plasmoid.configuration.statusActiveOnDischargeDGPUActive === 0
                }
            } else {
                if (plasmoid.isCharging) {
                    return plasmoid.configuration.statusActiveOnChargeDGPUInactive === 0
                } else {
                    return plasmoid.configuration.statusActiveOnDischargeDGPUInactive === 0
                }
            }
        }

        value: isPlasmoidActive() ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus
    }
    toolTipMainText: i18n("Graphics")
    toolTipSubText: i18n("Graphics mode: %1, dGPU power: %2", plasmoid.mode.name, plasmoid.power.name)

    compactRepresentation: MouseArea {
        property bool wasExpanded
        onPressed: wasExpanded = mainWindow.expanded
        onClicked: mainWindow.expanded = !wasExpanded
        hoverEnabled: true

        Kirigami.Icon {
            anchors.fill: parent
            source: plasmoid.icon
            active: parent.containsMouse

            PlasmaComponents.BusyIndicator {
                anchors.centerIn: parent
                running: plasmoid.realizing != -1
                visible: running
            }
        }
    }

    fullRepresentation: PlasmaExtras.Representation {
        id: dialog
        Layout.minimumWidth: Kirigami.Units.gridUnit * 19
        Layout.preferredWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: content.implicitHeight + Kirigami.Units.gridUnit
        Layout.preferredHeight: content.implicitHeight + Kirigami.Units.gridUnit

        ColumnLayout {
            id: content
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: Kirigami.Units.gridUnit * 0.6
            }
            spacing: Kirigami.Units.smallSpacing * 2
            visible: !plasmoid.isDaemonFailing && !plasmoid.isDaemonOutdated

            // ── Header: current mode and the dedicated GPU's power ──────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing * 3

                Rectangle {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                    radius: mainWindow.radius
                    color: mainWindow.tint(mainWindow.accent, 0.16)
                    border.width: 1
                    border.color: mainWindow.tint(mainWindow.accent, 0.35)
                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.iconSizes.smallMedium
                        height: width
                        source: plasmoid.icon
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    // the tray header already says "Graphics": the card leads with the mode
                    PlasmaComponents.Label {
                        text: plasmoid.mode.name
                        font.weight: Font.DemiBold
                        font.pixelSize: Kirigami.Theme.defaultFont.pixelSize * 1.15
                    }
                    RowLayout {
                        spacing: Kirigami.Units.smallSpacing * 1.5
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 3.5
                            color: plasmoid.power.isActive ? mainWindow.accent : mainWindow.tint(mainWindow.text, 0.35)
                        }
                        PlasmaComponents.Label {
                            text: i18n("dGPU power: %1", plasmoid.power.name)
                            opacity: 0.7
                            font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                }
            }

            // ── A switch waiting for a logout or reboot ─────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: plasmoid.isPending
                implicitHeight: pendingRow.implicitHeight + Kirigami.Units.smallSpacing * 4
                radius: mainWindow.radius
                color: mainWindow.tint(mainWindow.accent, 0.14)
                border.width: 1
                border.color: mainWindow.tint(mainWindow.accent, 0.35)
                RowLayout {
                    id: pendingRow
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing * 2
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: i18n("%1 is required to switch to %2", plasmoid.pendingAction.name, plasmoid.pendingMode.name)
                    }
                    PlasmaComponents.Button {
                        text: i18n("Revert to %1", plasmoid.mode.name)
                        icon.name: "edit-undo"
                        onClicked: plasmoid.revert()
                    }
                }
            }

            // ── Daemon errors ────────────────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                visible: plasmoid.errorMsg.length > 0
                implicitHeight: errorColumn.implicitHeight + Kirigami.Units.smallSpacing * 4
                radius: mainWindow.radius
                color: mainWindow.tint(Kirigami.Theme.negativeTextColor, 0.14)
                border.width: 1
                border.color: mainWindow.tint(Kirigami.Theme.negativeTextColor, 0.4)
                ColumnLayout {
                    id: errorColumn
                    anchors {
                        fill: parent
                        margins: Kirigami.Units.smallSpacing * 2
                    }
                    spacing: Kirigami.Units.smallSpacing
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: plasmoid.errorMsg
                    }
                    PlasmaComponents.Label {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        opacity: 0.7
                        font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                        text: i18n("Run journalctl -b -u supergfxd for more information")
                    }
                }
            }

            // ── Modes ────────────────────────────────────────────────────────
            PlasmaComponents.Label {
                Layout.topMargin: Kirigami.Units.smallSpacing
                text: i18n("Modes")
                opacity: 0.55
                font.weight: Font.DemiBold
                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
            }

            Repeater {
                model: plasmoid.candidates
                delegate: Rectangle {
                    id: row
                    required property int section
                    required property string reason
                    required property string name
                    required property string icon
                    required property string buttonText
                    required property int index
                    readonly property bool current: section == 0
                    readonly property bool available: section == 1
                    readonly property bool busy: plasmoid.realizing == index

                    Layout.fillWidth: true
                    visible: section != 3 || plasmoid.configuration.showUnsupported
                    implicitHeight: Kirigami.Units.gridUnit * (reason.length > 0 ? 2.6 : 2.2)
                    radius: mainWindow.radius
                    color: current ? mainWindow.tint(mainWindow.accent, 0.55)
                         : (rowMouse.containsMouse && available) ? mainWindow.tint(mainWindow.text, 0.07)
                         : "transparent"
                    Behavior on color { ColorAnimation { duration: Kirigami.Units.shortDuration } }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: row.available && plasmoid.realizing == -1
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: plasmoid.realizeCandidate(row.index)
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: Kirigami.Units.smallSpacing * 2.5
                            rightMargin: Kirigami.Units.smallSpacing * 2.5
                        }
                        spacing: Kirigami.Units.smallSpacing * 3

                        Kirigami.Icon {
                            Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                            Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
                            // the mode's glyph alone: the accent dot belongs to the
                            // tray icon, when the dedicated GPU is really on
                            source: row.icon.replace("-active", "")
                            opacity: row.current || row.available ? 1 : 0.45
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                text: row.name
                                elide: Text.ElideRight
                                font.weight: row.current ? Font.DemiBold : Font.Normal
                                opacity: row.current || row.available ? 1 : 0.45
                            }
                            PlasmaComponents.Label {
                                Layout.fillWidth: true
                                visible: row.reason.length > 0
                                text: row.reason
                                elide: Text.ElideRight
                                opacity: 0.6
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                            }
                        }
                        // the current mode: a check, as in the macOS menus
                        Kirigami.Icon {
                            visible: row.current
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                            source: "checkmark"
                        }
                        // an available mode: its action as a small pill
                        Rectangle {
                            visible: row.available && !row.busy
                            implicitWidth: pillLabel.implicitWidth + Kirigami.Units.smallSpacing * 5
                            implicitHeight: pillLabel.implicitHeight + Kirigami.Units.smallSpacing * 1.5
                            radius: height / 2
                            color: mainWindow.tint(mainWindow.text, rowMouse.containsMouse ? 0.16 : 0.09)
                            PlasmaComponents.Label {
                                id: pillLabel
                                anchors.centerIn: parent
                                text: i18n("Switch")
                                font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                                font.weight: Font.DemiBold
                            }
                        }
                        PlasmaComponents.BusyIndicator {
                            visible: row.busy
                            running: row.busy
                            Layout.preferredWidth: Kirigami.Units.iconSizes.small
                            Layout.preferredHeight: Kirigami.Units.iconSizes.small
                        }
                    }
                }
            }
        }

        PlasmaExtras.PlaceholderMessage {
            anchors {
                centerIn: parent
                left: parent.left
                right: parent.right
                margins: Kirigami.Units.gridUnit
            }
            visible: plasmoid.isDaemonOutdated
            iconName: "dialog-warning"
            text: i18n("supergfxd daemon is outdated")
        }

        PlasmaExtras.PlaceholderMessage {
            anchors {
                centerIn: parent
                left: parent.left
                right: parent.right
                margins: Kirigami.Units.gridUnit
            }
            visible: plasmoid.isDaemonFailing
            iconName: "dialog-error"
            text: i18n("Can't connect to daemon")
        }
    }
}
