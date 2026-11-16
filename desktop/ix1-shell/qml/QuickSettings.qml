import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

// Control Center — a floating card under the top bar: header, 2x2 toggle
// tiles, volume/brightness panes, output device, power row, More Settings.
Window {
    id: root
    visible: backend.quickSettingsOpen
    color: "transparent"

    // Which expander is open: "wifi" | "appearance" | "". IX1_SHOW_NET
    // opens the Wi-Fi list for renders.
    property string expanded: (typeof demoNet !== "undefined" && demoNet) ? "wifi" : ""

    function toggleExpanded(name) { expanded = expanded === name ? "" : name }
    function openSettings() {
        backend.launchApp("/usr/share/applications/ix1-settings.desktop")
        backend.closeQuickSettings()
    }

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    // The Wi-Fi password field needs real key events on Wayland.
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand
    width: 1920
    height: 1080

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: backend.closeQuickSettings()
    }

    Item {
        anchors.fill: parent

        // Click outside the card dismisses.
        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeQuickSettings()
        }

        Item {
            id: shell
            anchors.top: parent.top
            anchors.topMargin: 42
            anchors.right: parent.right
            anchors.rightMargin: 10
            width: 400
            height: Math.min(content.implicitHeight, parent.height - 60)
            opacity: 0

            Component.onCompleted: enter.restart()
            ParallelAnimation {
                id: enter
                NumberAnimation { target: shell; property: "opacity"; from: 0; to: 1; duration: 160 }
                NumberAnimation { target: shell; property: "anchors.topMargin"; from: 48; to: 42; duration: 200; easing.type: Easing.OutCubic }
            }

            DropShadow {
                anchors.fill: card
                source: card
                radius: 28
                samples: 41
                verticalOffset: 12
                color: Qt.rgba(0, 0, 0, CcStyle.dark ? 0.45 : 0.16)
            }

            Rectangle {
                id: card
                anchors.fill: parent
                radius: CcStyle.radiusCard
                color: CcStyle.card
                border.width: 1
                border.color: CcStyle.cardBorder
            }

            // Notch pointing up at the panel tray; covers the card's top border.
            Canvas {
                id: notch
                anchors.bottom: card.top
                anchors.bottomMargin: -1
                anchors.right: card.right
                anchors.rightMargin: 29
                width: 26
                height: 10
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = CcStyle.card
                    ctx.beginPath()
                    ctx.moveTo(0, height)
                    ctx.lineTo(width / 2 - 2, 1.2)
                    ctx.quadraticCurveTo(width / 2, 0, width / 2 + 2, 1.2)
                    ctx.lineTo(width, height)
                    ctx.closePath()
                    ctx.fill()
                    ctx.strokeStyle = CcStyle.cardBorder
                    ctx.lineWidth = 1
                    ctx.beginPath()
                    ctx.moveTo(0, height - 0.5)
                    ctx.lineTo(width / 2 - 2, 1.2)
                    ctx.quadraticCurveTo(width / 2, 0, width / 2 + 2, 1.2)
                    ctx.lineTo(width, height - 0.5)
                    ctx.stroke()
                }
                Connections {
                    target: Theme
                    function onModeChanged() { notch.requestPaint() }
                }
            }

            Flickable {
                anchors.fill: parent
                contentHeight: content.implicitHeight
                interactive: contentHeight > height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: content
                    x: 16
                    width: parent.width - 32
                    topPadding: 21

                    // ---- Header --------------------------------------------
                    Item {
                        width: parent.width
                        height: 45

                        Image {
                            id: logo
                            x: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 38
                            height: 38
                            source: CcStyle.dark ? "assets/logo-dark.png" : "assets/logo-light.png"
                            sourceSize: Qt.size(152, 152)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }
                        Column {
                            x: 65
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 0
                            Text {
                                text: "Control Center"
                                color: CcStyle.text
                                font.family: CcStyle.font
                                font.pixelSize: 17
                                font.weight: Font.Medium
                            }
                            Text {
                                text: "Quick settings and controls"
                                color: CcStyle.textMuted
                                font.family: CcStyle.font
                                font.pixelSize: 13
                            }
                        }
                        CcCircleButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            diameter: 45
                            icon: "gear"
                            iconSize: 28
                            onClicked: root.openSettings()
                        }
                    }

                    Item { width: 1; height: 19 }

                    // ---- Tiles ---------------------------------------------
                    Grid {
                        id: tiles
                        width: parent.width
                        columns: 2
                        columnSpacing: 11
                        rowSpacing: 13
                        readonly property real cell: (width - columnSpacing) / 2

                        CcTile {
                            width: tiles.cell
                            icon: "wifi"
                            iconSize: 42
                            iconWeight: 2.3
                            title: "Wi-Fi"
                            subtitle: !backend.wifiEnabled ? "Off"
                                      : (backend.wifiSsid ? "Connected" : "On")
                            active: backend.wifiEnabled
                            flashing: backend.qsSection === "wifi"
                            onToggled: backend.toggleWifi()
                            onChevronClicked: root.toggleExpanded("wifi")
                        }
                        CcTile {
                            width: tiles.cell
                            icon: "bluetooth"
                            title: "Bluetooth"
                            subtitle: backend.bluetoothEnabled ? "On" : "Off"
                            active: false
                            onToggled: backend.toggleBluetooth()
                            onChevronClicked: root.openSettings()
                        }
                        CcTile {
                            width: tiles.cell
                            icon: "moon"
                            title: "Focus"
                            subtitle: backend.dnd ? "On" : "Off"
                            active: backend.dnd
                            onToggled: backend.setDnd(!backend.dnd)
                            onChevronClicked: root.openSettings()
                        }
                        CcTile {
                            width: tiles.cell
                            icon: "sun"
                            title: "Appearance"
                            subtitle: backend.theme === "graphite" ? "Dark" : "Light"
                            onToggled: backend.toggleTheme()
                            onChevronClicked: root.toggleExpanded("appearance")
                        }
                    }

                    // ---- Wi-Fi networks ------------------------------------
                    Item {
                        width: parent.width
                        height: wifiList.height > 0 ? wifiList.height + 13 : 0
                        CcExpander {
                            id: wifiList
                            y: 13
                            open: root.expanded === "wifi"

                            Repeater {
                                model: backend.wifiNetworks
                                delegate: CcListRow {
                                    required property var modelData
                                    width: parent.width
                                    icon: "wifi"
                                    iconOpacity: modelData.inUse ? 1 : 0.4 + 0.6 * modelData.signal / 100
                                    label: modelData.ssid
                                    trailing: modelData.inUse ? "connected"
                                            : (modelData.secure ? "lock" : "")
                                    needsPassword: modelData.secure && !modelData.inUse
                                    onActivated: backend.connectWifi(modelData.ssid, "")
                                    onJoined: function(pw) { backend.connectWifi(modelData.ssid, pw) }
                                }
                            }
                            Text {
                                visible: backend.wifiNetworks.length === 0
                                x: 10
                                height: 38
                                verticalAlignment: Text.AlignVCenter
                                text: backend.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                                color: CcStyle.textMuted
                                font.family: CcStyle.font
                                font.pixelSize: 12
                            }
                        }
                    }

                    // ---- Appearance ----------------------------------------
                    Item {
                        width: parent.width
                        height: themeList.height > 0 ? themeList.height + 13 : 0
                        CcExpander {
                            id: themeList
                            y: 13
                            open: root.expanded === "appearance"

                            Repeater {
                                model: [
                                    { "id": "graphite", "label": "Dark", "icon": "moon" },
                                    { "id": "porcelain", "label": "Light", "icon": "sun" },
                                ]
                                delegate: CcListRow {
                                    required property var modelData
                                    width: parent.width
                                    icon: modelData.icon
                                    label: modelData.label
                                    trailing: backend.theme === modelData.id ? "check" : ""
                                    onActivated: {
                                        if (backend.theme !== modelData.id) {
                                            backend.toggleTheme()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: 1; height: 14 }

                    // ---- Sliders -------------------------------------------
                    CcSlider {
                        width: parent.width
                        icon: backend.volume === 0 ? "volume-off" : "volume"
                        min: 0
                        max: 150
                        value: backend.volume
                        available: backend.volume >= 0
                        onMoved: function(v) { backend.setVolume(v) }
                    }
                    Item { width: 1; height: 8 }
                    CcSlider {
                        width: parent.width
                        icon: "brightness"
                        min: 0
                        max: 100
                        value: backend.brightness
                        available: backend.brightness >= 0
                        onMoved: function(v) { backend.setBrightness(v) }
                    }

                    Item { width: 1; height: 14 }
                    Rectangle { width: parent.width; height: 1; color: CcStyle.divider }
                    Item { width: 1; height: 15 }

                    // ---- Output device -------------------------------------
                    CcDevicePicker {
                        width: parent.width
                        model: backend.outputDevices
                        onSelected: function(item) { backend.setOutputDevice(item.id) }
                    }

                    Item { width: 1; height: 19 }

                    // ---- Power ---------------------------------------------
                    Row {
                        width: parent.width
                        Repeater {
                            model: [
                                { "icon": "lock-fill", "label": "Lock", "action": "lock" },
                                { "icon": "moon", "label": "Suspend", "action": "suspend" },
                                { "icon": "restart", "label": "Restart", "action": "reboot" },
                                { "icon": "power", "label": "Power Off", "action": "poweroff" },
                            ]
                            delegate: Item {
                                required property var modelData
                                width: parent.width / 4
                                height: power.implicitHeight
                                CcCircleButton {
                                    id: power
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.width
                                    icon: modelData.icon
                                    label: modelData.label
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

                    Item { width: 1; height: 13 }
                    Rectangle { width: parent.width; height: 1; color: CcStyle.divider }

                    // ---- More Settings -------------------------------------
                    Item {
                        width: parent.width
                        height: 49

                        Rectangle {
                            anchors.fill: parent
                            anchors.topMargin: 4
                            anchors.bottomMargin: 4
                            radius: 10
                            color: moreArea.containsMouse ? CcStyle.rowHover : "transparent"
                        }
                        CcIcon {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 21
                            height: 21
                            name: "sliders"
                            weight: 1.7
                            color: CcStyle.text
                        }
                        Text {
                            x: 46
                            anchors.verticalCenter: parent.verticalCenter
                            text: "More Settings"
                            color: CcStyle.text
                            font.family: CcStyle.font
                            font.pixelSize: 12
                        }
                        CcIcon {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            width: 17
                            height: 17
                            name: "chevron-right"
                            color: CcStyle.text
                        }
                        MouseArea {
                            id: moreArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.openSettings()
                        }
                    }
                }
            }
        }
    }
}
