// A block that unfolds and folds back smoothly: its height follows the
// content (clipped while it moves) and it fades in and out; folded, it leaves
// the layout entirely, so it adds no spacing
import QtQuick
import QtQuick.Layouts

Item {
    id: block
    property bool open: false
    default property alias content: inner.data
    Layout.fillWidth: true
    implicitHeight: open ? inner.implicitHeight : 0
    visible: open || implicitHeight > 0.5
    opacity: open ? 1 : 0
    clip: true
    Behavior on implicitHeight { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutQuad } }
    ColumnLayout {
        id: inner
        width: block.width
        spacing: 10
        // slides down a little as it appears
        transform: Translate { y: block.open ? 0 : -6; Behavior on y { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } } }
    }
}
