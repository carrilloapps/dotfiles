// Circular gauge in the RedRog style: outer arc (accent gradient) for the
// main reading, thin inner arc for a secondary one, value and label inside.
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: ring
    property string label
    property string value
    property string detail
    property real fraction: 0
    property real inner: 0
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color redLight: Qt.lighter(Kirigami.Theme.highlightColor, 1.12)
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property string mono: "JetBrainsMono Nerd Font"
    Layout.fillWidth: true
    Layout.preferredHeight: 118

    Canvas {
        id: arc
        anchors.horizontalCenter: parent.horizontalCenter
        width: 96; height: 96
        property real f: ring.fraction
        property real g: ring.inner
        onFChanged: requestPaint()
        onGChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const c = width / 2, start = Math.PI * 0.75, span = Math.PI * 1.5;
            ctx.lineCap = "round";
            ctx.strokeStyle = Qt.alpha(Kirigami.Theme.textColor, 0.08);
            ctx.lineWidth = 5;
            ctx.beginPath(); ctx.arc(c, c, c - 5, start, start + span); ctx.stroke();
            ctx.lineWidth = 2;
            ctx.beginPath(); ctx.arc(c, c, c - 13, start, start + span); ctx.stroke();
            const grad = ctx.createLinearGradient(0, height, width, 0);
            grad.addColorStop(0, ring.red);
            grad.addColorStop(1, ring.redLight);
            ctx.strokeStyle = grad;
            ctx.lineWidth = 5;
            ctx.beginPath(); ctx.arc(c, c, c - 5, start, start + span * Math.max(0.01, Math.min(1, f))); ctx.stroke();
            ctx.strokeStyle = ring.fg;
            ctx.globalAlpha = 0.7;
            ctx.lineWidth = 2;
            ctx.beginPath(); ctx.arc(c, c, c - 13, start, start + span * Math.max(0.01, Math.min(1, g))); ctx.stroke();
        }
    }
    Column {
        anchors.centerIn: arc
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.value
            color: ring.fg
            font.family: ring.mono
            font.pixelSize: 20
            font.bold: true
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label
            color: ring.red
            font.family: ring.mono
            font.pixelSize: 9
            font.letterSpacing: 1.5
        }
    }
    Text {
        anchors.horizontalCenter: arc.horizontalCenter
        anchors.top: arc.bottom
        anchors.topMargin: 2
        text: ring.detail
        color: ring.dim
        font.family: ring.mono
        font.pixelSize: 10
        elide: Text.ElideRight
        width: ring.width
        horizontalAlignment: Text.AlignHCenter
    }
}
