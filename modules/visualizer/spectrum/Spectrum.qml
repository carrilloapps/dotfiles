// RedRog Spectrum: whatever is playing (any app, through CAVA) drawn on the
// desktop, whatever the wallpaper, as either
//   - "halo": a ring of bars in the center of the screen that pulses with the
//     bass, over a soft dark vignette, or
//   - "bars": spectrum bars along the whole bottom edge with falling peaks.
// One transparent layer per screen (Wayland layer-shell, the "bottom" layer:
// over the wallpaper, under every window and panel), which lets every click
// through to the desktop; screens connected later get theirs. The spectrum
// fades in when audio starts and out after a few seconds of silence; while
// windows cover a screen the compositor stops drawing its layer.
//
// The user's settings live in ~/.config/redrog/spectrum.json (written by the
// "Espectro de audio" settings window, Settings.qml) and are picked up while
// it runs. Colors follow the RedRog palette, set by modules/visualizer.
//
// Run by redrog-spectrum.service (qml6, with the layer-shell integration).
// CAVA runs through the process plugin shipped with Kurve
// (plasma6-applets-kurve).
import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell
import com.github.luisbocanegra.audiovisualizer.process

QtObject {
    id: app

    readonly property color baseColor: "@BASE@"
    readonly property color middleColor: "@MIDDLE@"
    readonly property color tipColor: "@TIP@"

    // ── Settings (spectrum.json; these are the defaults) ─────────────────────
    readonly property string configUrl: "file://@CONFIG@"
    property string configText: ""
    property var cfg: ({})
    readonly property bool enabled: cfg.enabled !== false
    readonly property string style: cfg.style === "bars" ? "bars" : "halo"
    readonly property int framerate: clamp(cfg.framerate, 30, 144, 60)
    readonly property int smoothing: clamp(cfg.smoothing, 0, 100, 77)
    readonly property bool autoSensitivity: cfg.autoSensitivity !== false
    readonly property int sensitivity: clamp(cfg.sensitivity, 10, 300, 100)
    readonly property real strength: clamp(cfg.opacity, 20, 100, 100) / 100
    readonly property int fadeSeconds: clamp(cfg.fadeSeconds, 1, 30, 3)

    function clamp(v, lo, hi, fallback) {
        const n = Number(v);
        return isNaN(n) || v === undefined || v === null ? fallback : Math.min(hi, Math.max(lo, n));
    }

    function readConfig() {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE || xhr.responseText === app.configText)
                return;
            app.configText = xhr.responseText;
            try {
                app.cfg = JSON.parse(xhr.responseText || "{}");
            } catch (e) {
                // a half-written file: keep the last good settings
            }
        };
        xhr.open("GET", configUrl);
        xhr.send();
    }

    // Spectrum values, 0-1, low to high frequencies, shared by every screen
    property var values: []
    // the bars style follows the widest screen
    readonly property int barCount: {
        if (style === "halo")
            return 48;
        let widest = 0;
        for (const s of Qt.application.screens)
            widest = Math.max(widest, s.width);
        return Math.max(32, Math.round(widest / 14));
    }
    // True while there is sound; drives the fade in/out
    property bool active: false

    readonly property string cavaConfig: `[general]
framerate=${framerate}
bars=${barCount}
autosens=${autoSensitivity ? 1 : 0}
sensitivity=${sensitivity}
lower_cutoff_freq=40
higher_cutoff_freq=12000
sleep_timer=3
[output]
method=raw
raw_target=/dev/stdout
data_format=ascii
ascii_max_range=1000
channels=mono
mono_option=average
[smoothing]
noise_reduction=${smoothing}
monstercat=1
`

    function startCava() {
        if (!enabled) {
            cava.stop();
            return;
        }
        cava.command = ["bash", "-c", "exec cava -p /dev/stdin <<'EOF'\n" + cavaConfig + "EOF\n"];
        cava.restart();
    }

    onCavaConfigChanged: startTimer.restart()
    onEnabledChanged: startTimer.restart()
    Component.onCompleted: {
        readConfig();
        startTimer.restart();
    }

    property list<QtObject> parts: [
        Process {
            id: cava
            // CAVA ends when the audio server is not up yet (an early login)
            // or restarts: start it again
            onRunningChanged: if (!running && app.enabled) retry.restart()
            onStdoutChanged: {
                let out = stdout.trim();
                if (out.endsWith(";"))
                    out = out.slice(0, -1);
                if (out === "")
                    return;
                const v = out.split(";").map(x => parseInt(x, 10) / 1000);
                app.values = v;
                if (v.some(x => x > 0.02)) {
                    app.active = true;
                    idle.restart();
                }
            }
        },
        // start CAVA once the screens and the settings have settled
        Timer {
            id: startTimer
            interval: 1200
            onTriggered: app.startCava()
        },
        Timer {
            id: retry
            interval: 3000
            onTriggered: if (app.enabled && !cava.running) app.startCava()
        },
        Timer {
            id: idle
            interval: app.fadeSeconds * 1000
            onTriggered: app.active = false
        },
        // the settings window saves while this runs: a small file read
        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: app.readConfig()
        },
        // one layer per screen, also for screens connected later
        Instantiator {
            model: Qt.application.screens
            delegate: Window {
                id: root

                // what Halo.qml and Bars.qml read
                readonly property var values: app.values
                readonly property int barCount: app.barCount
                readonly property color baseColor: app.baseColor
                readonly property color middleColor: app.middleColor
                readonly property color tipColor: app.tipColor

                screen: modelData
                // placed on its screen too: Qt moves a window to the screen
                // its position falls on when it shows, and (0, 0) is only one
                x: modelData.virtualX
                y: modelData.virtualY
                width: modelData.width
                height: modelData.height
                color: "transparent"
                flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus
                // shown only once its screen is set: the layer is created on
                // the screen the window has when it first shows
                visible: false
                Component.onCompleted: visible = true

                // a desktop layer for KWin (as it is: under every window, no
                // input): window effects such as the rounded-corners outline
                // leave it alone, which a normal window's scope would get
                LayerShell.Window.scope: "desktop"
                LayerShell.Window.layer: LayerShell.Window.LayerBottom
                LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                                           | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
                // the whole screen, under the panels too: the halo stays centered
                LayerShell.Window.exclusionZone: -1
                LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
                LayerShell.Window.wantsToBeOnActiveScreen: false
                // the layer goes on the screen of this window (deprecated, but its
                // replacement takes a QScreen, which QML cannot pass)
                LayerShell.Window.screenConfiguration: LayerShell.Window.ScreenFromQWindow

                Item {
                    anchors.fill: parent
                    opacity: app.enabled && app.active ? app.strength : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutQuad } }

                    Loader {
                        anchors.fill: parent
                        // nothing drawn (or kept in memory) while it is silent
                        active: parent.visible
                        source: app.style === "bars" ? "ui/Bars.qml" : "ui/Halo.qml"
                    }
                }
            }
        }
    ]
}
