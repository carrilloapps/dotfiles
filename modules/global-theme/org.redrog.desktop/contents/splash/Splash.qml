import QtQuick

Rectangle {
    id: root
    color: "#000000"

    property int stage: 0

    property int currentProgressFrame: 0
    property int currentThrobberFrame: 0
    property bool chargingDone: false

    function framePath(prefix, index) {
        var s = index < 10 ? "0" + index : "" + index;
        return "images/" + prefix + "-" + s + ".png";
    }

    Item {
        id: container
        anchors.fill: parent
        opacity: 1

        Behavior on opacity {
            NumberAnimation { duration: 350; easing.type: Easing.InOutQuad }
        }

        Item {
            id: logo
            anchors.centerIn: parent
            readonly property real logoSize: Math.round(Math.min(root.width, root.height) * 0.16)
            width: logoSize
            height: logoSize

            Image {
                id: progressImg
                anchors.centerIn: parent
                width: parent.width
                height: parent.height
                visible: !root.chargingDone
                source: root.framePath("progress", root.currentProgressFrame)
                asynchronous: false
                smooth: true
                mipmap: true
            }

            Image {
                id: throbberImg
                anchors.centerIn: parent
                width: Math.round(parent.width * 500 / 200)
                height: width
                visible: root.chargingDone
                source: root.framePath("throbber", root.currentThrobberFrame)
                asynchronous: false
                smooth: true
                mipmap: true
            }
        }
    }

    Timer {
        id: progressTimer
        interval: 45
        repeat: true
        running: !root.chargingDone
        onTriggered: {
            if (root.currentProgressFrame < 15) {
                root.currentProgressFrame++;
            } else {
                root.chargingDone = true;
                throbberTimer.start();
            }
        }
    }

    Timer {
        id: throbberTimer
        interval: 50
        repeat: true
        running: false
        onTriggered: {
            root.currentThrobberFrame = (root.currentThrobberFrame + 1) % 16;
        }
    }

    onStageChanged: {
        if (stage >= 5) {
            container.opacity = 0;
        }
    }
}
