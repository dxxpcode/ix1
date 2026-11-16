import QtQuick
import Ix1Shell 1.0

// Dropdown pill — leading icon + current value + chevron; expands into
// a list of `model` rows (each {id, name, active}) below itself.
Item {
    id: root
    property string glyph: "lock"
    property string text: ""
    property var model: []
    property bool open: false
    signal selected(var item)

    height: open ? 44 + list.height : 44
    clip: true
    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Rectangle {
        id: pill
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 44
        radius: 10
        color: area.containsMouse ? Theme.surface3 : Theme.surface1
        border.color: Theme.hairline
        border.width: 1

        Glyph {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 15
            height: 15
            name: root.glyph
            color: Theme.textSecondary
        }
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 36
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
        Glyph {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 14
            height: 14
            name: "chevron-down"
            color: Theme.textSecondary
            rotation: root.open ? 180 : 0
            Behavior on rotation { NumberAnimation { duration: 140 } }
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.open = !root.open
        }
    }

    Rectangle {
        id: list
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: pill.bottom
        anchors.topMargin: 6
        height: listCol.childrenRect.height
        radius: 10
        color: Theme.surface1
        border.color: Theme.hairline
        border.width: 1
        visible: root.open
        clip: true

        Column {
            id: listCol
            width: parent.width
            Repeater {
                model: root.model
                delegate: Rectangle {
                    required property var modelData
                    width: list.width
                    height: 34
                    color: rowArea.containsMouse ? Theme.surface3 : "transparent"

                    Glyph {
                        visible: modelData.active
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: 13
                        height: 13
                        name: "check"
                        color: Theme.accent
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 34
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.name
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selected(modelData)
                            root.open = false
                        }
                    }
                }
            }
        }
    }
}
