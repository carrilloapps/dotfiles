// The desktop audio spectrum's switch in the system tray: four bars in the
// theme's text color (images/spectrum.svg). On the top bar only while the spectrum is on (an active
// item); while it is off it waits in the tray's hidden items, from where it
// turns it on again. A click turns it on or off; the context menu opens its
// settings.
//
// The switch itself is redrog-spectrum-ctl (modules/visualizer), which stops
// the spectrum altogether when off: no CAVA, no layers, no GPU work.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property string tool: "$HOME/.local/lib/redrog/redrog-spectrum-ctl"
    property bool on: false
    property bool busy: false

    Plasmoid.status: root.on || root.busy ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

    toolTipMainText: i18n("Audio spectrum")
    toolTipSubText: root.on ? i18n("On: click to turn it off") : i18n("Off: click to turn it on")

    // a cheap check (systemctl), every few seconds and right after a click
    P5Support.DataSource {
        id: status
        engine: "executable"
        readonly property string cmd: "sh -c '\"" + root.tool + "\" status'"
        connectedSources: [cmd]
        interval: root.busy ? 1000 : 5000
        onNewData: (source, data) => {
            const now = (data["stdout"] || "").trim() === "on";
            if (root.busy && now !== root.on)
                root.busy = false;
            root.on = now;
        }
    }
    P5Support.DataSource {
        id: run
        engine: "executable"
        onNewData: (source, data) => {
            disconnectSource(source);
            root.busy = false;
            status.connectSource(status.cmd);
        }
    }
    function toggle() {
        root.busy = true;
        run.connectSource("sh -c '\"" + root.tool + "\" toggle'");
    }

    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: root.on ? i18n("Turn off") : i18n("Turn on")
            icon.name: root.on ? "media-playback-stop" : "media-playback-start"
            onTriggered: root.toggle()
        },
        PlasmaCore.Action {
            text: i18n("Spectrum settings…")
            icon.name: "configure"
            onTriggered: run.connectSource("gtk-launch redrog-spectrum-settings")
        }
    ]

    compactRepresentation: MouseArea {
        id: compact
        hoverEnabled: true
        Layout.minimumWidth: Kirigami.Units.iconSizes.small
        Layout.preferredWidth: Kirigami.Units.iconSizes.small
        onClicked: root.toggle()

        Kirigami.Icon {
            anchors.centerIn: parent
            width: Math.round(Math.min(parent.width, parent.height))
            height: width
            source: Qt.resolvedUrl("../images/spectrum.svg")
            // one flat color: the theme's text, or the one the top bar's
            // colorizer sets on it over the wallpaper
            isMask: true
            color: Kirigami.Theme.textColor
            opacity: root.on ? 1 : 0.55
        }
    }

    // what a click on its name in the tray's hidden items opens: on/off and
    // its settings
    fullRepresentation: ColumnLayout {
        Layout.preferredWidth: Kirigami.Units.gridUnit * 14
        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            Layout.margins: Kirigami.Units.largeSpacing
            PlasmaComponents.Label {
                Layout.fillWidth: true
                text: i18n("Audio spectrum")
                font.weight: Font.DemiBold
            }
            PlasmaComponents.Switch {
                checked: root.on
                enabled: !root.busy
                onToggled: root.toggle()
            }
        }
        PlasmaComponents.ToolButton {
            Layout.alignment: Qt.AlignRight
            Layout.margins: Kirigami.Units.smallSpacing
            text: i18n("Spectrum settings…")
            icon.name: "configure"
            onClicked: {
                run.connectSource("gtk-launch redrog-spectrum-settings");
                root.expanded = false;
            }
        }
    }
}
