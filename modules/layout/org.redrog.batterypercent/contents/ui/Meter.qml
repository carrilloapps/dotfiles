// Label, value and a thin accent bar (RedRog style)
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

ColumnLayout {
    id: meter
    property string label
    property string value
    property real fraction: 0
    property string hint            // optional explanation under the bar
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color redLight: Qt.lighter(Kirigami.Theme.highlightColor, 1.12)
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property string mono: "JetBrainsMono Nerd Font"
    Layout.fillWidth: true
    spacing: 4
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: meter.label.toUpperCase()
            color: meter.dim
            font.family: meter.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }
        Item { Layout.fillWidth: true }
        Text {
            text: meter.value
            color: meter.fg
            font.family: meter.mono
            font.pixelSize: 12
        }
    }
    Item {
        Layout.fillWidth: true
        height: 3
        Rectangle { anchors.fill: parent; radius: 1.5; color: Qt.alpha(Kirigami.Theme.textColor, 0.08) }
        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, meter.fraction))
            height: parent.height
            radius: 1.5
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: meter.red }
                GradientStop { position: 1; color: meter.redLight }
            }
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
        }
    }
    Text {
        Layout.fillWidth: true
        visible: meter.hint !== ""
        text: meter.hint
        color: meter.dim
        font.pixelSize: 9
        wrapMode: Text.WordWrap
        opacity: 0.85
    }
}
