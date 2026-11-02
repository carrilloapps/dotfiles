// A miniature RedRog window in one variant's palette: a title bar with the
// traffic lights, a sidebar, a few lines of text and a selected row in the
// accent, on that variant's window color. The current variant has an accent
// ring; a click switches to it.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: preview
    property var palette: ({})
    property string label
    property bool current: false
    signal picked()

    function col(key, fallback) { return palette[key] ? "#" + palette[key] : fallback; }
    readonly property color bg: col("bg", "#1c1c1c")
    readonly property color surface: col("surface", "#252524")
    readonly property color hi: col("surface_hi", "#313131")
    readonly property color fg: col("fg", "#efeeeb")
    readonly property color dim: col("fg_dim", "#888680")
    readonly property color accent: col("accent", "#ef3340")

    implicitHeight: frame.height + caption.implicitHeight + 6

    Rectangle {
        id: frame
        width: parent.width
        height: Math.round(width * 0.62)
        radius: 9
        color: preview.bg
        border.width: preview.current ? 2 : 1
        border.color: preview.current ? Kirigami.Theme.highlightColor : Qt.alpha(Kirigami.Theme.textColor, 0.18)
        Behavior on border.color { ColorAnimation { duration: 200 } }
        clip: true
        scale: area.containsMouse ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        // title bar with the traffic lights
        Row {
            x: 8; y: 7
            spacing: 4
            Repeater {
                model: ["#ff5f57", "#febc2e", "#28c840"]
                Rectangle { width: 6; height: 6; radius: 3; color: modelData }
            }
        }
        // sidebar
        Rectangle {
            x: 0; y: 20
            width: parent.width * 0.32; height: parent.height - 20
            color: Qt.darker(preview.bg, preview.palette.variant === "light" ? 1.03 : 1.15)
            Column {
                x: 7; y: 6
                spacing: 5
                Repeater {
                    model: 4
                    Rectangle {
                        width: (frame.width * 0.32 - 14) * (index === 1 ? 0.9 : 0.7)
                        height: 5; radius: 2.5
                        color: index === 1 ? preview.accent : Qt.alpha(preview.fg, 0.35)
                        opacity: index === 1 ? 0.85 : 1
                    }
                }
            }
        }
        // content: text lines and a button
        Column {
            x: frame.width * 0.32 + 9; y: 26
            spacing: 5
            Rectangle { width: frame.width * 0.42; height: 6; radius: 3; color: preview.fg }
            Rectangle { width: frame.width * 0.52; height: 4; radius: 2; color: preview.dim }
            Rectangle { width: frame.width * 0.46; height: 4; radius: 2; color: preview.dim }
            Item { width: 1; height: 2 }
            Rectangle {
                width: frame.width * 0.22; height: 10; radius: 5
                color: preview.accent
            }
        }
        // a field
        Rectangle {
            x: frame.width * 0.32 + 9
            y: frame.height - 16
            width: frame.width * 0.56; height: 9; radius: 4.5
            color: preview.surface
            border.width: 1
            border.color: preview.hi
        }
    }

    Text {
        id: caption
        anchors.top: frame.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: preview.label
        color: preview.current ? Kirigami.Theme.highlightColor : Kirigami.Theme.textColor
        font.pixelSize: 11
        font.bold: preview.current
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: preview.picked()
    }
}
