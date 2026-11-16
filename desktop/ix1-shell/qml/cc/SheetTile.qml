import QtQuick
import Ix1Shell 1.0

// Control tile — icon left, title + subtitle, trailing chevron.
// `active` fills the tile with solid accent; `flashing` draws a ring for
// tray-zone targeting; `expanded` rotates the chevron downward.
Item {
    id: tile
    property string glyph: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool flashing: false
    property bool chevron: true
    property bool expanded: false
    signal toggled()
    signal chevronClicked()

    Squircle {
        anchors.fill: parent
        n: 5
        color: tile.active ? (Theme.dark ? "#4A90D9" : Theme.accent)
                          : (area.containsMouse ? Theme.surface3 : Theme.surface2)
        borderColor: tile.flashing ? "#FFFFFF" : Theme.hairline
        borderWidth: tile.active ? 0 : 1

        Behavior on color { ColorAnimation { duration: 180 } }
    }

    Glyph {
        id: ic
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        name: tile.glyph
        color: tile.active ? "#FFFFFF" : Theme.textPrimary
    }

    Column {
        anchors.left: ic.right
        anchors.leftMargin: 12
        anchors.right: chev.left
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: tile.title
            color: tile.active ? "#FFFFFF" : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            visible: tile.subtitle !== ""
            text: tile.subtitle
            color: tile.active ? Qt.rgba(1, 1, 1, 0.78) : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    Glyph {
        id: chev
        visible: tile.chevron
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        name: "chevron-right"
        color: tile.active ? Qt.rgba(1, 1, 1, 0.78) : Theme.textSecondary
        rotation: tile.expanded ? 90 : 0
        Behavior on rotation { NumberAnimation { duration: 140 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            if (tile.chevron && mouse.x > width - 34) {
                tile.chevronClicked()
            } else {
                tile.toggled()
            }
        }
    }
}
