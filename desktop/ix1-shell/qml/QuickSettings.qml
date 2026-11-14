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

    // Tinted monochrome icon: name maps to assets/qs/<name>.svg.
    component QsIcon: Item {
        id: qsIconRoot
        required property string icon
        property color tint: Theme.textSecondary
        implicitWidth: 20
        implicitHeight: 20
        Image {
            id: qsiImg
            anchors.fill: parent
            source: "assets/qs/" + qsIconRoot.icon + ".svg"
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            visible: false
        }
        ColorOverlay {
            anchors.fill: qsiImg
            source: qsiImg
            color: qsIconRoot.tint
        }
    }

    // Hairline separator, inset past the icon column.
    component QsSep: Item {
        property int inset: 56
        width: parent ? parent.width : 0
        implicitHeight: 1
        height: 1
        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: parent.inset
            anchors.right: parent.right
            height: 1
            color: Theme.hairline
        }
    }

    // A single list entry: icon circle, name on the left, detail on the right.
    component QsRow: Item {
        id: rowRoot
        required property string name
        required property string icon
        required property string detail
        property bool on: false
        property bool enabled: true
        property var action: function() {}

        implicitWidth: 0
        implicitHeight: 50
        opacity: enabled ? 1 : 0.55

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: rowRoot.on ? Theme.accent : Theme.surface3

            Behavior on color { ColorAnimation { duration: 160 } }

            QsIcon {
                anchors.centerIn: parent
                width: 15
                height: 15
                icon: rowRoot.icon
                tint: rowRoot.on ? (Theme.dark ? "#0E1526" : "#FFFFFF")
                                 : Theme.textSecondary
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 56
            anchors.verticalCenter: parent.verticalCenter
            text: rowRoot.name
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: rowRoot.detail
            color: rowRoot.on ? Theme.accent : Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.glassHover
            visible: rowRoot.enabled && rowArea.containsMouse
        }

        MouseArea {
            id: rowArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: rowRoot.enabled
            onClicked: rowRoot.action()
        }
    }

    // A row with a toggle switch instead of a state label.
    component QsSwitchRow: Item {
        id: switchRoot
        required property string name
        required property string icon
        property bool on: false
        property var action: function() {}

        implicitWidth: 0
        implicitHeight: 50

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: switchRoot.on ? Theme.accent : Theme.surface3

            Behavior on color { ColorAnimation { duration: 160 } }

            QsIcon {
                anchors.centerIn: parent
                width: 15
                height: 15
                icon: switchRoot.icon
                tint: switchRoot.on ? (Theme.dark ? "#0E1526" : "#FFFFFF")
                                    : Theme.textSecondary
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 56
            anchors.verticalCenter: parent.verticalCenter
            text: switchRoot.name
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            height: 20
            radius: 10
            color: switchRoot.on ? Theme.accent : Theme.surface3

            Behavior on color { ColorAnimation { duration: 160 } }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: switchRoot.on ? 16 : 2
                width: 16
                height: 16
                radius: 8
                color: "#FFFFFF"

                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 8
            color: Theme.glassHover
            visible: switchArea.containsMouse
        }

        MouseArea {
            id: switchArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: switchRoot.action()
        }
    }

    // A row holding a horizontal slider: icon + track + knob.
    component QsSliderRow: Item {
        id: sliderRowRoot
        required property string icon
        property real fraction: 0
        property real maximum: 100
        property var onDrag: function(v) {}

        implicitWidth: 0
        implicitHeight: 50

        QsIcon {
            id: sliderIcon
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            icon: parent.icon
            tint: Theme.textSecondary
        }

        Item {
            id: sliderTrack
            anchors.left: sliderIcon.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            height: 14

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                height: 4
                radius: 2
                color: Theme.surface3
            }
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * Math.min(1, Math.max(0, sliderRowRoot.fraction))
                height: 4
                radius: 2
                color: Theme.dark ? "#E8EAF0" : "#1B1D24"
            }
            Rectangle {
                x: parent.width * Math.min(1, Math.max(0, sliderRowRoot.fraction)) - width / 2
                anchors.verticalCenter: parent.verticalCenter
                width: 12
                height: 12
                radius: 6
                color: Theme.dark ? "#FFFFFF" : "#1B1D24"
            }

            MouseArea {
                anchors.fill: parent
                anchors.topMargin: -8
                anchors.bottomMargin: -8
                onPositionChanged: function(mouse) {
                    if (pressed) {
                        sliderRowRoot.onDrag(Math.round(
                            Math.min(1, Math.max(0, mouse.x / sliderTrack.width))
                            * sliderRowRoot.maximum))
                    }
                }
                onPressed: function(mouse) {
                    sliderRowRoot.onDrag(Math.round(
                        Math.min(1, Math.max(0, mouse.x / sliderTrack.width))
                        * sliderRowRoot.maximum))
                }
            }
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
            width: 336
            height: contentCol.implicitHeight + 6
            radius: 18
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
                anchors.topMargin: 6
                spacing: 0

                // Header
                Item {
                    width: parent.width
                    height: 40
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Quick Settings"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
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

                QsSep { inset: 16 }

                QsRow {
                    width: parent.width
                    name: "Wi-Fi"
                    icon: "wifi"
                    detail: backend.airplaneEnabled ? "Airplane Mode"
                           : backend.wifiEnabled
                               ? (backend.wifiName.length > 0 ? backend.wifiName : "On")
                               : "Off"
                    on: backend.wifiEnabled && !backend.airplaneEnabled
                    action: function() { backend.toggleWifi() }
                }
                QsSep {}
                QsRow {
                    width: parent.width
                    name: "Bluetooth"
                    icon: "bluetooth"
                    detail: backend.bluetoothAvailable
                           ? (backend.bluetoothEnabled ? "On" : "Off")
                           : "No Adapter"
                    on: backend.bluetoothAvailable && backend.bluetoothEnabled
                    enabled: backend.bluetoothAvailable
                    action: function() { backend.toggleBluetooth() }
                }
                QsSep {}
                QsRow {
                    width: parent.width
                    name: "Airplane"
                    icon: "plane"
                    detail: backend.airplaneEnabled ? "On" : "Off"
                    on: backend.airplaneEnabled
                    action: function() { backend.toggleAirplane() }
                }
                QsSep {}
                QsRow {
                    width: parent.width
                    name: "Focus"
                    icon: "moon"
                    detail: backend.dndEnabled ? "Do Not Disturb" : "Off"
                    on: backend.dndEnabled
                    action: function() { backend.toggleDnd() }
                }

                QsSep {}
                QsSliderRow {
                    width: parent.width
                    visible: backend.brightnessAvailable
                    height: backend.brightnessAvailable ? implicitHeight : 0
                    icon: "sun"
                    fraction: backend.brightness / 100
                    maximum: 100
                    onDrag: function(v) { backend.setBrightness(v) }
                }
                QsSep { visible: backend.brightnessAvailable; height: backend.brightnessAvailable ? 1 : 0 }
                QsSliderRow {
                    width: parent.width
                    icon: "volume"
                    fraction: backend.volume / 150
                    maximum: 150
                    onDrag: function(v) { backend.setVolume(v) }
                }

                QsSep {}
                QsSwitchRow {
                    width: parent.width
                    name: Theme.dark ? "Dark Mode" : "Light Mode"
                    icon: "contrast"
                    on: Theme.dark
                    action: function() { backend.toggleTheme() }
                }
                QsSep {}
                QsRow {
                    width: parent.width
                    name: "Test Alert"
                    icon: "bell"
                    detail: "Send"
                    on: false
                    action: function() { backend.sendTestNotification() }
                }

                QsSep { inset: 16 }

                // Power actions
                Row {
                    width: parent.width
                    height: 54
                    spacing: 8
                    leftPadding: 16
                    rightPadding: 16
                    topPadding: 9
                    bottomPadding: 9

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

                            width: (contentCol.width - 32 - 24) / 4
                            height: 36
                            radius: 10
                            color: powerArea.containsMouse ? Theme.glassHover : Theme.surface2
                            border.color: Theme.hairline
                            border.width: 1

                            QsIcon {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                icon: modelData.icon
                                tint: Theme.textSecondary
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
