import QtQuick
import Ix1Shell 1.0

// Squircle icon button — power actions, shortcuts. Hover fills, the
// glyph brightens; press shrinks slightly.
Item {
    id: root
    property string glyph: ""
    signal clicked()

    Squircle {
        anchors.fill: parent
        n: 6
        color: area.containsMouse ? Theme.surface3 : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Glyph {
        anchors.centerIn: parent
        width: 16
        height: 16
        name: root.glyph
        color: area.containsMouse ? Theme.textPrimary : Theme.textSecondary
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        scale: pressed ? 0.92 : 1.0
        transformOrigin: Item.Center
    }
}
