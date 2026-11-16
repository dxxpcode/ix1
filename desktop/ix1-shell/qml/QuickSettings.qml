import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: backend.quickSettingsOpen
    color: "transparent"

    // Whether the Wi-Fi network list is expanded under its tile. The
    // IX1_SHOW_NET demo env opens it for renders.
    property bool wifiExpanded: typeof demoNet !== "undefined" && demoNet

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
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
            width: 384
            height: Math.min(contentCol.implicitHeight + 24, 980)
            radius: Theme.radius
            color: Theme.glass
            border.color: Theme.hairline
            border.width: 1
            clip: true

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
                    text: "Control Center"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                // ---- Toggle tiles --------------------------------------------------
                Grid {
                    width: parent.width
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    // Wi-Fi tile: body toggles the radio; chevron expands the
                    // network list. Flash when the tray's wifi zone targeted it.
                    Rectangle {
                        id: wifiTile
                        width: (parent.width - 8) / 2
                        height: 56
                        radius: Theme.radiusSmall
                        color: backend.wifiEnabled ? Theme.glassHover : Theme.surface2
                        border.color: backend.qsSection === "wifi"
                            ? Theme.accent : Theme.hairline
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: 350 } }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 10
                            color: backend.wifiEnabled ? Theme.accent : Theme.surface3

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
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: !backend.wifiEnabled ? "Off"
                                      : (backend.wifiSsid || "Not connected")
                                color: Theme.textSecondary
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
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "›"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            rotation: root.wifiExpanded ? 90 : 0
                            Behavior on rotation { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
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

                    // Do Not Disturb tile.
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 56
                        radius: Theme.radiusSmall
                        color: backend.dnd ? Theme.glassHover : Theme.surface2
                        border.color: Theme.hairline
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 10
                            color: backend.dnd ? Theme.accent : Theme.surface3

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
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: backend.dnd ? "On" : "Do Not Disturb"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setDnd(!backend.dnd)
                        }
                    }

                    // Appearance tile: graphite ⇄ porcelain.
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 56
                        radius: Theme.radiusSmall
                        color: Theme.surface2
                        border.color: Theme.hairline
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 10
                            color: Theme.surface3

                            Canvas {
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = Theme.textSecondary
                                    ctx.lineWidth = 1.4
                                    ctx.beginPath()
                                    ctx.arc(7.5, 7.5, 5.6, 0, Math.PI * 2)
                                    ctx.stroke()
                                    ctx.fillStyle = Theme.textSecondary
                                    ctx.beginPath()
                                    ctx.arc(7.5, 7.5, 5.6, -Math.PI / 2, Math.PI / 2)
                                    ctx.fill()
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
                                text: "Appearance"
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 12
                                elide: Text.ElideRight
                                width: parent.width
                            }
                            Text {
                                text: backend.theme === "graphite" ? "Graphite" : "Porcelain"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: parent.width
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.toggleTheme()
                        }
                    }

                    // Settings shortcut tile.
                    Rectangle {
                        width: (parent.width - 8) / 2
                        height: 56
                        radius: Theme.radiusSmall
                        color: Theme.surface2
                        border.color: Theme.hairline
                        border.width: 1

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 34
                            height: 34
                            radius: 10
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
                                font.pixelSize: 12
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
                                    anchors.right: netLock.visible ? netLock.left : netCheck.left
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
                                    visible: modelData.secure
                                    anchors.right: netCheck.left
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

                                // Check on the connected network.
                                Canvas {
                                    id: netCheck
                                    visible: modelData.inUse
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 12
                                    height: 10
                                    onPaint: {
                                        const ctx = getContext("2d")
                                        ctx.reset()
                                        ctx.strokeStyle = Theme.accent
                                        ctx.lineWidth = 1.6
                                        ctx.lineCap = "round"
                                        ctx.lineJoin = "round"
                                        ctx.beginPath()
                                        ctx.moveTo(1, 5)
                                        ctx.lineTo(4.5, 8.5)
                                        ctx.lineTo(11, 1.5)
                                        ctx.stroke()
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

                        // Volume slider.
                        Item {
                            width: parent.width
                            height: 30

                            Canvas {
                                id: speakerGlyph
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 14
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.fillStyle = Theme.textSecondary
                                    ctx.beginPath()
                                    ctx.moveTo(1, 5)
                                    ctx.lineTo(4, 5)
                                    ctx.lineTo(7.5, 1.5)
                                    ctx.lineTo(7.5, 12.5)
                                    ctx.lineTo(4, 9)
                                    ctx.lineTo(1, 9)
                                    ctx.closePath()
                                    ctx.fill()
                                    ctx.strokeStyle = Theme.textSecondary
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
                                    function onVolumeChanged() { speakerGlyph.requestPaint() }
                                }
                            }

                            Item {
                                anchors.left: speakerGlyph.right
                                anchors.leftMargin: 10
                                anchors.right: volPctText.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
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
                                id: volPctText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                horizontalAlignment: Text.AlignRight
                                text: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        // Brightness slider (N/A on hardware without backlight).
                        Item {
                            width: parent.width
                            height: 30
                            opacity: backend.brightness >= 0 ? 1 : 0.45

                            Canvas {
                                id: sunGlyph
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                onPaint: {
                                    const ctx = getContext("2d")
                                    ctx.reset()
                                    ctx.strokeStyle = Theme.textSecondary
                                    ctx.fillStyle = Theme.textSecondary
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

                            Item {
                                anchors.left: sunGlyph.right
                                anchors.leftMargin: 10
                                anchors.right: brightPctText.left
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                height: 22
                                visible: backend.brightness >= 0

                                Rectangle {
                                    id: brightTrack
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width
                                    height: 4
                                    radius: 2
                                    color: Theme.surface3

                                    Rectangle {
                                        width: brightTrack.width * Math.max(0, backend.brightness) / 100
                                        height: parent.height
                                        radius: 2
                                        color: Theme.accent
                                    }
                                }
                                Rectangle {
                                    x: brightTrack.width * Math.max(0, backend.brightness) / 100 - 7
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
                                    onPressed: function(mouse) { updateBright(mouse.x) }
                                    onPositionChanged: function(mouse) { if (pressed) updateBright(mouse.x) }
                                    function updateBright(x) {
                                        const v = Math.round(Math.max(0, Math.min(1, x / brightTrack.width)) * 100)
                                        backend.setBrightness(v)
                                    }
                                }
                            }
                            Text {
                                id: brightPctText
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                width: 34
                                horizontalAlignment: Text.AlignRight
                                text: backend.brightness >= 0 ? Math.round(backend.brightness) + "%" : "N/A"
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // ---- Test notification (dev/verification aid) -------------------
                Item {
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

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.hairline
                }

                // ---- Power -------------------------------------------------------
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
                            radius: Theme.radiusSmall
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
