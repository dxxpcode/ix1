import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

// Control Center — a full-height sheet sliding in from the right edge,
// composed from the cc/ component kit. Windows-Quick-Settings breathing
// room, Tahoe-style modular mechanics.
Window {
    id: root
    visible: backend.quickSettingsOpen
    color: "transparent"

    // Whether the Wi-Fi network list is expanded under its tile. The
    // IX1_SHOW_NET demo env opens it for renders.
    property bool wifiExpanded: typeof demoNet !== "undefined" && demoNet

    readonly property color accentSolid: Theme.dark
        ? Qt.darker(Theme.accent, 1.35) : Theme.accent

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    // The Wi-Fi password field needs real key events — without this the
    // surface never gets keyboard focus on Wayland.
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityOnDemand
    // Anchors size the window under the layer shell; set it explicitly so
    // offscreen (headless render) grabs work too.
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

        // Frosted backdrop — blurred wallpaper + scrim, Tahoe-style.
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
            color: Theme.dark ? Qt.rgba(0, 0, 0, 0.22) : Qt.rgba(1, 1, 1, 0.25)
        }

        // Click outside the sheet dismisses it.
        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeQuickSettings()
        }

        // Left-edge shadow.
        DropShadow {
            anchors.fill: sheet
            source: sheet
            z: -1
            radius: 28
            samples: 33
            horizontalOffset: -14
            color: Qt.rgba(0, 0, 0, Theme.dark ? 0.45 : 0.25)
        }

        Rectangle {
            id: sheet
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 400
            color: Theme.glass
            clip: true

            // Lit inner left edge.
            Rectangle {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.topMargin: Theme.radius
                anchors.bottomMargin: Theme.radius
                width: 1
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.14 : 0.7) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Component.onCompleted: { enterAnim.restart(); enterStagger.restart() }
            onVisibleChanged: { if (visible) { enterAnim.restart(); enterStagger.restart() } }

            ParallelAnimation {
                id: enterAnim
                NumberAnimation { target: sheet; property: "opacity"; from: 0; to: 1; duration: 140 }
                NumberAnimation { target: sheet; property: "anchors.rightMargin"; from: -40; to: 0; duration: 200; easing.type: Easing.OutCubic }
            }
            SequentialAnimation {
                id: enterStagger
                ParallelAnimation {
                    NumberAnimation { target: tileRow; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: netSection; property: "opacity"; from: 0; to: 1; duration: 180 }
                }
                PauseAnimation { duration: 45 }
                ParallelAnimation {
                    NumberAnimation { target: appRow; property: "opacity"; from: 0; to: 1; duration: 180 }
                    NumberAnimation { target: sliderSection; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 45 }
                ParallelAnimation {
                    NumberAnimation { target: testRow; property: "opacity"; from: 0; to: 1; duration: 180 }
                    NumberAnimation { target: powerStrip; property: "opacity"; from: 0; to: 1; duration: 180 }
                }
                PauseAnimation { duration: 30 }
                NumberAnimation { target: foot; property: "opacity"; from: 0; to: 1; duration: 160 }
            }

            Flickable {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                contentHeight: col.implicitHeight + 32
                clip: true
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: col
                    width: parent.width
                    y: 16
                    spacing: 14

                    // ---- Toggle tiles --------------------------------------
                    Row {
                        id: tileRow
                        opacity: 0
                        width: parent.width
                        height: 60
                        spacing: 8

                        SheetTile {
                            width: (parent.width - 8) / 2
                            height: 60
                            glyph: "wifi"
                            glyphStrength: backend.wifiEnabled ? backend.wifiSignal : -1
                            title: "Wi-Fi"
                            subtitle: !backend.wifiEnabled ? "Off"
                                      : (backend.wifiSsid || "Not connected")
                            active: backend.wifiEnabled
                            flashing: backend.qsSection === "wifi"
                            chevron: true
                            expanded: root.wifiExpanded
                            onToggled: backend.toggleWifi()
                            onChevronClicked: root.wifiExpanded = !root.wifiExpanded
                        }
                        SheetTile {
                            width: (parent.width - 8) / 2
                            height: 60
                            glyph: "crescent"
                            title: "Focus"
                            subtitle: backend.dnd ? "On" : "Do Not Disturb"
                            active: backend.dnd
                            onToggled: backend.setDnd(!backend.dnd)
                        }
                    }

                    // ---- Wi-Fi networks ------------------------------------
                    SheetSection {
                        id: netSection
                        opacity: 0
                        width: parent.width
                        label: "Wi-Fi Networks"
                        meta: backend.wifiNetworks.length + " found"
                        height: root.wifiExpanded ? implicitHeight : 0
                        clip: true

                        // Height animates with the expand.
                        Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                        ListView {
                            width: parent.width
                            height: Math.min(contentHeight, 200)
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

                    // ---- Appearance + Settings -----------------------------
                    Item {
                        id: appRow
                        opacity: 0
                        width: parent.width
                        height: 60

                        Column {
                            anchors.left: parent.left
                            anchors.right: settingsBtn.left
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Text {
                                text: "Appearance"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            SegmentedControl {
                                width: parent.width
                                height: 26
                                model: ["Graphite", "Porcelain"]
                                currentIndex: backend.theme === "graphite" ? 0 : 1
                                onActivated: function(i) {
                                    if ((i === 0) !== (backend.theme === "graphite")) {
                                        backend.toggleTheme()
                                    }
                                }
                            }
                        }
                        GlyphButton {
                            id: settingsBtn
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            glyph: "gear"
                            onClicked: {
                                backend.launchApp("/usr/share/applications/ix1-settings.desktop")
                                backend.closeQuickSettings()
                            }
                        }
                    }

                    // ---- Sliders -------------------------------------------
                    SheetSection {
                        id: sliderSection
                        opacity: 0
                        width: parent.width

                        CapsuleSlider {
                            width: parent.width
                            height: 36
                            glyph: "speaker"
                            min: 0
                            max: 150
                            value: backend.volume
                            available: backend.volume >= 0
                            readout: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
                            onMoved: function(v) { backend.setVolume(v) }
                        }
                        CapsuleSlider {
                            width: parent.width
                            height: 36
                            glyph: "sun"
                            min: 0
                            max: 100
                            value: backend.brightness
                            available: backend.brightness >= 0
                            readout: backend.brightness >= 0 ? Math.round(backend.brightness) + "%" : "N/A"
                            onMoved: function(v) { backend.setBrightness(v) }
                        }
                    }

                    // ---- Test notification (dev/verification aid) ----------
                    Item {
                        id: testRow
                        opacity: 0
                        width: parent.width
                        height: 34

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: backend.dnd ? "Send test notification (muted by Focus)"
                                              : "Send test notification"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        GlyphButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 30
                            glyph: "send"
                            onClicked: backend.sendTestNotification()
                        }
                    }

                    // ---- Power ---------------------------------------------
                    Row {
                        id: powerStrip
                        opacity: 0
                        width: parent.width
                        height: 34

                        Repeater {
                            model: ["lock", "moon", "reboot", "power"]
                            delegate: GlyphButton {
                                required property string modelData
                                width: parent.width / 4
                                height: 34
                                glyph: modelData
                                onClicked: {
                                    if (modelData === "lock") {
                                        backend.lock()
                                    } else if (modelData === "moon") {
                                        backend.powerAction("suspend")
                                    } else {
                                        backend.powerAction(modelData)
                                    }
                                }
                            }
                        }
                    }

                    // ---- Status line ---------------------------------------
                    StatusLine {
                        id: foot
                        opacity: 0
                        width: parent.width
                        height: 18
                        leftText: backend.userName
                            + (backend.batteryPct >= 0 ? "  ·  " + backend.batteryPct + "%" : "")
                        rightText: "ix1"
                    }
                }
            }
        }
    }
}
