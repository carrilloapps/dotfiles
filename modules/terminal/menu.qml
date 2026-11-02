// RedRog context menu for kitty (right click), installed by modules/terminal.
// A small frameless window in the theme's style; KWin places it under the
// pointer (rule "RedRog terminal menu"). It prints the chosen item as
// "ACTION <id>" and quits; redrog-kitty-menu turns that into a kitty action.
// Arguments: lang=<code> and agents=<id:name,...> (the agent CLIs found).
import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import org.kde.kirigami as Kirigami

Window {
    id: win
    title: "RedRog terminal menu"
    flags: Qt.FramelessWindowHint | Qt.Tool | Qt.WindowStaysOnTopHint
    color: "transparent"
    width: 290
    height: box.implicitHeight
    visible: true

    readonly property color bg: "#1c1c1c"
    readonly property color line: "#313131"
    readonly property color hover: "#2b2b2a"
    readonly property color fg: "#efeeeb"
    readonly property color dim: "#888680"
    readonly property color red: "#ef3340"

    function arg(name) {
        const a = Qt.application.arguments;
        for (let i = 0; i < a.length; i++)
            if (a[i].indexOf(name + "=") === 0) return a[i].slice(name.length + 1);
        return "";
    }
    readonly property string lang: arg("lang")
    readonly property var agents: arg("agents") ? arg("agents").split(",").map(x => x.split(":")) : []

    // Labels in the user's language (English otherwise)
    readonly property var texts: ({
        es: { copy: "Copiar", paste: "Pegar", tab: "Nueva pestaña", right: "Dividir a la derecha",
              down: "Dividir abajo", close: "Cerrar este panel", zoom: "Ampliar o restaurar panel",
              rotate: "Girar la división", detach: "Mover panel a una pestaña nueva",
              agent: "%1 en un panel nuevo", search: "Buscar en el historial", clear: "Limpiar",
              files: "Abrir la carpeta en Dolphin", rename: "Renombrar pestaña", settings: "Ajustes de la terminal" },
        en: { copy: "Copy", paste: "Paste", tab: "New tab", right: "Split right",
              down: "Split down", close: "Close this pane", zoom: "Zoom or restore pane",
              rotate: "Rotate the split", detach: "Move pane to a new tab",
              agent: "%1 in a new pane", search: "Search the scrollback", clear: "Clear",
              files: "Open the folder in Dolphin", rename: "Rename tab", settings: "Terminal settings" }
    })
    readonly property var tr: texts[lang] || texts.en

    function pick(id) {
        console.log("ACTION " + id);
        Qt.exit(0);
    }

    // Close when it loses focus or with Escape, like a menu
    onActiveChanged: if (!active && shown.running === false) Qt.exit(1)
    Timer { id: shown; interval: 400; running: true }
    Item {
        focus: true
        Keys.onEscapePressed: Qt.exit(1)
    }

    Rectangle {
        id: box
        anchors.fill: parent
        implicitHeight: column.implicitHeight + 12
        radius: 10
        color: Qt.alpha(win.bg, 0.97)
        border.width: 1
        border.color: win.line

        ColumnLayout {
            id: column
            anchors.fill: parent
            anchors.margins: 6
            spacing: 0

            Repeater {
                // in parentheses: a binding that starts with "[" is parsed as a list of objects
                model: ([
                    { id: "copy", icon: "edit-copy", key: "Ctrl+Shift+C" },
                    { id: "paste", icon: "edit-paste", key: "Ctrl+Shift+V" },
                    { sep: true },
                    { id: "tab", icon: "tab-new", key: "Ctrl+Shift+T" },
                    { id: "right", icon: "view-split-left-right", key: "Ctrl+Shift+D" },
                    { id: "down", icon: "view-split-top-bottom", key: "Ctrl+Shift+E" },
                    { id: "zoom", icon: "zoom-fit-best", key: "Ctrl+Shift+Z" },
                    { id: "rotate", icon: "object-rotate-right", key: "" },
                    { id: "detach", icon: "window-new", key: "" },
                    { id: "close", icon: "view-close", key: "Ctrl+Shift+Q" }
                ]).concat(win.agents.length ? [{ sep: true }] : [])
                 .concat(win.agents.map(a => ({ id: "agent:" + a[0], icon: a[2] || "utilities-terminal",
                                                mask: !a[2], text: win.tr.agent.arg(a[1]), key: "" })))
                 .concat([
                    { sep: true },
                    { id: "search", icon: "edit-find", key: "Ctrl+Shift+F" },
                    { id: "clear", icon: "edit-clear-all", key: "Ctrl+Shift+K" },
                    { id: "files", icon: "system-file-manager", key: "" },
                    { id: "rename", icon: "edit-rename", key: "Ctrl+Shift+R" },
                    { id: "settings", icon: "configure", key: "Ctrl+Shift+F2" }
                 ])

                delegate: Item {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    implicitHeight: modelData.sep ? 9 : 28

                    Rectangle {
                        visible: !!row.modelData.sep
                        anchors.centerIn: parent
                        width: parent.width - 16
                        height: 1
                        color: win.line
                    }
                    Rectangle {
                        visible: !row.modelData.sep
                        anchors.fill: parent
                        radius: 6
                        color: area.containsMouse ? win.red : "transparent"
                        Behavior on color { ColorAnimation { duration: 90 } }
                    }
                    RowLayout {
                        visible: !row.modelData.sep
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 10
                        spacing: 9
                        Kirigami.Icon {
                            implicitWidth: 16
                            implicitHeight: 16
                            source: row.modelData.icon || ""
                            color: area.containsMouse ? "#ffffff" : win.fg
                            // app logos keep their colors
                            isMask: row.modelData.mask !== false
                        }
                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.text || win.tr[row.modelData.id] || ""
                            color: area.containsMouse ? "#ffffff" : win.fg
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }
                        Text {
                            text: row.modelData.key || ""
                            color: area.containsMouse ? "#ffffff" : win.dim
                            font.pixelSize: 11
                        }
                    }
                    MouseArea {
                        id: area
                        anchors.fill: parent
                        enabled: !row.modelData.sep
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.pick(row.modelData.id)
                    }
                }
            }
        }
    }
}
