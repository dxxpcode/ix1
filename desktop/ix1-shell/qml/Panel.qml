import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: true
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    height: 32

    Component.onCompleted: Theme.mode = backend.theme

    Rectangle {
        anchors.fill: parent
        color: Theme.surface1
        opacity: 0.92

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 1
            color: Theme.hairline
        }
    }

    // Left: brand (click opens the launcher)
    Row {
        id: brandRow
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Image {
            width: 20
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            source: Qt.resolvedUrl(Theme.dark ? "assets/logo-dark.png" : "assets/logo-light.png")
            fillMode: Image.PreserveAspectFit
        }
        Text {
            text: "ix1"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        x: brandRow.x
        y: 0
        width: brandRow.width
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: backend.toggleLauncher()
    }

    // Center: clock
    Text {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: Qt.formatDateTime(new Date(), "HH:mm")
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        font.weight: Font.Medium

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: clock.text = Qt.formatDateTime(new Date(), "HH:mm")
        }
    }

    // Right: tray
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 14

        Text {
            text: backend.wifiEnabled ? "⌁" : "⌁̶"
            color: backend.wifiEnabled ? Theme.textSecondary : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 15
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: "♪"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: sysTrayArea.containsMouse ? Theme.surface3 : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                anchors.centerIn: parent
                text: "☰"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }
            MouseArea {
                id: sysTrayArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: backend.toggleQuickSettings()
            }
        }
    }
}
