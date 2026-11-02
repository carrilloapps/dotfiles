// RedRog system hologram for the desktop: CPU and GPU rings plus thin bars for
// memory, frequency, fans, disk, network and battery, drawn as floating lines
// with a soft red glow (no solid background) in the theme colors: on a dark
// glass in the dark variant, on a light one in the light variant.
//
// Readings come from KDE's sensor service (ksystemstats). The NVIDIA card is
// never woken up by this widget: its temperature is only read while
// something else already keeps it active, otherwise it shows as resting and
// the Intel GPU is shown instead.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasma5support as P5Support
import org.kde.kirigami as Kirigami
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    // the theme's colors (RedRog or RedRog Light): accent, text, softer text
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color redLight: Qt.lighter(red, 1.15)
    readonly property color text: Kirigami.Theme.textColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property color glass: Kirigami.Theme.backgroundColor
    readonly property bool lightTheme: Kirigami.ColorUtils.brightnessForColor(glass) === Kirigami.ColorUtils.Light
    readonly property string mono: "JetBrainsMono Nerd Font"

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    // ── Sensors ─────────────────────────────────────────────────────────────
    component Probe: Sensors.Sensor { updateRateLimit: 2000 }
    Probe { id: cpuTemp; sensorId: "cpu/all/averageTemperature" }
    Probe { id: cpuUse; sensorId: "cpu/all/usage" }
    Probe { id: cpuFreq; sensorId: "cpu/all/averageFrequency" }
    Probe { id: memUsed; sensorId: "memory/physical/used" }
    Probe { id: memTotal; sensorId: "memory/physical/total" }
    Probe { id: memPct; sensorId: "memory/physical/usedPercent" }
    Probe { id: fanCpu; sensorId: "lmsensors/asus-isa-000a/fan1" }
    Probe { id: fanGpu; sensorId: "lmsensors/asus-isa-000a/fan2" }
    Probe { id: diskPct; sensorId: "disk/all/usedPercent" }
    Probe { id: netDown; sensorId: "network/all/download" }
    Probe { id: netUp; sensorId: "network/all/upload" }
    Probe { id: battery; sensorId: "power/battery_BAT1/chargePercentage" }
    Probe { id: igpuTemp; sensorId: "gpu/gpu1/temperature" }
    Probe { id: igpuUse; sensorId: "gpu/gpu1/usage" }

    // NVIDIA: first its power state (a sysfs read, which never wakes it),
    // then, only while it is already active, temperature, load and power
    property string dgpuState: "suspended"
    property real dgpuTemp: 0
    property real dgpuUse: 0
    property real dgpuPower: 0
    readonly property bool dgpuActive: dgpuState === "active"
    readonly property string stateCmd: "sh -c 'cat /sys/bus/pci/drivers/nvidia/0000:*/power/runtime_status 2>/dev/null | head -1'"
    readonly property string queryCmd: "nvidia-smi --query-gpu=temperature.gpu,utilization.gpu,power.draw --format=csv,noheader,nounits"

    P5Support.DataSource {
        id: shell
        engine: "executable"
        connectedSources: [root.stateCmd]
        interval: 4000
        onNewData: (source, data) => {
            const out = (data["stdout"] || "").trim();
            if (source === root.stateCmd) {
                root.dgpuState = out || "suspended";
            } else if (source === root.queryCmd && out) {
                const v = out.split(",").map(x => parseFloat(x));
                root.dgpuTemp = v[0] || 0;
                root.dgpuUse = v[1] || 0;
                root.dgpuPower = v[2] || 0;
            }
        }
    }
    // Every 15 s and only while active, so polling never keeps it awake
    Timer {
        interval: 15000
        repeat: true
        triggeredOnStart: true
        running: root.dgpuActive
        onTriggered: {
            shell.disconnectSource(root.queryCmd);
            shell.connectSource(root.queryCmd);
        }
    }

    function num(v) { return isNaN(v) ? 0 : v; }
    function gb(bytes) { return (num(bytes) / 1073741824).toFixed(1); }
    function rate(bps) {
        const v = num(bps);
        if (v >= 1048576) return (v / 1048576).toFixed(1) + " MB/s";
        if (v >= 1024) return Math.round(v / 1024) + " KB/s";
        return Math.round(v) + " B/s";
    }
    // Temperature as a 0-1 fraction of a 30-100 °C range, for the rings
    function heat(t) { return Math.max(0, Math.min(1, (num(t) - 30) / 70)); }

    fullRepresentation: Item {
        Layout.preferredWidth: 340
        Layout.preferredHeight: 470
        Layout.minimumWidth: 300
        Layout.minimumHeight: 420

        // Glow: a blurred, brightened copy of the hologram behind it
        MultiEffect {
            anchors.fill: holo
            source: holo
            blurEnabled: true
            blur: 1.0
            blurMax: 32
            brightness: 0.15
            opacity: 0.55
        }

        Item {
            id: holo
            anchors.fill: parent
            layer.enabled: true

            // Glass behind everything in the theme's window color (dark, or
            // light in the light variant), so the readings stay legible over
            // any wallpaper, with a faint red edge
            Rectangle {
                anchors.fill: parent
                radius: 14
                color: Qt.alpha(root.glass, root.lightTheme ? 0.72 : 0.5)
                border.width: 1
                border.color: Qt.alpha(root.red, 0.25)
            }

            // Faint scan lines, the hologram texture
            Column {
                anchors.fill: parent
                spacing: 3
                opacity: 0.06
                Repeater {
                    model: Math.floor(parent.height / 4)
                    Rectangle { width: parent.width; height: 1; color: root.red }
                }
            }

            // Corner brackets
            Repeater {
                model: 4
                Item {
                    readonly property bool atRight: index % 2 === 1
                    readonly property bool atBottom: index > 1
                    width: 22; height: 22
                    x: atRight ? holo.width - width : 0
                    y: atBottom ? holo.height - height : 0
                    Rectangle { width: parent.width; height: 2; color: root.red; y: atBottom ? parent.height - 2 : 0 }
                    Rectangle { width: 2; height: parent.height; color: root.red; x: atRight ? parent.width - 2 : 0 }
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: i18n("SYSTEM")
                        color: root.text
                        font.family: root.mono
                        font.pixelSize: 13
                        font.letterSpacing: 4
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Qt.formatTime(clock.now, "hh:mm")
                        color: root.dim
                        font.family: root.mono
                        font.pixelSize: 12
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: root.red }
                        GradientStop { position: 1; color: "transparent" }
                    }
                }

                // Rings
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 18
                    Ring {
                        label: "CPU"
                        value: Math.round(root.num(cpuTemp.value)) + "°"
                        detail: Math.round(root.num(cpuUse.value)) + " %"
                        fraction: root.heat(cpuTemp.value)
                        inner: root.num(cpuUse.value) / 100
                    }
                    Ring {
                        label: root.dgpuActive ? "RTX 3050" : "Iris Xe"
                        // The Intel GPU has no temperature sensor: show its load
                        value: root.dgpuActive ? Math.round(root.dgpuTemp) + "°"
                               : root.num(igpuTemp.value) > 0 ? Math.round(igpuTemp.value) + "°"
                               : Math.round(root.num(igpuUse.value)) + "%"
                        detail: root.dgpuActive
                                ? Math.round(root.dgpuUse) + " % · " + Math.round(root.dgpuPower) + " W"
                                : i18n("NVIDIA resting")
                        fraction: root.dgpuActive ? root.heat(root.dgpuTemp)
                                  : root.num(igpuTemp.value) > 0 ? root.heat(igpuTemp.value)
                                  : root.num(igpuUse.value) / 100
                        inner: (root.dgpuActive ? root.dgpuUse : root.num(igpuUse.value)) / 100
                    }
                }

                // Bars
                Meter {
                    label: i18n("Memory")
                    value: root.gb(memUsed.value) + " / " + Math.round(root.num(memTotal.value) / 1073741824) + " GB"
                    fraction: root.num(memPct.value) / 100
                }
                Meter {
                    label: i18n("Frequency")
                    value: (root.num(cpuFreq.value) / 1000).toFixed(2) + " GHz"
                    fraction: root.num(cpuFreq.value) / 4500
                }
                Meter {
                    label: i18n("Fans")
                    value: Math.round(root.num(fanCpu.value)) + " · " + Math.round(root.num(fanGpu.value)) + " rpm"
                    fraction: Math.max(root.num(fanCpu.value), root.num(fanGpu.value)) / 6500
                }
                Meter {
                    label: i18n("Disk")
                    value: Math.round(root.num(diskPct.value)) + " %"
                    fraction: root.num(diskPct.value) / 100
                }
                Meter {
                    label: i18n("Network")
                    value: "↓ " + root.rate(netDown.value) + "   ↑ " + root.rate(netUp.value)
                    fraction: Math.min(1, root.num(netDown.value) / 12500000)
                }
                Meter {
                    label: i18n("Battery")
                    value: Math.round(root.num(battery.value)) + " %"
                    fraction: root.num(battery.value) / 100
                }
                Item { Layout.fillHeight: true }
            }
        }

        QtObject {
            id: clock
            property date now: new Date()
        }
        Timer { interval: 10000; running: true; repeat: true; onTriggered: clock.now = new Date() }
    }

    // Circular gauge: outer arc for temperature, thin inner arc for load
    component Ring: Item {
        id: ring
        readonly property color red: root.red
        readonly property color redLight: root.redLight
        readonly property color fg: root.text
        readonly property color dim: root.dim
        readonly property string mono: "JetBrainsMono Nerd Font"
        property string label
        property string value
        property string detail
        property real fraction: 0
        property real inner: 0
        Layout.fillWidth: true
        Layout.preferredHeight: 136

        Canvas {
            id: arc
            anchors.centerIn: parent
            width: 116; height: 116
            property real f: ring.fraction
            property real g: ring.inner
            onFChanged: requestPaint()
            onGChanged: requestPaint()
            // repainted when the theme (light/dark) changes
            property color ink: ring.fg
            onInkChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const c = width / 2, start = Math.PI * 0.75, span = Math.PI * 1.5;
                ctx.lineCap = "round";
                // tracks
                ctx.strokeStyle = Qt.alpha(ring.fg, 0.08);
                ctx.lineWidth = 6;
                ctx.beginPath(); ctx.arc(c, c, c - 6, start, start + span); ctx.stroke();
                ctx.lineWidth = 2;
                ctx.beginPath(); ctx.arc(c, c, c - 16, start, start + span); ctx.stroke();
                // temperature
                const grad = ctx.createLinearGradient(0, height, width, 0);
                grad.addColorStop(0, ring.red);
                grad.addColorStop(1, ring.redLight);
                ctx.strokeStyle = grad;
                ctx.lineWidth = 6;
                ctx.beginPath(); ctx.arc(c, c, c - 6, start, start + span * Math.max(0.01, f)); ctx.stroke();
                // load
                ctx.strokeStyle = ring.fg;
                ctx.globalAlpha = 0.7;
                ctx.lineWidth = 2;
                ctx.beginPath(); ctx.arc(c, c, c - 16, start, start + span * Math.max(0.01, Math.min(1, g))); ctx.stroke();
            }
        }
        Column {
            anchors.centerIn: arc
            spacing: 0
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ring.value
                color: ring.fg
                font.family: ring.mono
                font.pixelSize: 26
                font.bold: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: ring.label
                color: ring.red
                font.family: ring.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
        Text {
            anchors.horizontalCenter: arc.horizontalCenter
            anchors.top: arc.bottom
            anchors.topMargin: 2
            text: ring.detail
            color: ring.dim
            font.family: ring.mono
            font.pixelSize: 11
        }
    }

    // Label, value and a thin bar with a bright tip
    component Meter: ColumnLayout {
        id: meter
        readonly property color red: root.red
        readonly property color redLight: root.redLight
        readonly property color fg: root.text
        readonly property color dim: root.dim
        readonly property string mono: "JetBrainsMono Nerd Font"
        property string label
        property string value
        property real fraction: 0
        Layout.fillWidth: true
        spacing: 4
        RowLayout {
            Layout.fillWidth: true
            Text {
                text: meter.label.toUpperCase()
                color: meter.dim
                font.family: meter.mono
                font.pixelSize: 10
                font.letterSpacing: 2
            }
            Item { Layout.fillWidth: true }
            Text {
                text: meter.value
                color: meter.fg
                font.family: meter.mono
                font.pixelSize: 12
            }
        }
        Item {
            Layout.fillWidth: true
            height: 3
            Rectangle { anchors.fill: parent; radius: 1.5; color: Qt.alpha(meter.fg, 0.08) }
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, meter.fraction))
                height: parent.height
                radius: 1.5
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: meter.red }
                    GradientStop { position: 1; color: meter.redLight }
                }
                Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            }
        }
    }
}
