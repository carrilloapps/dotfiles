// "More details" / "Fewer details" switch at the bottom of a card: small
// spaced capitals with a chevron, red on hover
import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

RowLayout {
    id: toggle
    property bool open: false
    signal toggled()
    readonly property color red: Kirigami.Theme.highlightColor
    readonly property color dim: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.62)
    readonly property string mono: "JetBrainsMono Nerd Font"
    spacing: 4
    Text {
        text: (toggle.open ? i18n("Fewer details") : i18n("More details")).toUpperCase()
        color: hover.hovered ? toggle.red : toggle.dim
        font.family: toggle.mono
        font.pixelSize: 9
        font.letterSpacing: 2
    }
    Kirigami.Icon {
        implicitWidth: 10
        implicitHeight: 10
        source: toggle.open ? "go-up" : "go-down"
        color: hover.hovered ? toggle.red : toggle.dim
        isMask: true
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: toggle.toggled() }
}
