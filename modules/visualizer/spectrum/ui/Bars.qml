// Spectrum analyzer along the whole bottom edge: slim rounded bars in a
// vertical gradient, a thin peak marker over each bar that falls slowly, and
// a blurred glow behind everything.
import QtQuick
import QtQuick.Effects

Item {
    id: bars

    readonly property var values: root.values
    readonly property int count: root.barCount
    readonly property real slot: width / count
    readonly property real barWidth: Math.max(3, Math.round(slot * 0.45))
    readonly property real maxHeight: height * 0.42
    property var peaks: []

    // Peaks jump up with the bars and fall back at a steady speed
    onValuesChanged: {
        const p = peaks.length === values.length ? peaks.slice() : values.slice();
        for (let i = 0; i < values.length; i++)
            p[i] = Math.max(values[i], p[i] - 0.012);
        peaks = p;
    }

    MultiEffect {
        anchors.fill: content
        source: content
        blurEnabled: true
        blur: 1.0
        blurMax: 40
        brightness: 0.2
        opacity: 0.7
    }

    Item {
        id: content
        anchors.fill: parent
        layer.enabled: true

        Repeater {
            model: bars.count
            Item {
                required property int index
                readonly property real value: bars.values[index] ?? 0
                readonly property real peak: bars.peaks[index] ?? 0
                x: index * bars.slot + (bars.slot - bars.barWidth) / 2
                width: bars.barWidth
                height: bars.height

                Rectangle {
                    width: parent.width
                    height: Math.max(width, value * bars.maxHeight)
                    anchors.bottom: parent.bottom
                    radius: width / 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: root.tipColor }
                        GradientStop { position: 0.4; color: root.middleColor }
                        GradientStop { position: 1.0; color: root.baseColor }
                    }
                    opacity: 0.85
                }

                // Peak marker
                Rectangle {
                    width: parent.width
                    height: 3
                    radius: 1.5
                    y: parent.height - peak * bars.maxHeight - 8
                    color: root.tipColor
                    opacity: peak > 0.03 ? 0.9 : 0
                }
            }
        }
    }
}
