// Compact readings in two columns of label / value pairs (RedRog style):
// rows is a list of [label, value]; empty values are left out, and a value
// too long for its half is elided instead of running into the other one
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

GridLayout {
    id: facts
    property var rows: []
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property string mono: "JetBrainsMono Nerd Font"
    Layout.fillWidth: true
    columns: 4
    columnSpacing: 20
    rowSpacing: 3
    Repeater {
        model: facts.rows.filter(r => r[1] !== "" && r[1] !== undefined)
        delegate: Item {
            required property var modelData
            required property int index
            Layout.fillWidth: true
            Layout.preferredWidth: 1     // both halves equal
            Layout.columnSpan: 2
            implicitHeight: pair.implicitHeight
            RowLayout {
                id: pair
                anchors.fill: parent
                spacing: 6
                Text {
                    text: modelData[0].toUpperCase()
                    color: facts.dim
                    font.family: facts.mono
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideRight
                    text: modelData[1]
                    color: facts.fg
                    font.family: facts.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
