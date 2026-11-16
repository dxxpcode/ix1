import QtQuick
import Ix1Shell 1.0

// Surface that slides open under a tile or picker to hold CcListRows.
Item {
    id: root
    property bool open: false
    default property alias content: col.data

    width: parent ? parent.width : 0
    height: open ? col.implicitHeight + 12 : 0
    visible: height > 0
    clip: true
    Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    Rectangle {
        width: parent.width
        height: col.implicitHeight + 12
        radius: CcStyle.radius
        color: CcStyle.surface
        border.width: 1
        border.color: CcStyle.surfaceBorder
    }
    Column {
        id: col
        x: 6
        y: 6
        width: parent.width - 12
    }
}
