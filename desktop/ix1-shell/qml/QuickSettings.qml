import QtQuick
import org.kde.layershell 1.0

Window {
    id: root
    visible: backend.quickSettingsOpen
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorRight
    width: 336
    height: contentCol.implicitHeight + 52

    Component.onCompleted: Theme.mode = backend.theme

    Item {
        anchors.fill: parent

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.right: parent.right
            anchors.rightMargin: 12
            width: 312
            height: contentCol.implicitHeight + 24
            radius: Theme.radius
            color: Theme.surface1
            border.color: Theme.hairline
            border.width: 1

            Column {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                Text {
                    text: "Quick Settings"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                // Wi-Fi
                Item {
                    width: parent.width
                    height: 34

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wi-Fi"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 22
                        radius: 11
                        color: backend.wifiEnabled ? Theme.accent : Theme.surface3

                        Rectangle {
                            width: 18
                            height: 18
                            radius: 9
                            color: "#FFFFFF"
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            anchors.rightMargin: backend.wifiEnabled ? 2 : 22
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: backend.toggleWifi()
                        }
                    }
                }

                // Volume
                Column {
                    width: parent.width
                    spacing: 4

                    Text {
                        text: "Volume"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                    Item {
                        width: parent.width
                        height: 22

                        Rectangle {
                            id: volTrack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Theme.surface3

                            Rectangle {
                                width: volTrack.width * Math.max(0, backend.volume) / 150
                                height: parent.height
                                radius: 2
                                color: Theme.accent
                            }
                        }
                        Rectangle {
                            x: volTrack.width * Math.max(0, backend.volume) / 150 - 7
                            anchors.verticalCenter: parent.verticalCenter
                            width: 14
                            height: 14
                            radius: 7
                            color: Theme.surface1
                            border.color: Theme.hairline
                            border.width: 1
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onPressed: function(mouse) { updateVol(mouse.x) }
                            onPositionChanged: function(mouse) { if (pressed) updateVol(mouse.x) }
                            function updateVol(x) {
                                const v = Math.round(Math.max(0, Math.min(1, x / volTrack.width)) * 150)
                                backend.setVolume(v)
                            }
                        }
                    }
                    Text {
                        text: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                // Brightness (unsupported on this hardware path yet)
                Item {
                    width: parent.width
                    height: 34
                    opacity: 0.45

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Brightness"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "N/A"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.hairline
                }

                // Test notification (dev/verification aid)
                Item {
                    width: parent.width
                    height: 34

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Send test notification"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                        height: 26
                        radius: 8
                        color: sendArea.containsMouse ? Theme.surface3 : Theme.surface2
                        border.color: Theme.hairline
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "Send"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        MouseArea {
                            id: sendArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: backend.sendTestNotification()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.hairline
                }

                // Power
                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: [
                            { label: "Lock", action: "lock" },
                            { label: "Suspend", action: "suspend" },
                            { label: "Restart", action: "reboot" },
                            { label: "Power Off", action: "poweroff" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: (parent.width - 8) / 2
                            height: 34
                            radius: 8
                            color: powerArea.containsMouse ? Theme.surface3 : Theme.surface2

                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                            MouseArea {
                                id: powerArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.action === "lock") {
                                        backend.lock()
                                    } else {
                                        backend.powerAction(modelData.action)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
