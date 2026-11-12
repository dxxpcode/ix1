import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: backend.locked
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityExclusive

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    onVisibleChanged: {
        if (visible) {
            passwordInput.text = ""
            failed = false
            passwordInput.forceActiveFocus()
        }
    }

    property bool failed: false

    function doUnlock() {
        backend.unlock(passwordInput.text)
        failed = backend.locked
        if (!failed) {
            passwordInput.text = ""
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgBase

        Column {
            anchors.centerIn: parent
            spacing: 18

            Image {
                width: 72
                height: 64
                source: Qt.resolvedUrl(Theme.dark ? "assets/logo-dark.png" : "assets/logo-light.png")
                fillMode: Image.PreserveAspectFit
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 15
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                id: lockClock
                text: Qt.formatDateTime(new Date(), "HH:mm")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 56
                font.weight: Font.Light
                anchors.horizontalCenter: parent.horizontalCenter

                Timer {
                    interval: 1000
                    running: true
                    repeat: true
                    onTriggered: lockClock.text = Qt.formatDateTime(new Date(), "HH:mm")
                }
            }

            Text {
                text: backend.userName
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 15
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                width: 280
                height: 40
                radius: 10
                color: Theme.surface2
                border.color: Theme.hairline
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    clip: true
                    onAccepted: root.doUnlock()
                }
            }

            Text {
                visible: root.failed
                text: "Incorrect password"
                color: "#E5534B"
                font.family: Theme.fontFamily
                font.pixelSize: 12
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Rectangle {
                id: unlockButton
                width: 280
                height: 36
                radius: 10
                color: unlockArea.containsMouse ? Theme.surface3 : Theme.accent
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: "Unlock"
                    color: Theme.dark ? "#0E0F12" : "#FFFFFF"
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    id: unlockArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.doUnlock()
                }
            }
        }
    }
}
