import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
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

    // Blurred wallpaper backdrop — the same image the desktop shows, pushed
    // through a heavy blur and a dim scrim like macOS's unlock screen.
    Rectangle {
        anchors.fill: parent
        color: Theme.bgBase

        Image {
            id: lockWallpaper
            anchors.fill: parent
            source: Qt.resolvedUrl(Theme.dark
                ? "assets/wallpaper-graphite.png"
                : "assets/wallpaper-porcelain.png")
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            visible: false
        }
        FastBlur {
            anchors.fill: parent
            source: lockWallpaper
            radius: 72
            cached: true
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.dark ? Qt.rgba(0.03, 0.035, 0.05, 0.52)
                              : Qt.rgba(0.08, 0.1, 0.16, 0.34)
        }

        Column {
            anchors.centerIn: parent
            spacing: 14

            Text {
                id: lockClock
                text: Qt.formatDateTime(new Date(), "HH:mm")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 72
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
                text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 15
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Item { width: 1; height: 10 }

            // Avatar circle with the user's initial.
            Rectangle {
                width: 68
                height: 68
                radius: 34
                color: Theme.glass
                border.color: Theme.hairline
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: backend.userName.length > 0
                        ? backend.userName.charAt(0).toUpperCase()
                        : "?"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.Medium
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
                radius: 20
                color: Theme.glass
                border.color: Theme.hairline
                border.width: 1
                anchors.horizontalCenter: parent.horizontalCenter

                TextInput {
                    id: passwordInput
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    echoMode: TextInput.Password
                    clip: true
                    onAccepted: root.doUnlock()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: passwordInput.text.length === 0
                        text: "Enter Password"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
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

            Item { width: 1; height: 2 }

            Text {
                text: "Press Return to log in"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                opacity: 0.8
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
