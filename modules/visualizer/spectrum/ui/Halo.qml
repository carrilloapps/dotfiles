// Ring of spectrum bars in the center of the screen, mirrored left and right
// (bass at the top), around the RedRog emblem and over a soft dark vignette.
// The whole ring breathes with the bass and has a blurred glow behind it.
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: halo

    readonly property var values: root.values
    readonly property int half: root.barCount
    readonly property int count: half * 2
    readonly property real radius: Math.min(width, height) * 0.16
    readonly property real maxLength: Math.min(width, height) * 0.17
    readonly property real barWidth: Math.max(3, Math.round(2 * Math.PI * radius / count * 0.42))
    // Average of the lowest bands, 0-1
    readonly property real bass: {
        let s = 0;
        const n = Math.min(6, values.length);
        for (let i = 0; i < n; i++) s += values[i];
        return n > 0 ? s / n : 0;
    }

    function valueAt(i) {
        // right half clockwise from the top, left half mirrored
        const k = i < half ? i : count - 1 - i;
        return values[k] ?? 0;
    }

    // Vignette: darkens the center a little so the ring stands out
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeWidth: -1
            fillGradient: RadialGradient {
                centerX: halo.width / 2; centerY: halo.height / 2
                focalX: centerX; focalY: centerY
                centerRadius: halo.radius * 3.2
                focalRadius: 0
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.3) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            PathRectangle { x: 0; y: 0; width: halo.width; height: halo.height }
        }
    }

    // Glow: a blurred, brightened copy of the ring behind it
    MultiEffect {
        anchors.fill: ring
        source: ring
        blurEnabled: true
        blur: 1.0
        blurMax: 48
        brightness: 0.25
        opacity: 0.55 + halo.bass * 0.45
    }

    Item {
        id: ring
        anchors.fill: parent
        layer.enabled: true

        Item {
            id: center
            x: halo.width / 2
            y: halo.height / 2
            scale: 1 + halo.bass * 0.08
            Behavior on scale { NumberAnimation { duration: 90 } }

            // Thin inner circle
            Rectangle {
                width: (halo.radius - 10) * 2
                height: width
                x: -width / 2
                y: -height / 2
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(root.middleColor.r, root.middleColor.g, root.middleColor.b, 0.55 + halo.bass * 0.45)
            }

            Repeater {
                model: halo.count
                Rectangle {
                    required property int index
                    readonly property real len: halo.barWidth + halo.valueAt(index) * halo.maxLength
                    width: halo.barWidth
                    height: len
                    radius: width / 2
                    x: -width / 2
                    y: -halo.radius - len
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.tipColor }
                        GradientStop { position: 0.45; color: root.middleColor }
                        GradientStop { position: 1.0; color: root.baseColor }
                    }
                    transform: Rotation {
                        origin.x: halo.barWidth / 2
                        origin.y: halo.radius + len
                        angle: index * 360 / halo.count
                    }
                }
            }
        }
    }

    // RedRog emblem, outside the glow layer so it stays crisp and flat
    Image {
        source: "../images/logo.svg"
        width: halo.radius * 1.15
        height: width
        sourceSize: Qt.size(width * 2, height * 2)
        x: (halo.width - width) / 2
        y: (halo.height - height) / 2
        smooth: true
        scale: 1 + halo.bass * 0.06
        Behavior on scale { NumberAnimation { duration: 90 } }
    }
}
