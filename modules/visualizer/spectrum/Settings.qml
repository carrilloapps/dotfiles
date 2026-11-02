// "Espectro de audio": the settings window of RedRog Spectrum. Edits
// ~/.config/redrog/spectrum.json, which the running spectrum picks up within
// two seconds; changes save as they are made. modules/visualizer only creates
// that file the first time, so these settings survive updates and reinstalls.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import com.github.luisbocanegra.audiovisualizer.process

Kirigami.ApplicationWindow {
    id: win

    readonly property string configPath: "@CONFIG@"
    readonly property var defaults: ({
        enabled: true, style: "@STYLE@", framerate: 60, smoothing: 77,
        autoSensitivity: true, sensitivity: 100, opacity: 100, fadeSeconds: 3
    })
    property var cfg: Object.assign({}, defaults)
    property bool loaded: false

    title: "Espectro de audio"
    width: Kirigami.Units.gridUnit * 30
    height: Kirigami.Units.gridUnit * 27
    minimumWidth: Kirigami.Units.gridUnit * 24
    minimumHeight: Kirigami.Units.gridUnit * 22
    pageStack.initialPage: page

    function load() {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            try {
                win.cfg = Object.assign({}, win.defaults, JSON.parse(xhr.responseText || "{}"));
            } catch (e) {
                win.cfg = Object.assign({}, win.defaults);
            }
            win.loaded = true;
        };
        xhr.open("GET", "file://" + configPath);
        xhr.send();
    }

    function set(key, value) {
        if (!loaded || cfg[key] === value)
            return;
        const c = Object.assign({}, cfg);
        c[key] = value;
        cfg = c;
        saveTimer.restart();
    }

    // written to a temporary file and moved over, so the spectrum never reads
    // half a file
    function save() {
        writer.command = ["sh", "-c", 'mkdir -p "$(dirname "$2")" && printf "%s\\n" "$1" > "$2.tmp" && mv "$2.tmp" "$2"',
                          "sh", JSON.stringify(cfg, null, 2), configPath];
        writer.restart();
    }

    Component.onCompleted: load()

    Timer {
        id: saveTimer
        interval: 300
        onTriggered: win.save()
    }

    Process {
        id: writer
    }

    // on the desktop or off altogether (redrog-spectrum-ctl: off stops the
    // spectrum, so it uses no GPU at all), as the tray switch does
    Process {
        id: power
    }

    Kirigami.ScrollablePage {
        id: page
        title: "Espectro de audio"

        Kirigami.FormLayout {
            enabled: win.loaded

            QQC2.Switch {
                Kirigami.FormData.label: "Mostrar en el escritorio:"
                checked: win.cfg.enabled !== false
                onToggled: {
                    win.set("enabled", checked);
                    power.command = ["sh", "-c", '"$HOME/.local/lib/redrog/redrog-spectrum-ctl" "$1"', "sh", checked ? "on" : "off"];
                    power.restart();
                }
            }

            QQC2.ComboBox {
                Kirigami.FormData.label: "Estilo:"
                implicitContentWidthPolicy: QQC2.ComboBox.WidestText
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "Halo en el centro de cada pantalla", value: "halo" },
                    { text: "Barras en el borde inferior", value: "bars" }
                ]
                currentIndex: win.cfg.style === "bars" ? 1 : 0
                onActivated: win.set("style", currentValue)
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Movimiento"
            }

            QQC2.ComboBox {
                Kirigami.FormData.label: "Fluidez:"
                implicitContentWidthPolicy: QQC2.ComboBox.WidestText
                textRole: "text"
                valueRole: "value"
                model: [
                    { text: "30 fps (ahorro)", value: 30 },
                    { text: "60 fps", value: 60 },
                    { text: "120 fps (pantallas rápidas)", value: 120 },
                    { text: "144 fps (pantallas rápidas)", value: 144 }
                ]
                currentIndex: Math.max(0, [30, 60, 120, 144].indexOf(Number(win.cfg.framerate)))
                onActivated: win.set("framerate", currentValue)
            }

            RowLayout {
                Kirigami.FormData.label: "Suavizado:"
                QQC2.Slider {
                    id: smoothing
                    Layout.fillWidth: true
                    from: 0; to: 100; stepSize: 1
                    value: win.cfg.smoothing
                    onMoved: win.set("smoothing", Math.round(value))
                }
                QQC2.Label { text: Math.round(smoothing.value) + " %"; Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5 }
            }

            QQC2.Switch {
                Kirigami.FormData.label: "Sensibilidad automática:"
                checked: win.cfg.autoSensitivity !== false
                onToggled: win.set("autoSensitivity", checked)
            }

            RowLayout {
                Kirigami.FormData.label: "Sensibilidad:"
                enabled: win.cfg.autoSensitivity === false
                QQC2.Slider {
                    id: sensitivity
                    Layout.fillWidth: true
                    from: 10; to: 300; stepSize: 5
                    value: win.cfg.sensitivity
                    onMoved: win.set("sensitivity", Math.round(value))
                }
                QQC2.Label { text: Math.round(sensitivity.value) + " %"; Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5 }
            }

            Kirigami.Separator {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Apariencia"
            }

            RowLayout {
                Kirigami.FormData.label: "Intensidad:"
                QQC2.Slider {
                    id: strength
                    Layout.fillWidth: true
                    from: 20; to: 100; stepSize: 5
                    value: win.cfg.opacity
                    onMoved: win.set("opacity", Math.round(value))
                }
                QQC2.Label { text: Math.round(strength.value) + " %"; Layout.minimumWidth: Kirigami.Units.gridUnit * 2.5 }
            }

            RowLayout {
                Kirigami.FormData.label: "Desaparece tras:"
                QQC2.SpinBox {
                    from: 1; to: 30
                    value: win.cfg.fadeSeconds
                    onValueModified: win.set("fadeSeconds", value)
                }
                QQC2.Label { text: "segundos de silencio" }
            }

            QQC2.Button {
                Kirigami.FormData.label: " "
                text: "Restablecer valores de RedRog"
                icon.name: "edit-reset"
                onClicked: {
                    win.cfg = Object.assign({}, win.defaults);
                    win.save();
                }
            }
        }
    }
}
