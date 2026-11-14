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

        // Tracks the pointer across the whole dock for magnification; sits
        // behind the icon buttons, which forward their hover events down to it.
        MouseArea {
            id: dockTrack
            anchors.fill: parent
            anchors.bottomMargin: -14
            hoverEnabled: true
            property real mouseX: -1
            onPositionChanged: function (mouse) { mouseX = mouse.x }
            onExited: mouseX = -1
        }

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

                    readonly property real centerX: dockRow.x + x + width / 2
                    readonly property real mag: {
                        if (dockTrack.mouseX < 0) return 1.0
                        const d = Math.abs(dockTrack.mouseX - centerX)
                        return 1 + 0.35 * Math.max(0, 1 - d / 120)
                    }

                    width: 56
                    height: 56
                    radius: 16
                    scale: mag * (dockButtonArea.pressed ? 0.9 : 1)
                    transformOrigin: Item.Bottom
                    color: dockButtonArea.containsMouse ? Theme.glassHover : "transparent"

                    Behavior on scale {
                        NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
                    }

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
                        propagateComposedEvents: true
                        onClicked: backend.launchApp(desktopFile)
                    }
                }
            }
        }
    }
}
