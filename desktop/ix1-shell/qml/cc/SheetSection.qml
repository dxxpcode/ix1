import QtQuick
import Ix1Shell 1.0

// Grouped container — an optional dim label above a hairline'd surface
// holding its `children`. Height tracks the content column.
Item {
    id: root
    property string label: ""
    property string meta: ""
    default property alias content: col.data

    implicitHeight: (label !== "" ? 20 : 0) + body.implicitHeight
    height: implicitHeight

    Row {
        visible: root.label !== ""
        height: 20
        spacing: 6
        Text {
            text: root.label
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
        Text {
            visible: root.meta !== ""
            text: root.meta
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            opacity: 0.7
        }
    }

    Rectangle {
        id: body
        anchors.top: parent.top
        anchors.topMargin: root.label !== "" ? 20 : 0
        width: parent.width
        implicitHeight: col.childrenRect.height + 16
        height: implicitHeight
        radius: Theme.radiusSmall
        color: Theme.surface2
        border.color: Theme.hairline
        border.width: 1
        clip: true

        Column {
            id: col
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 8
            spacing: 10
        }
    }
}
