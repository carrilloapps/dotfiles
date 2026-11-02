// Segmented selector in the RedRog style: a translucent strip with one option
// per segment and an accent-red highlight that slides to the active one.
// While a change is being applied (busy) the selector ignores taps, the
// requested option shows a spinner and the others dim, so a change can never
// be triggered twice.
// model: [{ text: "...", value: "..." }, ...]
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: seg
    property var model: []
    property string current: ""
    property bool enabled: true
    property bool busy: false
    property string pendingValue: ""
    signal selected(string value)
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color fg: Kirigami.Theme.textColor
    readonly property int count: model.length
    readonly property int activeIndex: {
        const want = busy && pendingValue ? pendingValue : current;
        for (let i = 0; i < count; i++)
            if (model[i].value === want) return i;
        return -1;
    }

    Layout.fillWidth: true
    implicitHeight: 30
    radius: 8
    color: Qt.alpha(Kirigami.Theme.textColor, 0.06)
    opacity: enabled ? 1 : 0.45
    Behavior on opacity { NumberAnimation { duration: 200 } }

    // Sliding highlight
    Rectangle {
        visible: seg.activeIndex >= 0
        y: 2
        height: parent.height - 4
        width: (seg.width - 4) / Math.max(1, seg.count) - 2
        x: 2 + seg.activeIndex * (seg.width - 4) / Math.max(1, seg.count) + 1
        radius: 6
        color: seg.red
        opacity: seg.busy ? 0.75 : 1
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 2
        spacing: 2
        Repeater {
            model: seg.model
            Item {
                id: option
                required property var modelData
                required property int index
                readonly property bool active: index === seg.activeIndex
                readonly property bool pending: seg.busy && modelData.value === seg.pendingValue
                Layout.fillWidth: true
                Layout.fillHeight: true

                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color: Qt.alpha(Kirigami.Theme.textColor, 0.08)
                    opacity: hover.hovered && seg.enabled && !seg.busy && !option.active ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
                Row {
                    anchors.centerIn: parent
                    spacing: 6
                    // Spinner while this option is being applied
                    Item {
                        width: option.pending ? 11 : 0
                        height: 11
                        anchors.verticalCenter: parent.verticalCenter
                        visible: option.pending
                        Canvas {
                            anchors.fill: parent
                            onPaint: {
                                const ctx = getContext("2d");
                                ctx.reset();
                                ctx.strokeStyle = "#ffffff";
                                ctx.lineWidth = 1.6;
                                ctx.lineCap = "round";
                                ctx.beginPath();
                                ctx.arc(width / 2, height / 2, width / 2 - 1, 0, Math.PI * 1.4);
                                ctx.stroke();
                            }
                            RotationAnimation on rotation {
                                running: option.pending
                                from: 0; to: 360
                                duration: 800
                                loops: Animation.Infinite
                            }
                        }
                    }
                    Text {
                        text: option.modelData.text
                        color: option.active ? "#ffffff" : seg.fg
                        opacity: seg.busy && !option.pending ? 0.45 : 1
                        font.pixelSize: 11
                        font.bold: option.active
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
                HoverHandler { id: hover; enabled: seg.enabled; cursorShape: seg.busy ? Qt.BusyCursor : Qt.PointingHandCursor }
                TapHandler {
                    enabled: seg.enabled && !seg.busy
                    onTapped: if (!option.active) seg.selected(option.modelData.value)
                }
            }
        }
    }
}
