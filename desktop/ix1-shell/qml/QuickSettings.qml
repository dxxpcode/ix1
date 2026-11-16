import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

// Control Center — a floating card anchored under the top bar: header,
// 2x2 control tiles, knob sliders, output-device dropdown, labeled power
// circles, More Settings footer. Lucide icons throughout.
Window {
    id: root
    visible: backend.quickSettingsOpen
    color: "transparent"

    // Which tile's expansion is open: "wifi" | "appearance" | "" — the
    // IX1_SHOW_NET demo env opens wifi for renders.
    property string expandedTile: (typeof demoNet !== "undefined" && demoNet) ? "wifi" : ""

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

        // Frosted backdrop — blurred wallpaper + scrim.
        Image {
            id: frostedWallpaper
            anchors.fill: parent
            source: Theme.dark ? "assets/wallpaper-graphite.png"
                               : "assets/wallpaper-porcelain.png"
            visible: false
        }
        FastBlur {
            anchors.fill: parent
            source: frostedWallpaper
            radius: 48
            opacity: 0
            NumberAnimation on opacity { to: 1; duration: 260; running: true }
        }
        Rectangle {
            anchors.fill: parent
            color: Theme.dark ? Qt.rgba(0, 0, 0, 0.18) : Qt.rgba(1, 1, 1, 0.22)
        }

        // Click outside the card dismisses.
        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeQuickSettings()
        }

        DropShadow {
            anchors.fill: card
            source: card
            z: -1
            radius: 26
            samples: 33
            verticalOffset: 10
            color: Qt.rgba(0, 0, 0, Theme.dark ? 0.5 : 0.28)
        }

        // Notch pointing up at the panel tray.
        Canvas {
            id: notch
            anchors.bottom: card.top
            anchors.right: card.right
            anchors.rightMargin: 148
            width: 22
            height: 10
            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                ctx.fillStyle = Theme.glass
                ctx.beginPath()
                ctx.moveTo(0, height)
                ctx.lineTo(width / 2, 0)
                ctx.lineTo(width, height)
                ctx.closePath()
                ctx.fill()
            }
            Connections {
                target: Theme
                function onModeChanged() { notch.requestPaint() }
            }
        }

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.topMargin: 44
            anchors.right: parent.right
            anchors.rightMargin: 12
            width: 392
            height: Math.min(flick.contentHeight + 32, parent.height - 60)
            radius: 18
            color: Theme.glass
            clip: true

            // Lit inner top edge.
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Theme.radius
                anchors.rightMargin: Theme.radius
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.16 : 0.7) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Component.onCompleted: { enterAnim.restart(); enterStagger.restart() }

            ParallelAnimation {
                id: enterAnim
                NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 150 }
                NumberAnimation { target: card; property: "anchors.topMargin"; from: 54; to: 44; duration: 200; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                id: enterStagger
                ParallelAnimation {
                    NumberAnimation { target: headerRow; property: "opacity"; from: 0; to: 1; duration: 160 }
                    NumberAnimation { target: tileGrid; property: "opacity"; from: 0; to: 1; duration: 160 }
                }
                PauseAnimation { duration: 45 }
                ParallelAnimation {
                    NumberAnimation { target: sliderCol; property: "opacity"; from: 0; to: 1; duration: 180 }
                    NumberAnimation { target: outputCol; property: "opacity"; from: 0; to: 1; duration: 180 }
                }
                PauseAnimation { duration: 45 }
                ParallelAnimation {
                    NumberAnimation { target: powerRow; property: "opacity"; from: 0; to: 1; duration: 180 }
                    NumberAnimation { target: moreRow; property: "opacity"; from: 0; to: 1; duration: 160 }
                }
            }

            Flickable {
                id: flick
                anchors.fill: parent
                anchors.margins: 16
                contentHeight: col.childrenRect.height
                clip: true
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: col
                    width: parent.width
                    spacing: 14

                    // ---- Header -------------------------------------------
                    Item {
                        id: headerRow
                        opacity: 0
                        width: parent.width
                        height: 46

                        Image {
                            id: logo
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            height: 42
                            source: Theme.dark ? "assets/logo-dark.png" : "assets/logo-light.png"
                            fillMode: Image.PreserveAspectFit
                        }
                        Column {
                            anchors.left: logo.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "Control Center"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: "Quick settings and controls"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        GlyphButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 40
                            height: 40
                            glyph: "settings"
                            onClicked: {
                                backend.launchApp("/usr/share/applications/ix1-settings.desktop")
                                backend.closeQuickSettings()
                            }
                        }
                    }

                    // ---- Toggle tiles --------------------------------------
                    Grid {
                        id: tileGrid
                        opacity: 0
                        width: parent.width
                        columns: 2
                        rowSpacing: 10
                        columnSpacing: 10

                        SheetTile {
                            width: (tileGrid.width - 10) / 2
                            height: 76
                            glyph: "wifi"
                            title: "Wi-Fi"
                            subtitle: !backend.wifiEnabled ? "Off"
                                      : (backend.wifiSsid ? "Connected" : "On")
                            active: backend.wifiEnabled
                            flashing: backend.qsSection === "wifi"
                            expanded: root.expandedTile === "wifi"
                            onToggled: backend.toggleWifi()
                            onChevronClicked: root.expandedTile =
                                root.expandedTile === "wifi" ? "" : "wifi"
                        }
                        SheetTile {
                            width: (tileGrid.width - 10) / 2
                            height: 76
                            glyph: "bluetooth"
                            title: "Bluetooth"
                            subtitle: backend.bluetoothEnabled ? "On" : "Off"
                            active: backend.bluetoothEnabled
                            chevron: false
                            onToggled: backend.toggleBluetooth()
                        }
                        SheetTile {
                            width: (tileGrid.width - 10) / 2
                            height: 76
                            glyph: "moon"
                            title: "Focus"
                            subtitle: backend.dnd ? "On" : "Off"
                            active: backend.dnd
                            chevron: false
                            onToggled: backend.setDnd(!backend.dnd)
                        }
                        SheetTile {
                            width: (tileGrid.width - 10) / 2
                            height: 76
                            glyph: "sun-medium"
                            title: "Appearance"
                            subtitle: backend.theme === "graphite" ? "Dark" : "Light"
                            expanded: root.expandedTile === "appearance"
                            onToggled: backend.toggleTheme()
                            onChevronClicked: root.expandedTile =
                                root.expandedTile === "appearance" ? "" : "appearance"
                        }
                    }

                    // ---- Wi-Fi networks (expands under the grid) -----------
                    SheetSection {
                        width: parent.width
                        label: ""
                        height: root.expandedTile === "wifi" ? implicitHeight : 0
                        clip: true
                        visible: root.expandedTile === "wifi" || height > 0
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        ListView {
                            width: parent.width
                            height: Math.min(contentHeight, 180)
                            model: backend.wifiNetworks
                            interactive: contentHeight > height
                            clip: true
                            spacing: 2

                            delegate: SwitchRow {
                                required property var modelData
                                width: ListView.view.width
                                label: modelData.ssid
                                glyph: "wifi"
                                glyphStrength: modelData.signal
                                trailing: modelData.inUse ? "pill"
                                        : (modelData.secure ? "lock" : "")
                                needsPassword: modelData.secure && !modelData.inUse
                                onActivated: backend.connectWifi(modelData.ssid, "")
                                onJoined: function(pw) { backend.connectWifi(modelData.ssid, pw) }
                            }
                        }
                        Text {
                            visible: backend.wifiNetworks.length === 0
                            text: backend.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                            topPadding: 4
                            bottomPadding: 4
                        }
                    }

                    // ---- Appearance expander --------------------------------
                    SheetSection {
                        width: parent.width
                        height: root.expandedTile === "appearance" ? implicitHeight : 0
                        clip: true
                        visible: root.expandedTile === "appearance" || height > 0
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        SegmentedControl {
                            width: parent.width
                            height: 30
                            model: ["Graphite", "Porcelain"]
                            currentIndex: backend.theme === "graphite" ? 0 : 1
                            onActivated: function(i) {
                                if ((i === 0) !== (backend.theme === "graphite")) {
                                    backend.toggleTheme()
                                }
                            }
                        }
                    }

                    // ---- Sliders -------------------------------------------
                    Column {
                        id: sliderCol
                        opacity: 0
                        width: parent.width
                        spacing: 10

                        KnobSlider {
                            width: parent.width
                            height: 52
                            glyph: "volume-2"
                            min: 0
                            max: 150
                            value: backend.volume
                            available: backend.volume >= 0
                            readout: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
                            onMoved: function(v) { backend.setVolume(v) }
                        }
                        KnobSlider {
                            width: parent.width
                            height: 52
                            glyph: "sun"
                            min: 0
                            max: 100
                            value: backend.brightness
                            available: backend.brightness >= 0
                            readout: backend.brightness >= 0 ? Math.round(backend.brightness) + "%" : "N/A"
                            onMoved: function(v) { backend.setBrightness(v) }
                        }
                    }

                    // ---- Output device --------------------------------------
                    Column {
                        id: outputCol
                        opacity: 0
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.hairline
                        }
                        Row {
                            height: 24
                            spacing: 8
                            Glyph {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 15
                                height: 15
                                name: "headphones"
                                color: Theme.textSecondary
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Output Device"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        DropdownPill {
                            width: parent.width
                            glyph: "lock"
                            text: {
                                for (const d of backend.outputDevices) {
                                    if (d.active) return d.name
                                }
                                return backend.outputDevices.length
                                        ? backend.outputDevices[0].name : "Speakers"
                            }
                            model: backend.outputDevices
                            onSelected: function(item) { backend.setOutputDevice(item.id) }
                        }
                    }

                    // ---- Power ----------------------------------------------
                    Column {
                        width: parent.width
                        spacing: 6

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.hairline
                        }
                        Row {
                            id: powerRow
                            opacity: 0
                            width: parent.width
                            height: 84
                            topPadding: 8

                            Repeater {
                                model: [
                                    { "glyph": "lock", "label": "Lock", "action": "lock" },
                                    { "glyph": "moon", "label": "Suspend", "action": "suspend" },
                                    { "glyph": "refresh-cw", "label": "Restart", "action": "reboot" },
                                    { "glyph": "power", "label": "Power Off", "action": "poweroff" },
                                ]
                                delegate: PowerCircle {
                                    required property var modelData
                                    width: parent.width / 4
                                    height: 84
                                    glyph: modelData.glyph
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

                    // ---- More Settings --------------------------------------
                    Column {
                        width: parent.width
                        spacing: 0

                        Rectangle {
                            width: parent.width
                            height: 1
                            color: Theme.hairline
                        }
                        Item {
                            id: moreRow
                            opacity: 0
                            width: parent.width
                            height: 44

                            Glyph {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 17
                                height: 17
                                name: "sliders-horizontal"
                                color: Theme.textSecondary
                            }
                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 40
                                anchors.verticalCenter: parent.verticalCenter
                                text: "More Settings"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                            Glyph {
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 15
                                height: 15
                                name: "chevron-right"
                                color: Theme.textSecondary
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    backend.launchApp("/usr/share/applications/ix1-settings.desktop")
                                    backend.closeQuickSettings()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
