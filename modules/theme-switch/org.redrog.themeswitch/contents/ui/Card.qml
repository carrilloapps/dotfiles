// macOS-style card in the RedRog colours: rounded, a faint translucent fill
// with a hairline edge, a bold title with a small red accent bar, and a soft
// staggered entrance (fade and rise) each time the panel opens.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: card
    property string title
    property string note            // small text at the right of the title
    property bool shown: true       // drives the entrance animation
    property int order: 0           // position in the stagger
    default property alias content: body.data
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitWidth: 0
    implicitHeight: column.implicitHeight + 24

    // Entrance
    opacity: 0
    transform: Translate { id: lift; y: 8 }
    states: State {
        name: "in"; when: card.shown
        PropertyChanges { target: card; opacity: 1 }
        PropertyChanges { target: lift; y: 0 }
    }
    transitions: Transition {
        to: "in"
        SequentialAnimation {
            PauseAnimation { duration: card.order * 45 }
            ParallelAnimation {
                NumberAnimation { target: card; property: "opacity"; duration: 260; easing.type: Easing.OutCubic }
                NumberAnimation { target: lift; property: "y"; duration: 320; easing.type: Easing.OutCubic }
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: Qt.alpha(Kirigami.Theme.textColor, 0.05)
        border.width: 1
        border.color: Qt.alpha(Kirigami.Theme.textColor, 0.07)
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        RowLayout {
            Layout.fillWidth: true
            spacing: 7
            Rectangle { width: 3; height: 12; radius: 1.5; color: card.red }
            Text {
                text: card.title
                color: card.fg
                font.pixelSize: 12
                font.bold: true
            }
            Text {
                // takes the remaining width and elides, so a long note never
                // widens the card
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
                text: card.note
                color: card.dim
                font.pixelSize: 10
            }
        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 10
        }
        // a stretched card keeps its content at the top
        Item { Layout.fillHeight: true }
    }
}
