import QtQuick
import Ix1Shell 1.0

// Fine-print row at the sheet's foot — quiet system facts.
Item {
    id: root
    property string leftText: ""
    property string rightText: ""

    Text {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.leftText
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 10
    }
    Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: root.rightText
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 10
        opacity: 0.7
    }
}
