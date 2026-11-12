import QtQuick
import org.kde.layershell 1.0

Window {
    id: root
    visible: true
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    height: 88

    Component.onCompleted: Theme.mode = backend.theme

    Rectangle {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        width: dockRow.implicitWidth + 16
        height: dockRow.implicitHeight + 16
        radius: Theme.radius
        color: Theme.surface1
        opacity: 0.94

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.hairline
        }

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: backend.apps

                delegate: Rectangle {
                    required property string name
                    required property string desktopFile
                    required property int index

                    width: 48
                    height: 48
                    radius: 10
                    color: dockButtonArea.containsMouse ? Theme.surface3 : Theme.surface2

                    Text {
                        anchors.centerIn: parent
                        text: name.length > 0 ? name.charAt(0).toUpperCase() : "?"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: dockButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: backend.launchApp(desktopFile)
                    }

                }
            }
        }
    }
}
