// Date and time in one line, like the macOS menu bar:
//   Spanish  "Vie 16 oct. 3:43 PM"
//   English  "Fri Oct 16 3:43 PM"
// Day and month names come from the user's locale. Plasma's own clock is not
// used because it only offers the locale's AM/PM text ("p. m." in Spanish)
// and cannot put the date and a 12-hour time on one line.
import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.workspace.calendar as PlasmaCalendar
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    property date now: new Date()

    function capitalize(s) {
        return s.length > 0 ? s.charAt(0).toLocaleUpperCase() + s.slice(1) : s;
    }

    function format(d) {
        const loc = Qt.locale();
        const day = capitalize(loc.dayName(d.getDay(), Locale.ShortFormat).replace(/\.$/, ""));
        const month = loc.monthName(d.getMonth(), Locale.ShortFormat).replace(/\.$/, "");
        const longMonth = loc.monthName(d.getMonth(), Locale.LongFormat);
        const h = d.getHours() % 12 || 12;
        const time = h + ":" + String(d.getMinutes()).padStart(2, "0") + (d.getHours() < 12 ? " AM" : " PM");

        if (loc.name.startsWith("en"))
            return day + " " + capitalize(month) + " " + d.getDate() + " " + time;
        // Other languages: day, date, month; abbreviated months get a period
        const dot = month.length < longMonth.length ? "." : "";
        return day + " " + d.getDate() + " " + month + dot + " " + time;
    }

    // Wake up right after each minute changes
    Timer {
        running: true
        repeat: true
        interval: 60000 - (root.now.getSeconds() * 1000 + root.now.getMilliseconds()) + 50
        onTriggered: root.now = new Date()
    }

    toolTipMainText: Qt.locale().toString(root.now, Locale.LongFormat)
    toolTipSubText: ""

    compactRepresentation: MouseArea {
        Layout.minimumWidth: label.implicitWidth
        Layout.preferredWidth: label.implicitWidth
        Layout.fillHeight: true
        onClicked: root.expanded = !root.expanded

        PlasmaComponents.Label {
            id: label
            anchors.fill: parent
            text: root.format(root.now)
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
    }

    fullRepresentation: PlasmaCalendar.MonthView {
        id: calendar
        Layout.minimumWidth: Kirigami.Units.gridUnit * 20
        Layout.minimumHeight: Kirigami.Units.gridUnit * 18
        today: root.now
        currentDate: root.now
        // Back to today every time the calendar opens
        Connections {
            target: root
            function onExpandedChanged() {
                if (root.expanded) calendar.resetToToday();
            }
        }
    }
}
