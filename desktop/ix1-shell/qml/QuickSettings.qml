import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: backend.quickSettingsOpen
    color: "transparent"

    // Whether the Wi-Fi network list is expanded under its tile. The
    // IX1_SHOW_NET demo env opens it for renders.
    property bool wifiExpanded: typeof demoNet !== "undefined" && demoNet

    // Solid accent for active controls — iOS-style decisive fills.
    // The dark theme's accent is a light blue; deepen it so white
    // glyphs and text read on it.
    readonly property color accentSolid: Theme.dark
        ? Qt.darker(Theme.accent, 1.35) : Theme.accent
    readonly property color accentSolidHot: Theme.dark
        ? Qt.darker(Theme.accent, 1.5) : Qt.darker(Theme.accent, 1.12)

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

        // Frosted backdrop — the desktop wallpaper pushed through a blur
        // and a scrim, so the card floats on glass like macOS Tahoe.
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

        // Clicking anywhere outside the card dismisses the panel. The tray
        // toggle is covered by this overlay while open, so this is the way out.
        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeQuickSettings()
        }

        // Soft shadow behind the card — real depth against the wallpaper.
        DropShadow {
            anchors.fill: card
            source: card
            z: -1
            radius: 24
            samples: 33
            spread: 0.15
            verticalOffset: 12
            horizontalOffset: 0
            color: Qt.rgba(0, 0, 0, Theme.dark ? 0.5 : 0.28)
        }

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.right: parent.right
            anchors.rightMargin: 12
            width: 384
            height: Math.min(contentCol.implicitHeight + 24, 980)
            radius: Theme.radius
            color: Theme.glass
            border.color: Theme.hairline
            border.width: 1
            clip: true

            // Lit inner top edge — the elevated-card language.
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
                    GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.14 : 0.7) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Component.onCompleted: { enterAnim.restart(); enterStagger.restart() }
            onVisibleChanged: { if (visible) { enterAnim.restart(); enterStagger.restart() } }

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

            // Sections fade in staggered — the card arrives in beats,
            // not as one flat plate.
            SequentialAnimation {
                id: enterStagger
                ParallelAnimation {
                    NumberAnimation { target: tileGrid; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                    NumberAnimation { target: netCard; property: "opacity"; from: 0; to: 1; duration: 180 }
                }
                PauseAnimation { duration: 45 }
                NumberAnimation { target: sliderCard; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 45 }
                ParallelAnimation {
                    NumberAnimation { target: footRow; property: "opacity"; from: 0; to: 1; duration: 180 }
                    NumberAnimation { target: powerRow; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
                }
                PauseAnimation { duration: 30 }
                NumberAnimation { target: statusStrip; property: "opacity"; from: 0; to: 1; duration: 160 }
            }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 10

                // ---- Toggle tiles --------------------------------------------------
                Grid {
                    id: tileGrid
                    opacity: 0
                    width: parent.width
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    // Wi-Fi tile: body toggles the radio; chevron expands the
                    // network list. Solid accent when on — an iOS-style lit
                    // control. Flash when the tray's wifi zone targeted it.
                    Item {
                        id: wifiTile
                        width: (parent.width - 8) / 2
                        height: 60

                        Squircle {
                            anchors.fill: parent
                            n: 5.5
                            color: wifiArea.containsMouse
                                ? (backend.wifiEnabled ? root.accentSolidHot : Theme.surface3)
                                : (backend.wifiEnabled ? root.accentSolid : Theme.surface2)
                            borderColor: backend.qsSection === "wifi"
                                ? "#FFFFFF" : (backend.wifiEnabled ? "transparent" : Theme.hairline)
                            borderWidth: backend.wifiEnabled ? 0 : 1

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on borderColor { ColorAnimation { duration: 350 } }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 17
                            color: backend.wifiEnabled
                                ? Qt.rgba(1, 1, 1, 0.24) : Theme.surface3

                            Canvas {
                                anchors.centerIn: parent
                                width: 17
                                height: 13
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.lineWidth = 1.5
                                    ctx.lineCap = "round"
                                    const cx = width / 2
                                    const cy = height * 0.80
                                    const sig = backend.wifiEnabled ? backend.wifiSignal : -1
                                    const lit = backend.wifiEnabled ? "#FFFFFF" : Theme.textSecondary
                                    const dim = backend.wifiEnabled ? Qt.rgba(1,1,1,0.35) : Theme.hairline
                                    for (let i = 0; i < 3; ++i) {
                                        ctx.strokeStyle = sig > 25 * (i + 1) ? lit : dim
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, width * (0.20 + i * 0.16),
                                                -Math.PI * 0.78, -Math.PI * 0.22)
                                        ctx.stroke()
                                    }
                                    ctx.fillStyle = backend.wifiEnabled && sig >= 0 ? lit : dim
                                    ctx.beginPath()
                                    ctx.arc(cx, cy, ctx.lineWidth * 0.62, 0, Math.PI * 2)
                                    ctx.fill()
                                }
                                Connections {
                                    target: backend
                                    function onWifiSignalChanged() { parent.requestPaint() }
                                    function onWifiEnabledChanged() { parent.requestPaint() }
                                }
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 52
                            anchors.right: wifiChev.left
                            anchors.rightMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "Wi-Fi"
                                color: backend.wifiEnabled ? "#FFFFFF" : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: !backend.wifiEnabled ? "Off"
                                      : (backend.wifiSsid || "Not connected")
                                color: backend.wifiEnabled
                                    ? Qt.rgba(1, 1, 1, 0.75) : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        // Chevron: expands the network list.
                        Text {
                            id: wifiChev
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: backend.wifiEnabled
                                ? Qt.rgba(1, 1, 1, 0.75) : Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            rotation: root.wifiExpanded ? 90 : 0
                            Behavior on rotation { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: wifiArea
                            anchors.fill: parent
                            anchors.rightMargin: 28
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.toggleWifi()
                        }
                        MouseArea {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 30
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.wifiExpanded = !root.wifiExpanded
                        }
                    }

                    // Focus tile — solid accent while Do Not Disturb runs.
                    Item {
                        width: (parent.width - 8) / 2
                        height: 60

                        Squircle {
                            anchors.fill: parent
                            n: 5.5
                            color: dndArea.containsMouse
                                ? (backend.dnd ? root.accentSolidHot : Theme.surface3)
                                : (backend.dnd ? root.accentSolid : Theme.surface2)
                            borderColor: backend.dnd ? "transparent" : Theme.hairline
                            borderWidth: backend.dnd ? 0 : 1

                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 17
                            color: backend.dnd
                                ? Qt.rgba(1, 1, 1, 0.24) : Theme.surface3

                            Canvas {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    const lit = backend.dnd ? "#FFFFFF" : Theme.textSecondary
                                    ctx.fillStyle = lit
                                    ctx.beginPath()
                                    ctx.arc(6, 7.5, 5.2, 0, Math.PI * 2)
                                    ctx.fill()
                                    ctx.globalCompositeOperation = "destination-out"
                                    ctx.beginPath()
                                    ctx.arc(9.5, 5.5, 4.4, 0, Math.PI * 2)
                                    ctx.fill()
                                }
                                Connections {
                                    target: backend
                                    function onDndChanged() { parent.requestPaint() }
                                }
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 52
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "Focus"
                                color: backend.dnd ? "#FFFFFF" : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: backend.dnd ? "On" : "Do Not Disturb"
                                color: backend.dnd
                                    ? Qt.rgba(1, 1, 1, 0.75) : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        MouseArea {
                            id: dndArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setDnd(!backend.dnd)
                        }
                    }

                    // Appearance: a segmented Graphite | Porcelain switcher
                    // with a sliding thumb — a real control, not a toggle tile.
                    Item {
                        width: (parent.width - 8) / 2
                        height: 60

                        Squircle {
                            anchors.fill: parent
                            n: 5.5
                            color: Theme.surface2
                            borderColor: Theme.hairline
                            borderWidth: 1
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 10
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

                            // Segmented track.
                            Item {
                                width: parent.width
                                height: 26

                                Squircle {
                                    anchors.fill: parent
                                    n: 8
                                    color: Theme.surface3
                                }

                                // Sliding thumb.
                                Squircle {
                                    y: 3
                                    x: backend.theme === "graphite" ? 3 : parent.width / 2 + 1
                                    width: parent.width / 2 - 4
                                    height: 20
                                    n: 8
                                    color: root.accentSolid

                                    Behavior on x {
                                        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    width: parent.width / 2
                                    height: parent.height
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Graphite"
                                    color: backend.theme === "graphite"
                                        ? "#FFFFFF" : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    anchors.right: parent.right
                                    width: parent.width / 2
                                    height: parent.height
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    text: "Porcelain"
                                    color: backend.theme === "porcelain"
                                        ? "#FFFFFF" : Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: function(mouse) {
                                        const want = mouse.x < width / 2 ? "graphite" : "porcelain"
                                        if (want !== backend.theme) {
                                            backend.toggleTheme()
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Settings shortcut tile.
                    Item {
                        width: (parent.width - 8) / 2
                        height: 60

                        Squircle {
                            anchors.fill: parent
                            n: 5.5
                            color: setArea.containsMouse ? Theme.surface3 : Theme.surface2
                            borderColor: Theme.hairline
                            borderWidth: 1

                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 17
                            color: Theme.surface3

                            Canvas {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = Theme.textSecondary
                                    ctx.lineWidth = 1.4
                                    ctx.lineCap = "round"
                                    ctx.beginPath()
                                    ctx.arc(8, 8, 3.4, 0, Math.PI * 2)
                                    ctx.stroke()
                                    for (let i = 0; i < 8; ++i) {
                                        const a = i * Math.PI / 4
                                        ctx.beginPath()
                                        ctx.moveTo(8 + Math.cos(a) * 5.2, 8 + Math.sin(a) * 5.2)
                                        ctx.lineTo(8 + Math.cos(a) * 6.8, 8 + Math.sin(a) * 6.8)
                                        ctx.stroke()
                                    }
                                }
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.leftMargin: 52
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1
                            Text {
                                text: "Settings"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: "System"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        MouseArea {
                            id: setArea
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

                // ---- Wi-Fi network list ------------------------------------------
                Rectangle {
                    id: netCard
                    opacity: 0
                    width: parent.width
                    height: root.wifiExpanded ? netCol.implicitHeight + 20 : 0
                    radius: Theme.radiusSmall
                    color: Theme.surface2
                    border.color: Theme.hairline
                    border.width: root.wifiExpanded ? 1 : 0
                    clip: true
                    visible: height > 0

                    Behavior on height {
                        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                    }

                    Column {
                        id: netCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 2

                        Row {
                            spacing: 6
                            Text {
                                text: "Wi-Fi Networks"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                            Text {
                                text: backend.wifiNetworks.length + " found"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                opacity: 0.7
                            }
                        }

                        ListView {
                            width: parent.width
                            height: Math.min(contentHeight, 152)
                            model: backend.wifiNetworks
                            interactive: contentHeight > height
                            clip: true
                            spacing: 2

                            delegate: Rectangle {
                                id: netRow
                                required property var modelData
                                // Secured networks without a saved profile need
                                // a password — click expands an inline field.
                                property bool pwOpen: false
                                width: ListView.view.width
                                height: pwOpen ? 66 : 34
                                radius: 8
                                clip: true
                                color: netArea.containsMouse ? Theme.surface3
                                      : (modelData.inUse ? Theme.glassHover : "transparent")
                                Behavior on height {
                                    NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
                                }

                                Canvas {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 15
                                    height: 12
                                    property var net: modelData
                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.lineWidth = 1.3
                                        ctx.lineCap = "round"
                                        const cx = width / 2
                                        const cy = height * 0.82
                                        const sig = net.signal
                                        const lit = net.inUse ? Theme.accent : Theme.textPrimary
                                        const dim = Theme.hairline
                                        for (let i = 0; i < 3; ++i) {
                                            ctx.strokeStyle = sig > 25 * (i + 1) ? lit : dim
                                            ctx.beginPath()
                                            ctx.arc(cx, cy, width * (0.20 + i * 0.16),
                                                    -Math.PI * 0.78, -Math.PI * 0.22)
                                            ctx.stroke()
                                        }
                                        ctx.fillStyle = sig >= 0 ? lit : dim
                                        ctx.beginPath()
                                        ctx.arc(cx, cy, ctx.lineWidth * 0.6, 0, Math.PI * 2)
                                        ctx.fill()
                                    }
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 30
                                    anchors.right: netLock.visible ? netLock.left : netPill.left
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.ssid
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                }

                                // Padlock for secured networks.
                                Canvas {
                                    id: netLock
                                    visible: modelData.secure && !modelData.inUse
                                    anchors.right: netPill.left
                                    anchors.rightMargin: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 10
                                    height: 12
                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.strokeStyle = Theme.textSecondary
                                        ctx.fillStyle = Theme.textSecondary
                                        ctx.lineWidth = 1.2
                                        ctx.beginPath()
                                        ctx.arc(5, 5, 2.6, Math.PI, 0)
                                        ctx.stroke()
                                        ctx.beginPath()
                                        ctx.rect(2, 5, 6, 6)
                                        ctx.fill()
                                    }
                                }

                                // "Connected" pill on the active network —
                                // the iOS Settings list treatment.
                                Rectangle {
                                    id: netPill
                                    visible: modelData.inUse
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: connText.implicitWidth + 12
                                    height: 18
                                    radius: 9
                                    color: Theme.accent

                                    Text {
                                        id: connText
                                        anchors.centerIn: parent
                                        text: "Connected"
                                        color: "#FFFFFF"
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                }

                                // Password field, shown when the row expands.
                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 30
                                    anchors.rightMargin: 10
                                    anchors.top: parent.top
                                    anchors.topMargin: 36
                                    height: 26
                                    radius: 6
                                    color: Theme.surface1
                                    border.color: pwField.activeFocus ? Theme.accent : Theme.hairline
                                    border.width: 1

                                    TextInput {
                                        id: pwField
                                        anchors.fill: parent
                                        anchors.leftMargin: 8
                                        anchors.rightMargin: 8
                                        verticalAlignment: Text.AlignVCenter
                                        color: Theme.textPrimary
                                        font.family: Theme.fontFamily
                                        font.pixelSize: 12
                                        echoMode: TextInput.Password
                                        selectByMouse: true
                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: !pwField.text && !pwField.activeFocus
                                            text: "Password"
                                            color: Theme.textSecondary
                                            font.family: Theme.fontFamily
                                            font.pixelSize: 12
                                        }
                                        onAccepted: {
                                            backend.connectWifi(modelData.ssid, text)
                                            netRow.pwOpen = false
                                            text = ""
                                        }
                                    }
                                }

                                MouseArea {
                                    id: netArea
                                    anchors.fill: parent
                                    anchors.bottomMargin: netRow.pwOpen ? 30 : 0
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (modelData.inUse) {
                                            return
                                        }
                                        if (modelData.secure) {
                                            netRow.pwOpen = !netRow.pwOpen
                                            if (netRow.pwOpen) {
                                                pwField.forceActiveFocus()
                                            }
                                        } else {
                                            backend.connectWifi(modelData.ssid, "")
                                        }
                                    }
                                }
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
                }

                // ---- Sliders -----------------------------------------------------
                Rectangle {
                    id: sliderCard
                    opacity: 0
                    width: parent.width
                    height: sliderCol.implicitHeight + 20
                    radius: Theme.radiusSmall
                    color: backend.qsSection === "sound" ? Theme.glassHover : Theme.surface2
                    border.color: Theme.hairline
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 350 } }

                    Column {
                        id: sliderCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 12

                        // Volume: iOS-style fill slider — the capsule IS
                        // the control; glyph and % live inside the fill.
                        Item {
                            width: parent.width
                            height: 36

                            Squircle {
                                id: volTrack
                                anchors.fill: parent
                                n: 9
                                color: Theme.surface3
                            }
                            Item {
                                width: Math.max(36, volTrack.width * Math.max(0, backend.volume) / 150)
                                height: parent.height
                                clip: true

                                Squircle {
                                    width: volTrack.width
                                    height: parent.height
                                    n: 9
                                    color: volArea.pressed ? root.accentSolidHot : root.accentSolid
                                }

                                Canvas {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 14
                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.fillStyle = "#FFFFFF"
                                        ctx.beginPath()
                                        ctx.moveTo(1, 5)
                                        ctx.lineTo(4, 5)
                                        ctx.lineTo(7.5, 1.5)
                                        ctx.lineTo(7.5, 12.5)
                                        ctx.lineTo(4, 9)
                                        ctx.lineTo(1, 9)
                                        ctx.closePath()
                                        ctx.fill()
                                        ctx.strokeStyle = "#FFFFFF"
                                        ctx.lineWidth = 1.2
                                        ctx.lineCap = "round"
                                        if (backend.volume > 0) {
                                            ctx.beginPath()
                                            ctx.arc(8, 7, 3, -Math.PI * 0.35, Math.PI * 0.35)
                                            ctx.stroke()
                                        }
                                        if (backend.volume > 60) {
                                            ctx.beginPath()
                                            ctx.arc(8, 7, 5.4, -Math.PI * 0.35, Math.PI * 0.35)
                                            ctx.stroke()
                                        }
                                    }
                                    Connections {
                                        target: backend
                                        function onVolumeChanged() { requestPaint() }
                                    }
                                }
                            }
                            // Readout pinned to the capsule's right edge —
                            // visible even at mute, when the fill is a sliver.
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
                                color: volTrack.width * Math.max(0, backend.volume) / 150
                                       > volTrack.width - 46 ? "#FFFFFF" : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                id: volArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: function(mouse) { updateVol(mouse.x) }
                                onPositionChanged: function(mouse) { if (pressed) updateVol(mouse.x) }
                                function updateVol(x) {
                                    const v = Math.round(Math.max(0, Math.min(1, x / volTrack.width)) * 150)
                                    backend.setVolume(v)
                                }
                            }
                        }

                        // Brightness: same fill pattern. N/A on hardware
                        // without a backlight.
                        Item {
                            width: parent.width
                            height: 36
                            opacity: backend.brightness >= 0 ? 1 : 0.45

                            Squircle {
                                id: brightTrack
                                anchors.fill: parent
                                n: 9
                                color: Theme.surface3
                            }
                            Item {
                                width: Math.max(36, brightTrack.width * Math.max(0, backend.brightness) / 100)
                                height: parent.height
                                clip: true

                                Squircle {
                                    width: brightTrack.width
                                    height: parent.height
                                    n: 9
                                    color: brightArea.pressed ? root.accentSolidHot : root.accentSolid
                                }

                                Canvas {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 16
                                    height: 16
                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.strokeStyle = "#FFFFFF"
                                        ctx.fillStyle = "#FFFFFF"
                                        ctx.lineWidth = 1.3
                                        ctx.beginPath()
                                        ctx.arc(8, 8, 3.4, 0, Math.PI * 2)
                                        ctx.fill()
                                        ctx.lineCap = "round"
                                        for (let i = 0; i < 8; ++i) {
                                            const a = i * Math.PI / 4
                                            ctx.beginPath()
                                            ctx.moveTo(8 + Math.cos(a) * 5.4, 8 + Math.sin(a) * 5.4)
                                            ctx.lineTo(8 + Math.cos(a) * 7.2, 8 + Math.sin(a) * 7.2)
                                            ctx.stroke()
                                        }
                                    }
                                }
                            }
                            Text {
                                anchors.right: parent.right
                                anchors.rightMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                text: backend.brightness >= 0 ? Math.round(backend.brightness) + "%" : "N/A"
                                color: backend.brightness >= 0
                                       && brightTrack.width * backend.brightness / 100
                                          > brightTrack.width - 46 ? "#FFFFFF" : Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                            MouseArea {
                                id: brightArea
                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: backend.brightness >= 0
                                cursorShape: Qt.PointingHandCursor
                                onPressed: function(mouse) { updateBright(mouse.x) }
                                onPositionChanged: function(mouse) { if (pressed) updateBright(mouse.x) }
                                function updateBright(x) {
                                    const v = Math.round(Math.max(0, Math.min(1, x / brightTrack.width)) * 100)
                                    backend.setBrightness(v)
                                }
                            }

                        }
                    }
                }

                // ---- Test notification (dev/verification aid) -------------------
                Item {
                    id: footRow
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
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 60
                        height: 26
                        radius: Theme.radiusSmall
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

                // ---- Power: drawn glyphs, one slim strip -------------------------
                Row {
                    id: powerRow
                    opacity: 0
                    width: parent.width
                    height: 34
                    spacing: 0

                    Repeater {
                        model: ["lock", "suspend", "reboot", "poweroff"]
                        delegate: Item {
                            required property string modelData
                            width: parent.width / 4
                            height: 34

                            Rectangle {
                                anchors.centerIn: parent
                                width: 30
                                height: 30
                                radius: 8
                                color: powerArea.containsMouse ? Theme.surface3 : "transparent"

                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            Canvas {
                                anchors.centerIn: parent
                                width: 16
                                height: 16
                                property string action: parent.modelData
                                property bool hot: powerArea.containsMouse
                                onHotChanged: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = hot ? Theme.textPrimary : Theme.textSecondary
                                    ctx.fillStyle = ctx.strokeStyle
                                    ctx.lineWidth = 1.4
                                    ctx.lineCap = "round"
                                    ctx.lineJoin = "round"
                                    if (action === "lock") {
                                        // shackle + body
                                        ctx.beginPath()
                                        ctx.arc(8, 6.5, 3.2, Math.PI, 0)
                                        ctx.stroke()
                                        ctx.beginPath()
                                        ctx.rect(4, 6.5, 8, 7)
                                        ctx.fill()
                                    } else if (action === "suspend") {
                                        // crescent
                                        ctx.beginPath()
                                        ctx.arc(8, 8, 5.4, 0, Math.PI * 2)
                                        ctx.fill()
                                        ctx.globalCompositeOperation = "destination-out"
                                        ctx.beginPath()
                                        ctx.arc(11, 5.5, 4.6, 0, Math.PI * 2)
                                        ctx.fill()
                                    } else if (action === "reboot") {
                                        // circular arrow
                                        ctx.beginPath()
                                        ctx.arc(8, 8, 5, -Math.PI * 0.3, Math.PI * 1.35)
                                        ctx.stroke()
                                        ctx.beginPath()
                                        ctx.moveTo(11.6, 2.4)
                                        ctx.lineTo(13.4, 4.6)
                                        ctx.lineTo(10.7, 5.2)
                                        ctx.closePath()
                                        ctx.fill()
                                    } else {
                                        // power: broken ring + stem
                                        ctx.beginPath()
                                        ctx.arc(8, 9, 4.8, -Math.PI * 0.38, Math.PI * 1.38)
                                        ctx.stroke()
                                        ctx.beginPath()
                                        ctx.moveTo(8, 2.5)
                                        ctx.lineTo(8, 7.5)
                                        ctx.stroke()
                                    }
                                }
                            }

                            MouseArea {
                                id: powerArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (modelData === "lock") {
                                        backend.lock()
                                    } else {
                                        backend.powerAction(modelData)
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- Status strip: quiet system facts ----------------------------
                Item {
                    id: statusStrip
                    opacity: 0
                    width: parent.width
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: backend.userName
                            + (backend.batteryPct >= 0 ? "  ·  " + backend.batteryPct + "%" : "")
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "ix1"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 10
                        opacity: 0.7
                    }
                }
            }
        }
    }
}
