// The tray glyph: a sun (eight short rays) while light, a crescent moon while
// dark, in one flat color like the other tray icons. Switching turns it a
// quarter and morphs one into the other; in automatic mode a small dot in the
// accent color sits at its lower right. While a switch runs it turns slowly.
import QtQuick
import org.kde.kirigami as Kirigami

Item {
    id: glyph
    property real size: 16
    property bool light: false
    property color color: "white"
    property color accent: "red"
    property bool busy: false
    property bool auto: false
    // 0 = moon, 1 = sun
    property real morph: light ? 1 : 0
    Behavior on morph { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }

    width: size
    height: size

    // turns slowly while a switch runs
    Item {
        id: spinner
        anchors.fill: parent
        RotationAnimator on rotation {
            id: spin
            running: glyph.busy
            from: 0
            to: 360
            duration: 1600
            loops: Animation.Infinite
            onRunningChanged: if (!running) spinner.rotation = 0
        }

        Canvas {
            id: canvas
            anchors.fill: parent
            rotation: (1 - glyph.morph) * -90
            renderStrategy: Canvas.Cooperative
            // its own text color: the glyph's, or the one the top bar's
            // colorizer sets on it over the wallpaper
            Kirigami.Theme.textColor: glyph.color
            readonly property color ink: Kirigami.Theme.textColor
            onInkChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                const s = width, c = s / 2, m = glyph.morph;
                ctx.reset();
                ctx.fillStyle = canvas.ink;
                ctx.strokeStyle = canvas.ink;
                // the disc: smaller for the sun, which has rays around it
                const r = s * (0.45 - 0.19 * m);
                ctx.beginPath();
                ctx.arc(c, c, r, 0, Math.PI * 2);
                ctx.fill();
                // the moon's bite: a disc cut out, sliding away as it turns into the sun
                if (m < 1) {
                    ctx.globalCompositeOperation = "destination-out";
                    const off = r * (0.62 + 1.4 * m);
                    ctx.beginPath();
                    ctx.arc(c + off, c - off * 0.72, r * 0.86, 0, Math.PI * 2);
                    ctx.fill();
                    ctx.globalCompositeOperation = "source-over";
                }
                // the sun's rays, growing in as it appears
                if (m > 0) {
                    ctx.lineWidth = Math.max(1.4, s * 0.09);
                    ctx.lineCap = "round";
                    ctx.globalAlpha = m;
                    for (let i = 0; i < 8; i++) {
                        const a = i * Math.PI / 4;
                        const r1 = s * 0.36, r2 = s * (0.36 + 0.13 * m);
                        ctx.beginPath();
                        ctx.moveTo(c + Math.cos(a) * r1, c + Math.sin(a) * r1);
                        ctx.lineTo(c + Math.cos(a) * r2, c + Math.sin(a) * r2);
                        ctx.stroke();
                    }
                    ctx.globalAlpha = 1;
                }
            }
            Connections {
                target: glyph
                function onMorphChanged() { canvas.requestPaint(); }
                function onColorChanged() { canvas.requestPaint(); }
                function onSizeChanged() { canvas.requestPaint(); }
            }
        }
    }

    // automatic mode
    Rectangle {
        visible: glyph.auto
        width: Math.max(4, Math.round(glyph.size * 0.3))
        height: width
        radius: width / 2
        color: glyph.accent
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -1
        anchors.bottomMargin: -1
    }
}
