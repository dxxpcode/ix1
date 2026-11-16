import QtQuick
import Ix1Shell 1.0

// Sliding-thumb segmented switcher — `model` is a list of labels,
// `currentIndex` the selected segment; emits activated(index) on click.
Item {
    id: root
    property var model: []
    property int currentIndex: 0
    property color thumbColor: Theme.dark
        ? Qt.darker(Theme.accent, 1.35) : Theme.accent
    signal activated(int index)

    Squircle {
        anchors.fill: parent
        n: 8
        color: Theme.surface3
    }
    Squircle {
        y: 3
        x: 3 + root.currentIndex * root.width / Math.max(1, root.model.length)
        width: root.width / Math.max(1, root.model.length) - 6
        height: parent.height - 6
        n: 8
        color: root.thumbColor
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }
    Row {
        anchors.fill: parent
        Repeater {
            model: root.model
            delegate: Text {
                required property int index
                required property string modelData
                width: root.width / Math.max(1, root.model.length)
                height: root.height
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: modelData
                color: root.currentIndex === index ? "#FFFFFF" : Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: function(mouse) {
            const i = Math.floor(mouse.x / (width / Math.max(1, root.model.length)))
            root.activated(Math.max(0, Math.min(root.model.length - 1, i)))
        }
    }
}
