import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

// Grouped card: rows stack inside with inset hairlines between them.
Rectangle {
    default property alias rows: column.data
    Layout.fillWidth: true
    implicitHeight: column.implicitHeight
    radius: 14
    color: Theme.surface1
    border.width: 1
    border.color: Theme.hairline

    ColumnLayout {
        id: column
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0
    }
}
