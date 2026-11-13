import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: true
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    height: 92

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Rectangle {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        width: dockRow.implicitWidth + 20
        height: dockRow.implicitHeight + 20
        radius: 18
        color: Theme.glass
        border.color: Theme.hairline
        border.width: 1

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: backend.apps

                delegate: Rectangle {
                    required property string name
                    required property string desktopFile
                    required property int index

                    width: 56
                    height: 56
                    radius: 16
                    color: dockButtonArea.containsMouse ? Theme.glassHover : "transparent"

                    AppIcon {
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        desktopFileName: desktopFile
                        appTitle: name
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
