import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import Ix1Settings 1.0

// Custom select: value + chevron button that opens an anchored popover list.
Item {
    id: sel
    property var options: []      // display labels
    property int currentIndex: -1
    property int buttonWidth: 180
    property bool demoOpen: false
    signal activated(int index)

    width: buttonWidth
    height: 32

    Rectangle {
        id: button
        anchors.fill: parent
        radius: 9
        color: hover.containsMouse || pop.visible ? Theme.surface3 : Theme.surface2
        border.width: 1
        border.color: pop.visible
            ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6)
            : Theme.hairline

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.right: chevron.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: sel.currentIndex >= 0 ? sel.options[sel.currentIndex] : "—"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            elide: Text.ElideRight
        }

        Shape {
            id: chevron
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 10
            height: 12
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Theme.textSecondary
                strokeWidth: 1.5
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                joinStyle: ShapePath.RoundJoin
                startX: 1.5; startY: 4.5
                PathLine { x: 5; y: 1.5 }
                PathLine { x: 8.5; y: 4.5 }
                PathMove { x: 1.5; y: 7.5 }
                PathLine { x: 5; y: 10.5 }
                PathLine { x: 8.5; y: 7.5 }
            }
        }

        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: pop.open()
        }
    }

    Component.onCompleted: if (demoOpen) pop.open()

    Popup {
        id: pop
        y: sel.height + 6
        width: Math.max(sel.width, 180)
        padding: 5
        margins: 8
        implicitHeight: Math.min(list.contentHeight, 320) + 10

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 140; easing.type: Easing.OutCubic }
        }

        background: Rectangle {
            radius: 12
            color: Theme.dark ? "#202229" : "#FFFFFF"
            border.width: 1
            border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0.05, 0.07, 0.12, 0.12)
            Rectangle {
                z: -1
                anchors.fill: parent
                anchors.topMargin: 6
                anchors.margins: -2
                radius: 14
                color: Qt.rgba(0, 0, 0, Theme.dark ? 0.35 : 0.10)
            }
        }

        contentItem: ListView {
            id: list
            implicitHeight: Math.min(contentHeight, 320)
            clip: true
            interactive: contentHeight > height
            boundsBehavior: Flickable.StopAtBounds
            currentIndex: sel.currentIndex
            Component.onCompleted: positionViewAtIndex(Math.max(0, sel.currentIndex), ListView.Contain)
            model: sel.options
            delegate: Rectangle {
                width: ListView.view.width
                height: 32
                radius: 8
                color: rowHover.containsMouse ? Theme.surface3 : "transparent"

                Rectangle {
                    visible: index === sel.currentIndex
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 2
                    height: 14
                    radius: 1
                    color: Theme.accent
                }
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData
                    color: index === sel.currentIndex ? Theme.textPrimary : Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: index === sel.currentIndex ? Font.Medium : Font.Normal
                }
                MouseArea {
                    id: rowHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        pop.close()
                        sel.activated(index)
                    }
                }
            }
        }
    }
}
