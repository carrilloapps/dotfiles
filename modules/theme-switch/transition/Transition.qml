// RedRog light/dark transition, in the manner of Samsung DeX: every screen
// fades into the new variant's color and the boot splash's Arch logo charges
// in the middle; only then does the switch happen, unseen behind it (the
// desktop repainting piece by piece, the compositor's brief pauses while
// decorations and colors change, the check that every part took the new
// variant), and once it is done the logo flashes and the veil fades away over
// the new look.
//
// Started by redrog-theme-switch (modules/theme-switch):
//   qml6 Transition.qml -- RUN_DIR COLOR FRAMES_DIR
// RUN_DIR (private, in XDG_RUNTIME_DIR): this writes "charged" there once the
// screens are veiled and the logo full, and flashes and fades away when
// "reveal" appears. FRAMES_DIR holds the boot splash's frames: progress-NN.png
// (the charge) and throbber-NN.png (the flash); without them the veil goes on
// alone. It never holds the desktop:
// clicks go through it, and it fades away and quits by itself after a few
// seconds whatever happens.
import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShell

QtObject {
    id: app

    function arg(i, fallback) {
        const a = Qt.application.arguments, k = a.indexOf("--");
        const v = k >= 0 ? a[k + 1 + i] : undefined;
        return v === undefined || v === "" ? fallback : v;
    }
    readonly property string run: arg(0, "")
    readonly property color color: arg(1, "#1c1c1c")
    readonly property string frames: arg(2, "")
    readonly property int frameCount: 16

    // the veil, 0 → 1 → 0, the logo's charge and its flash, frame by frame
    property real veil: 0
    property real charge: 0
    property real flash: 0
    property bool flashing: false
    property bool revealing: false
    onChargeChanged: if (charge >= 1) write("charged")
    onFlashChanged: if (flash >= 1) reveal()
    readonly property bool hasFrames: frames !== ""
    function frame(name, f) {
        return "file://" + frames + "/" + name + "-" + String(Math.min(frameCount - 1, Math.floor(f * frameCount))).padStart(2, "0") + ".png";
    }

    function write(name) {
        if (run === "")
            return;
        const x = new XMLHttpRequest();
        x.open("PUT", "file://" + run + "/" + name);
        x.send("1");
    }
    function reveal() {
        if (revealing)
            return;
        revealing = true;
        fadeIn.stop();
        fadeOut.from = veil;
        fadeOut.start();
    }

    property list<QtObject> parts: [
        NumberAnimation {
            id: fadeIn
            target: app
            property: "veil"
            to: 1
            duration: 220
            easing.type: Easing.OutQuad
            onFinished: if (!app.hasFrames) app.write("charged")
        },
        NumberAnimation {
            id: fadeOut
            target: app
            property: "veil"
            to: 0
            duration: 420
            easing.type: Easing.InOutCubic
            onFinished: Qt.quit()
        },
        // the logo charges in about 0.7 s and stays full while the switch
        // runs; then it flashes (0.55 s). Frame by frame: a pause of the
        // compositor never makes them skip ahead
        FrameAnimation {
            running: app.hasFrames && app.veil > 0 && app.charge < 1
            onTriggered: app.charge = Math.min(1, app.charge + Math.min(frameTime, 1 / 60) / 0.7)
        },
        FrameAnimation {
            running: app.flashing && app.flash < 1
            onTriggered: app.flash = Math.min(1, app.flash + Math.min(frameTime, 1 / 60) / 0.55)
        },
        // "reveal" from redrog-theme-switch once the new look is in place
        Timer {
            interval: 16
            repeat: true
            running: app.veil >= 1 && !app.flashing && !app.revealing
            onTriggered: {
                const x = new XMLHttpRequest();
                x.onreadystatechange = function () {
                    if (x.readyState === XMLHttpRequest.DONE && x.responseText.length > 0) {
                        if (app.hasFrames)
                            app.flashing = true;
                        else
                            app.reveal();
                    }
                };
                x.open("GET", "file://" + app.run + "/reveal");
                x.send();
            }
        },
        // never left veiled: fade away anyway, then quit anyway
        Timer { interval: 7000; running: true; onTriggered: app.reveal() },
        Timer { interval: 10000; running: true; onTriggered: Qt.quit() },
        Instantiator {
            model: Qt.application.screens
            delegate: Window {
                id: win

                readonly property var scr: modelData

                screen: scr
                x: scr.virtualX
                y: scr.virtualY
                width: scr.width
                height: scr.height
                color: "transparent"
                flags: Qt.FramelessWindowHint | Qt.WindowTransparentForInput | Qt.WindowDoesNotAcceptFocus
                visible: false
                Component.onCompleted: visible = true
                // the fade starts with the first frame on screen
                onFrameSwapped: if (!fadeIn.running && !app.revealing && app.veil === 0) fadeIn.start()

                // above everything, panels included, on its own screen; an
                // on-screen display for KWin, so window effects leave it alone
                LayerShell.Window.scope: "on-screen-display"
                LayerShell.Window.layer: LayerShell.Window.LayerOverlay
                LayerShell.Window.anchors: LayerShell.Window.AnchorTop | LayerShell.Window.AnchorBottom
                                           | LayerShell.Window.AnchorLeft | LayerShell.Window.AnchorRight
                LayerShell.Window.exclusionZone: -1
                LayerShell.Window.keyboardInteractivity: LayerShell.Window.KeyboardInteractivityNone
                LayerShell.Window.wantsToBeOnActiveScreen: false
                LayerShell.Window.screenConfiguration: LayerShell.Window.ScreenFromQWindow

                Rectangle {
                    anchors.fill: parent
                    color: app.color
                    opacity: app.veil

                    // the boot splash's Arch logo: charging, then flashing (its
                    // glow frames are wider: the logo in them is 202 of 500 px)
                    Item {
                        id: logo
                        anchors.centerIn: parent
                        width: Math.round(Math.min(win.width, win.height) * 0.11)
                        height: width
                        visible: app.hasFrames
                        // a slight rise as it appears
                        scale: 0.92 + 0.08 * app.veil
                        Image {
                            anchors.centerIn: parent
                            width: parent.width
                            height: width
                            visible: !app.flashing
                            source: app.hasFrames ? app.frame("progress", app.charge) : ""
                            sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                            smooth: true
                            mipmap: true
                        }
                        Image {
                            anchors.centerIn: parent
                            width: Math.round(parent.width * 500 / 202)
                            height: width
                            visible: app.flashing
                            source: app.hasFrames && app.flashing ? app.frame("throbber", app.flash) : ""
                            sourceSize: Qt.size(width * Screen.devicePixelRatio, height * Screen.devicePixelRatio)
                            smooth: true
                            mipmap: true
                        }
                    }
                }
            }
        }
    ]
}
