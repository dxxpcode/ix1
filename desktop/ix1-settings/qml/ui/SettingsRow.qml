import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

// Title (+ hint) on the left, control on the right edge.
Item {
    id: row
    property string title
    property string hint
    property bool divider: true
    default property alias control: slot.data
    Layout.fillWidth: true
    implicitHeight: Math.max(hint.length ? 62 : 52, slot.childrenRect.height + 20)

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: slot.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        Text {
            text: row.title
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }
        Text {
            visible: row.hint.length > 0
            width: parent.width
            text: row.hint
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            wrapMode: Text.Wrap
        }
    }

    Item {
        id: slot
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }

    Rectangle {
        visible: row.divider
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.leftMargin: 18
        anchors.right: parent.right
        anchors.rightMargin: 1
        height: 1
        color: Theme.hairline
    }
}
