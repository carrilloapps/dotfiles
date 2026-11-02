// CPU threads as a music equalizer: one column of segments per thread that
// lights up with its load, a peak marker that falls slowly, and the threads
// grouped as performance (P) and efficiency (E) cores on hybrid Intel CPUs.
// Hovering a column shows the thread, its core type, load and frequency
// against the maximum it can reach.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami

Item {
    id: eq
    property int threads: 0
    property var pThreads: []          // thread numbers of the P-cores
    property real pMaxGHz: 0
    property real eMaxGHz: 0
    property bool active: true
    readonly property int segments: 14
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color redLight: Qt.lighter(Kirigami.Theme.highlightColor, 1.12)
    readonly property color fg: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property bool hybrid: pThreads.length > 0 && pThreads.length < threads

    Layout.fillWidth: true
    Layout.minimumWidth: 0
    implicitWidth: 0
    implicitHeight: 104

    function isP(n) { return pThreads.indexOf(n) >= 0; }

    Row {
        id: row
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: parent.height - 16
        spacing: 3
        Repeater {
            model: eq.threads
            Item {
                id: col
                required property int index
                readonly property bool perf: eq.isP(index)
                // a little gap between the P and E groups
                readonly property bool groupStart: eq.hybrid && index > 0 && perf !== eq.isP(index - 1)
                width: (row.width - (eq.threads - 1) * row.spacing - (eq.hybrid ? 8 : 0)) / Math.max(1, eq.threads)
                       + (groupStart ? 8 : 0)
                height: row.height

                Sensors.Sensor { id: load; sensorId: "cpu/cpu" + col.index + "/usage"; updateRateLimit: 1000; enabled: eq.active }
                Sensors.Sensor { id: freq; sensorId: "cpu/cpu" + col.index + "/frequency"; updateRateLimit: 1500; enabled: eq.active }
                readonly property real v: Math.max(0, Math.min(100, isNaN(load.value) ? 0 : load.value))
                readonly property int lit: Math.round(v / 100 * eq.segments)
                property real peak: 0
                onVChanged: if (v > peak) peak = v
                Timer {                    // the peak falls back slowly
                    interval: 120; repeat: true; running: eq.active && col.peak > col.v
                    onTriggered: col.peak = Math.max(col.v, col.peak - 3)
                }

                Item {
                    id: bar
                    anchors.right: parent.right
                    width: parent.width - (col.groupStart ? 8 : 0)
                    height: parent.height
                    Column {
                        anchors.fill: parent
                        spacing: 2
                        Repeater {
                            model: eq.segments
                            Rectangle {
                                required property int index
                                // segment 0 is at the top
                                readonly property int level: eq.segments - index
                                readonly property bool on: level <= col.lit
                                width: bar.width
                                height: (bar.height - (eq.segments - 1) * 2) / eq.segments
                                radius: 1.5
                                color: !on ? Qt.alpha(Kirigami.Theme.textColor, 0.06)
                                     : level > eq.segments * 0.8 ? eq.fg
                                     : level > eq.segments * 0.55 ? eq.redLight : eq.red
                                opacity: on ? 1 : 1
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }
                        }
                    }
                    // peak marker
                    Rectangle {
                        width: bar.width
                        height: 2
                        radius: 1
                        color: eq.fg
                        opacity: col.peak > 2 ? 0.9 : 0
                        y: bar.height * (1 - col.peak / 100) - 1
                        Behavior on y { NumberAnimation { duration: 120 } }
                    }
                    HoverHandler { id: hover }
                    QQC2.ToolTip {
                        visible: hover.hovered
                        delay: 250
                        text: i18n("Thread %1 · %2", col.index,
                                   eq.hybrid ? (col.perf ? i18n("Performance core") : i18n("Efficiency core")) : i18n("Core"))
                              + "\n" + i18n("Load %1 %", Math.round(col.v))
                              + "\n" + ((isNaN(freq.value) ? 0 : freq.value) / 1000).toFixed(2) + " / "
                              + (col.perf || !eq.hybrid ? eq.pMaxGHz : eq.eMaxGHz).toFixed(1) + " GHz"
                    }
                }
            }
        }
    }

    // Group labels
    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        visible: eq.hybrid
        Text {
            width: (row.width - 8) * eq.pThreads.length / Math.max(1, eq.threads) + 4
            horizontalAlignment: Text.AlignHCenter
            text: i18n("P-cores · up to %1 GHz", eq.pMaxGHz.toFixed(1))
            color: eq.dim
            font.pixelSize: 9
        }
        Text {
            width: row.width - (row.width - 8) * eq.pThreads.length / Math.max(1, eq.threads) - 4
            horizontalAlignment: Text.AlignHCenter
            text: i18n("E-cores · up to %1 GHz", eq.eMaxGHz.toFixed(1))
            color: eq.dim
            font.pixelSize: 9
        }
    }
}
