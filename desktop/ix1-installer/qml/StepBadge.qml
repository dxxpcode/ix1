import QtQuick
import QtQuick.Layouts
import Ix1Installer

// shadcn Badge (outline) — "step 01 · destination" pill.
Item {
    property string text: ""
    property string label: ""

    implicitWidth: row.implicitWidth + 20
    implicitHeight: 26

    Rectangle {
        anchors.fill: parent
        radius: 13
        color: "transparent"
        border.width: 1
        border.color: Theme.border
        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 7
            Text {
                text: text
                color: Theme.mutedFg
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.weight: Font.Medium
                font.letterSpacing: 1.8
            }
            Rectangle { width: 3; height: 3; radius: 1.5; color: Theme.dim }
            Text {
                text: label
                color: Theme.dim
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 1.8
            }
        }
    }
}
