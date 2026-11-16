import QtQuick
import Ix1Shell 1.0

// Round icon button with an optional caption underneath.
Item {
    id: root
    property string icon: ""
    property string label: ""
    property int diameter: 57
    property int iconSize: 24
    signal clicked()

    implicitWidth: diameter
    implicitHeight: diameter + (label !== "" ? 26 : 0)

    Rectangle {
        id: disc
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.diameter
        height: root.diameter
        radius: width / 2
        color: area.pressed ? CcStyle.surfacePressed
             : (area.containsMouse ? CcStyle.surfaceHover : CcStyle.circle)
        border.width: 1
        border.color: CcStyle.dark ? Qt.rgba(1, 1, 1, 0.07) : CcStyle.surfaceBorder
        scale: area.pressed ? 0.95 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Behavior on color { ColorAnimation { duration: 120 } }

        CcIcon {
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            name: root.icon
            color: CcStyle.text
        }
    }

    Text {
        visible: root.label !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: disc.bottom
        height: 26
        verticalAlignment: Text.AlignVCenter
        text: root.label
        color: CcStyle.text
        font.family: CcStyle.font
        font.pixelSize: 12
    }

    MouseArea {
        id: area
        anchors.fill: disc
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
