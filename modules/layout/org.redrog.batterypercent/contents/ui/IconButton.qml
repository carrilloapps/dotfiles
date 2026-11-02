// Small round icon button for the RedRog panel's header: a faint fill that
// brightens on hover, red while highlighted, and a tooltip
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami as Kirigami

Rectangle {
    id: button
    property string icon
    property string tip
    property bool highlighted: false
    readonly property bool hovered: hover.hovered
    property bool tipVisible: hovered
    signal tapped()
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color fg: Kirigami.Theme.textColor

    implicitWidth: 26
    implicitHeight: 26
    radius: 13
    color: highlighted ? Qt.alpha(Kirigami.Theme.highlightColor, 0.18)
         : hover.hovered ? Qt.alpha(Kirigami.Theme.textColor, 0.12) : Qt.alpha(Kirigami.Theme.textColor, 0.06)
    border.width: 1
    border.color: highlighted ? Qt.alpha(Kirigami.Theme.highlightColor, 0.45) : Qt.alpha(Kirigami.Theme.textColor, 0.08)
    scale: tap.pressed ? 0.9 : 1
    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
    Kirigami.Icon {
        anchors.centerIn: parent
        width: 14
        height: 14
        source: button.icon
        color: button.highlighted ? button.red : button.fg
        isMask: true
    }
    HoverHandler { id: hover; cursorShape: button.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    TapHandler { id: tap; enabled: button.enabled; onTapped: button.tapped() }
    PlasmaComponents.ToolTip { text: button.tip; visible: button.tipVisible && button.tip !== "" }
}
