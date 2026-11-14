import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: backend.quickSettingsOpen
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: backend.closeQuickSettings()
    }

    component QsIcon: Item {
        required property string icon
        property color tint: Theme.textSecondary
        implicitWidth: 20
        implicitHeight: 20
        Image {
            id: qsiImg
            anchors.fill: parent
            source: "assets/qs/" + icon + ".svg"
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            visible: false
        }
        ColorOverlay {
            anchors.fill: parent
            source: qsiImg
            color: parent.tint
        }
    }

    Item {
        anchors.fill: parent

        // Clicking anywhere outside the card dismisses the panel. The tray
        // toggle is covered by this overlay while open, so this is the way out.
        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeQuickSettings()
        }

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.right: parent.right
            anchors.rightMargin: 12
            width: 320
            height: contentCol.implicitHeight + 24
            radius: Theme.radius
            color: Theme.glass
            border.color: Theme.hairline
            border.width: 1

            Component.onCompleted: enterAnim.restart()
            onVisibleChanged: { if (visible) enterAnim.restart() }

            ParallelAnimation {
                id: enterAnim
                NumberAnimation {
                    target: card
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 140
                }
                NumberAnimation {
                    target: card
                    property: "anchors.topMargin"
                    from: 30
                    to: 40
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea { anchors.fill: parent; onClicked: {} }

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

                // Connectivity tiles (Wi-Fi + Bluetooth when present)
                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            {
                                name: "Wi-Fi",
                                icon: "wifi",
                                state: backend.wifiEnabled
                                       ? (backend.wifiName.length > 0 ? backend.wifiName : "On")
                                       : "Off",
                                on: backend.wifiEnabled,
                                action: function() { backend.toggleWifi() },
                                visible: true
                            },
                            {
                                name: "Bluetooth",
                                icon: "bluetooth",
                                state: backend.bluetoothEnabled ? "On" : "Off",
                                on: backend.bluetoothEnabled,
                                action: function() { backend.toggleBluetooth() },
                                visible: backend.bluetoothAvailable
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            visible: modelData.visible
                            width: (contentCol.width - 8) / 2
                            height: 58
                            radius: 10
                            color: tileArea.containsMouse ? Theme.glassHover : Theme.surface2
                            border.color: Theme.hairline
                            border.width: 1

                            Row {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 10

                                Rectangle {
                                    width: 30
                                    height: 30
                                    radius: 15
                                    color: modelData.on ? Theme.accent : Theme.surface3
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color { ColorAnimation { duration: 160 } }

                                    QsIcon {
                                        anchors.centerIn: parent
                                        width: 18
                                        height: 18
                                        icon: modelData.icon
                                        tint: modelData.on ? (Theme.dark ? "#0E1526" : "#FFFFFF")
                                                           : Theme.textSecondary
                                    }
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 1
                                    Text {
                                        text: modelData.name
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        text: modelData.state
                                        color: Theme.textSecondary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        width: (contentCol.width - 8) / 2 - 64
                                    }
                                }
                            }

                            MouseArea {
                                id: tileArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: modelData.action()
                            }
                        }
                    }
                }

                // Volume module
                Rectangle {
                    width: parent.width
                    height: 52
                    radius: 10
                    color: Theme.surface2
                    border.color: Theme.hairline
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        QsIcon { icon: "volume"; tint: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }

                        Item {
                            width: parent.width - 20 - 34 - 24 - 24
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: volTrack
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Theme.surface3

                                Rectangle {
                                    width: volTrack.width * Math.max(0, backend.volume) / 150
                                    height: parent.height
                                    radius: 3
                                    color: Theme.accent
                                }
                            }
                            Rectangle {
                                x: volTrack.width * Math.max(0, backend.volume) / 150 - 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                radius: 8
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
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            horizontalAlignment: Text.AlignRight
                            text: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                // Brightness module (only on hardware with a backlight)
                Rectangle {
                    visible: backend.brightnessAvailable
                    width: parent.width
                    height: visible ? 52 : 0
                    radius: 10
                    color: Theme.surface2
                    border.color: Theme.hairline
                    border.width: 1

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 12

                        QsIcon { icon: "sun"; tint: Theme.textSecondary; anchors.verticalCenter: parent.verticalCenter }

                        Item {
                            width: parent.width - 20 - 34 - 24 - 24
                            height: 20
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: briTrack
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 6
                                radius: 3
                                color: Theme.surface3

                                Rectangle {
                                    width: briTrack.width * Math.max(0, backend.brightness) / 100
                                    height: parent.height
                                    radius: 3
                                    color: Theme.accent
                                }
                            }
                            Rectangle {
                                x: briTrack.width * Math.max(0, backend.brightness) / 100 - 8
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                radius: 8
                                color: Theme.surface1
                                border.color: Theme.hairline
                                border.width: 1
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onPressed: function(mouse) { updateBri(mouse.x) }
                                onPositionChanged: function(mouse) { if (pressed) updateBri(mouse.x) }
                                function updateBri(x) {
                                    const v = Math.round(Math.max(0, Math.min(1, x / briTrack.width)) * 100)
                                    backend.setBrightness(v)
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            horizontalAlignment: Text.AlignRight
                            text: backend.brightness >= 0 ? Math.round(backend.brightness) + "%" : "—"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                // Toggle chips
                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            {
                                name: "Do Not Disturb",
                                icon: "moon",
                                on: backend.dndEnabled,
                                action: function() { backend.toggleDnd() }
                            },
                            {
                                name: Theme.dark ? "Light Mode" : "Dark Mode",
                                icon: "contrast",
                                on: Theme.dark,
                                action: function() { backend.toggleTheme() }
                            },
                            {
                                name: "Test Alert",
                                icon: "bell",
                                on: false,
                                action: function() { backend.sendTestNotification() }
                            }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (contentCol.width - 16) / 3
                            height: 46
                            radius: 10
                            color: chipArea.containsMouse ? Theme.glassHover : Theme.surface2
                            border.color: modelData.on ? Theme.accent : Theme.hairline
                            border.width: 1

                            Behavior on border.color { ColorAnimation { duration: 160 } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 3
                                QsIcon {
                                    width: 16
                                    height: 16
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    icon: modelData.icon
                                    tint: modelData.on ? Theme.accent : Theme.textSecondary
                                    Behavior on tint { ColorAnimation { duration: 160 } }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.name
                                    color: modelData.on ? Theme.textPrimary : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
                            }

                            MouseArea {
                                id: chipArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: modelData.action()
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.hairline
                }

                // Power actions
                Row {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: [
                            { name: "Lock", icon: "lock", action: "lock" },
                            { name: "Suspend", icon: "moon", action: "suspend" },
                            { name: "Restart", icon: "reboot", action: "reboot" },
                            { name: "Power Off", icon: "power", action: "poweroff" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (contentCol.width - 24) / 4
                            height: 50
                            radius: 10
                            color: powerArea.containsMouse ? Theme.glassHover : Theme.surface2
                            border.color: Theme.hairline
                            border.width: 1

                            Column {
                                anchors.centerIn: parent
                                spacing: 4
                                QsIcon {
                                    width: 18
                                    height: 18
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    icon: modelData.icon
                                    tint: Theme.textPrimary
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: modelData.name
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 9
                                }
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
