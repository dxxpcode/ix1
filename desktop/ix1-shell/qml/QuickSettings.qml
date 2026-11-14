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

    // Connectivity tile: icon circle + name + state line.
    component QsTile: Rectangle {
        required property string name
        required property string icon
        required property string detail
        property bool on: false
        property bool enabled: true
        property var action: function() {}

        implicitWidth: 0
        implicitHeight: 92
        radius: 14
        color: on ? Theme.accentSoft
                  : (enabled && tileArea.containsMouse ? Theme.glassHover : Theme.surface2)
        border.color: on ? Theme.accent : Theme.hairline
        border.width: 1
        opacity: enabled ? 1 : 0.55

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        Column {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.margins: 12
            spacing: 8

            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: on ? Theme.accent : Theme.surface3

                Behavior on color { ColorAnimation { duration: 160 } }

                QsIcon {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    icon: parent.parent.parent.icon
                    tint: on ? (Theme.dark ? "#0E1526" : "#FFFFFF")
                             : Theme.textSecondary
                }
            }

            Column {
                spacing: 2
                Text {
                    text: name
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }
                Text {
                    text: detail
                    color: on ? Theme.accent : Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 10
                }
            }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: parent.enabled
            onClicked: parent.action()
        }
    }

    // Vertical slider card (iOS-style: fills from the bottom, icon at foot).
    component QsVSlider: Rectangle {
        required property string icon
        required property real fraction   // 0..1
        required property real maximum    // percent max
        property var onDrag: function(v) {}

        implicitWidth: 72
        implicitHeight: 168
        radius: 14
        color: Theme.surface2
        border.color: Theme.hairline
        border.width: 1
        clip: true

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: parent.height * Math.max(0.02, Math.min(1, fraction))
            radius: 14
            color: Theme.dark ? "#E8EAF0" : "#1B1D24"

            Behavior on height { NumberAnimation { duration: 80 } }
        }

        QsIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            width: 17
            height: 17
            icon: parent.icon
            tint: fraction > 0.12 ? (Theme.dark ? "#1B1D24" : "#F2F3F5")
                                  : Theme.textSecondary
            Behavior on tint { ColorAnimation { duration: 80 } }
        }

        MouseArea {
            anchors.fill: parent
            onPressed: function(mouse) { apply(mouse) }
            onPositionChanged: function(mouse) { if (pressed) apply(mouse) }
            function apply(mouse) {
                const f = Math.max(0, Math.min(1, 1 - mouse.y / height))
                parent.onDrag(Math.round(f * parent.maximum))
            }
        }
    }

    // Mini stacked card in the sliders row (icon circle + label).
    component QsMini: Rectangle {
        required property string name
        required property string icon
        property bool on: false
        property var action: function() {}

        implicitWidth: 0
        implicitHeight: 79
        radius: 14
        color: on ? Theme.accentSoft
                  : (miniArea.containsMouse ? Theme.glassHover : Theme.surface2)
        border.color: on ? Theme.accent : Theme.hairline
        border.width: 1

        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }

        Column {
            anchors.centerIn: parent
            spacing: 5
            Rectangle {
                width: 30
                height: 30
                radius: 15
                anchors.horizontalCenter: parent.horizontalCenter
                color: on ? Theme.accent : Theme.surface3

                Behavior on color { ColorAnimation { duration: 160 } }

                QsIcon {
                    anchors.centerIn: parent
                    width: 15
                    height: 15
                    icon: parent.parent.parent.icon
                    tint: on ? (Theme.dark ? "#0E1526" : "#FFFFFF")
                             : Theme.textSecondary
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: name
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 10
            }
        }

        MouseArea {
            id: miniArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: parent.action()
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
            width: 360
            height: contentCol.implicitHeight + 28
            radius: 20
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
                anchors.margins: 14
                spacing: 10

                // Header
                Item {
                    width: parent.width
                    height: 22
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Quick Settings"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 22
                        height: 22
                        radius: 11
                        color: closeArea.containsMouse ? Theme.glassHover : Theme.surface3

                        Text {
                            anchors.centerIn: parent
                            text: "✕"
                            color: Theme.textSecondary
                            font.pixelSize: 10
                        }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: backend.closeQuickSettings()
                        }
                    }
                }

                // Connectivity grid (2×2)
                Grid {
                    columns: 2
                    width: parent.width
                    columnSpacing: 8
                    rowSpacing: 8

                    QsTile {
                        width: (parent.width - 8) / 2
                        name: "Wi-Fi"
                        icon: "wifi"
                        detail: backend.airplaneEnabled ? "Airplane Mode"
                               : backend.wifiEnabled
                                   ? (backend.wifiName.length > 0 ? backend.wifiName : "On")
                                   : "Off"
                        on: backend.wifiEnabled && !backend.airplaneEnabled
                        action: function() { backend.toggleWifi() }
                    }
                    QsTile {
                        width: (parent.width - 8) / 2
                        name: "Bluetooth"
                        icon: "bluetooth"
                        detail: backend.bluetoothAvailable
                               ? (backend.bluetoothEnabled ? "On" : "Off")
                               : "No Adapter"
                        on: backend.bluetoothAvailable && backend.bluetoothEnabled
                        enabled: backend.bluetoothAvailable
                        action: function() { backend.toggleBluetooth() }
                    }
                    QsTile {
                        width: (parent.width - 8) / 2
                        name: "Airplane"
                        icon: "plane"
                        detail: backend.airplaneEnabled ? "On" : "Off"
                        on: backend.airplaneEnabled
                        action: function() { backend.toggleAirplane() }
                    }
                    QsTile {
                        width: (parent.width - 8) / 2
                        name: "Focus"
                        icon: "moon"
                        detail: backend.dndEnabled ? "Do Not Disturb" : "Off"
                        on: backend.dndEnabled
                        action: function() { backend.toggleDnd() }
                    }
                }

                // Sliders + mini cards row
                Item {
                    width: parent.width
                    height: 168

                    QsVSlider {
                        id: briSlider
                        anchors.left: parent.left
                        visible: backend.brightnessAvailable
                        icon: "sun"
                        fraction: backend.brightness / 100
                        maximum: 100
                        onDrag: function(v) { backend.setBrightness(v) }
                    }
                    QsVSlider {
                        anchors.left: briSlider.visible ? briSlider.right : parent.left
                        anchors.leftMargin: briSlider.visible ? 10 : 0
                        icon: "volume"
                        fraction: backend.volume / 150
                        maximum: 150
                        onDrag: function(v) { backend.setVolume(v) }
                    }
                    Column {
                        anchors.right: parent.right
                        width: parent.width - (briSlider.visible ? 154 : 82)
                        spacing: 10

                        QsMini {
                            width: parent.width
                            name: Theme.dark ? "Dark Mode" : "Light Mode"
                            icon: "contrast"
                            on: Theme.dark
                            action: function() { backend.toggleTheme() }
                        }
                        QsMini {
                            width: parent.width
                            name: "Test Alert"
                            icon: "bell"
                            on: false
                            action: function() { backend.sendTestNotification() }
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
                            { icon: "lock", action: "lock" },
                            { icon: "moon", action: "suspend" },
                            { icon: "reboot", action: "reboot" },
                            { icon: "power", action: "poweroff" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            width: (contentCol.width - 24) / 4
                            height: 38
                            radius: 12
                            color: powerArea.containsMouse ? Theme.glassHover : Theme.surface2
                            border.color: Theme.hairline
                            border.width: 1

                            QsIcon {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                icon: modelData.icon
                                tint: Theme.textPrimary
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
