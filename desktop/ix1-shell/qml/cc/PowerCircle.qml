import QtQuick
import Ix1Shell 1.0

// Labeled power button — a circle with a glyph and a caption below.
Item {
    id: root
    property string glyph: ""
    property string label: ""
    signal clicked()

    Column {
        anchors.centerIn: parent
        spacing: 7
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 54
            height: 54
            radius: 27
            color: area.containsMouse ? Theme.glassHover : Theme.surface2
            border.color: Theme.hairline
            border.width: 1
            scale: area.pressed ? 0.94 : 1.0

            Glyph {
                anchors.centerIn: parent
                width: 21
                height: 21
                name: root.glyph
                color: area.containsMouse ? Theme.textPrimary : Theme.textSecondary
            }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.label
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
