import QtQuick
import Ix1Settings 1.0

// Segmented control: selected segment is a raised subtle fill with a hairline,
// never a solid accent fill.
Rectangle {
    id: seg
    property var options: []      // display labels
    property int currentIndex: 0
    property int segmentWidth: 64
    signal activated(int index)

    width: options.length * segmentWidth + 6
    height: 32
    radius: 9
    color: Theme.surface2
    border.width: 1
    border.color: activeFocus ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6) : Theme.hairline
    activeFocusOnTab: true
    Keys.onLeftPressed: if (currentIndex > 0) activated(currentIndex - 1)
    Keys.onRightPressed: if (currentIndex < options.length - 1) activated(currentIndex + 1)

    Rectangle {
        visible: seg.currentIndex >= 0
        x: 3 + seg.currentIndex * seg.segmentWidth
        y: 3
        width: seg.segmentWidth
        height: seg.height - 6
        radius: 7
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : "#FFFFFF"
        border.width: 1
        border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0.05, 0.07, 0.12, 0.10)
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            anchors.horizontalCenter: parent.horizontalCenter
            width: 14
            height: 2
            radius: 1
            color: Theme.accent
        }
    }

    Row {
        x: 3
        y: 3
        Repeater {
            model: seg.options
            delegate: Item {
                width: seg.segmentWidth
                height: seg.height - 6
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1
                    text: modelData
                    color: index === seg.currentIndex ? Theme.textPrimary : Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: index === seg.currentIndex ? Font.Medium : Font.Normal
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.activated(index)
                }
            }
        }
    }
}
