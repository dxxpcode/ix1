import QtQuick
import Ix1Shell 1.0

// Control Center tile — squircle surface, icon disc + title + optional
// subtitle and trailing chevron. `active` fills it with solid accent
// (white content), `flashing` draws a white ring for tray-zone targeting.
Item {
    id: tile
    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool flashing: false
    property bool chevron: false
    property bool expanded: false
    property real glyphStrength: 100
    // Split hit-zones: body toggles, chevron expands.
    signal toggled()
    signal chevronClicked()

    Squircle {
        anchors.fill: parent
        n: 5.5
        color: area.containsMouse
            ? (tile.active ? Qt.darker(Theme.accent, Theme.dark ? 1.5 : 1.12)
                           : Theme.surface3)
            : (tile.active ? Qt.darker(Theme.accent, Theme.dark ? 1.35 : 1.0)
                           : Theme.surface2)
        borderColor: tile.flashing ? "#FFFFFF"
                    : (tile.active ? "transparent" : Theme.hairline)
        borderWidth: tile.active ? 0 : 1

        Behavior on color { ColorAnimation { duration: 180 } }
        Behavior on borderColor { ColorAnimation { duration: 300 } }
    }

    Rectangle {
        id: disc
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 34
        radius: 17
        color: tile.active ? Qt.rgba(1, 1, 1, 0.24) : Theme.surface3

        Glyph {
            anchors.centerIn: parent
            width: 17
            height: 15
            name: tile.glyph
            strength: tile.glyphStrength
            color: tile.active ? "#FFFFFF" : Theme.textSecondary
            dimColor: tile.active ? Qt.rgba(1, 1, 1, 0.35) : Theme.hairline
        }
    }

    Column {
        anchors.left: disc.right
        anchors.leftMargin: 8
        anchors.right: chev.visible ? chev.left : parent.right
        anchors.rightMargin: chev.visible ? 2 : 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: tile.title
            color: tile.active ? "#FFFFFF" : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: tile.subtitle !== ""
            text: tile.subtitle
            color: tile.active ? Qt.rgba(1, 1, 1, 0.75) : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 10
            elide: Text.ElideRight
        }
    }

    Glyph {
        id: chev
        visible: tile.chevron
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 12
        name: "chevron"
        color: tile.active ? Qt.rgba(1, 1, 1, 0.75) : Theme.textSecondary
        rotation: tile.expanded ? 90 : 0
        Behavior on rotation { NumberAnimation { duration: 140 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.rightMargin: tile.chevron ? 30 : 0
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()
        scale: pressed ? 0.97 : 1.0
        transformOrigin: Item.Center
    }
    MouseArea {
        visible: tile.chevron
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 30
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.chevronClicked()
    }
}
