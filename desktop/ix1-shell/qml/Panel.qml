import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: true
    color: "transparent"
    width: 1920

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    height: 32

    readonly property color unlit: Theme.dark ? "#3A3D46" : "#C7CCD6"
    readonly property color lit: Theme.textSecondary

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.glass

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
        spacing: 7

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
        Text {
            visible: backend.activeApp !== ""
            text: "·"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: backend.activeApp !== ""
            text: backend.activeApp
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium
            elide: Text.ElideRight
            maximumLineCount: 1
            width: Math.min(implicitWidth, 160)
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

    // Center: date + clock (click opens the calendar popover)
    Rectangle {
        id: clockZone
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: clock.implicitWidth + 16
        height: 24
        radius: 6
        color: clockArea.containsMouse ? Theme.surface3 : "transparent"

        Behavior on color { ColorAnimation { duration: 120 } }

        Text {
            id: clock
            anchors.centerIn: parent
            text: Qt.formatDateTime(new Date(), "ddd MMM d  HH:mm")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.weight: Font.Medium

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: clock.text = Qt.formatDateTime(new Date(), "ddd MMM d  HH:mm")
            }
        }
        MouseArea {
            id: clockArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: backend.toggleCalendar()
        }
    }

    // Right: live status tray — each zone opens its quick-settings section.
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        // Wi-Fi: tiered arcs fill with real signal strength.
        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: wifiArea.containsMouse ? Theme.surface3 : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: wifiGlyph
                anchors.centerIn: parent
                width: 16
                height: 12
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.lineWidth = 1.5
                    ctx.lineCap = "round"
                    const cx = width / 2
                    const cy = height * 0.80
                    const sig = backend.wifiEnabled ? backend.wifiSignal : -1
                    for (let i = 0; i < 3; ++i) {
                        ctx.strokeStyle = sig > 25 * (i + 1) ? root.lit : root.unlit
                        ctx.beginPath()
                        ctx.arc(cx, cy, width * (0.20 + i * 0.16), -Math.PI * 0.78, -Math.PI * 0.22)
                        ctx.stroke()
                    }
                    ctx.fillStyle = backend.wifiEnabled && sig >= 0 ? root.lit : root.unlit
                    ctx.beginPath()
                    ctx.arc(cx, cy, ctx.lineWidth * 0.62, 0, Math.PI * 2)
                    ctx.fill()
                }
            }
            Connections {
                target: backend
                function onWifiSignalChanged() { wifiGlyph.requestPaint() }
                function onWifiEnabledChanged() { wifiGlyph.requestPaint() }
            }
            MouseArea {
                id: wifiArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: backend.openQuickSettings("wifi")
            }
        }

        // Volume: speaker + waves by level, then the percentage.
        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: volArea.containsMouse ? Theme.surface3 : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                id: volGlyph
                anchors.centerIn: parent
                width: 16
                height: 12
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const v = backend.volume
                    ctx.fillStyle = root.lit
                    ctx.beginPath()
                    ctx.moveTo(1, 4.5)
                    ctx.lineTo(4, 4.5)
                    ctx.lineTo(7.5, 1.5)
                    ctx.lineTo(7.5, 10.5)
                    ctx.lineTo(4, 7.5)
                    ctx.lineTo(1, 7.5)
                    ctx.closePath()
                    ctx.fill()
                    const waves = v <= 0 ? 0 : (v < 70 ? 1 : 2)
                    ctx.strokeStyle = root.lit
                    ctx.lineWidth = 1.4
                    ctx.lineCap = "round"
                    for (let i = 0; i < waves; ++i) {
                        ctx.beginPath()
                        ctx.arc(7.5, 6, 2.6 + i * 2.3, -Math.PI / 3.4, Math.PI / 3.4)
                        ctx.stroke()
                    }
                }
            }
            Connections {
                target: backend
                function onVolumeChanged() { volGlyph.requestPaint() }
            }
            MouseArea {
                id: volArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: backend.openQuickSettings("sound")
            }
        }

        Text {
            text: backend.volume >= 0 ? Math.round(backend.volume) + "%" : "—"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 32
        }

        // Battery: only present on machines that have one.
        Rectangle {
            visible: backend.batteryPct >= 0
            width: 30
            height: 26
            radius: 13
            color: batArea.containsMouse ? Theme.surface3 : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                anchors.centerIn: parent
                width: 20
                height: 12
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = root.lit
                    ctx.lineWidth = 1.3
                    // Shell: rounded 15×8 cell + nub.
                    ctx.beginPath()
                    const r = 2, x = 1, y = 2, w = 15, h = 8
                    ctx.moveTo(x + r, y)
                    ctx.arcTo(x + w, y, x + w, y + h, r)
                    ctx.arcTo(x + w, y + h, x, y + h, r)
                    ctx.arcTo(x, y + h, x, y, r)
                    ctx.arcTo(x, y, x + w, y, r)
                    ctx.stroke()
                    ctx.fillStyle = root.lit
                    ctx.beginPath()
                    ctx.rect(x + w + 0.5, y + 2.5, 2, 3)
                    ctx.fill()
                    // Level fill.
                    const pct = Math.max(0, Math.min(100, backend.batteryPct)) / 100
                    ctx.beginPath()
                    ctx.rect(x + 1.6, y + 1.6, (w - 3.2) * pct, h - 3.2)
                    ctx.fill()
                }
                Connections {
                    target: backend
                    function onBatteryPctChanged() { parent.requestPaint() }
                }
            }
            MouseArea {
                id: batArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: backend.openQuickSettings("")
            }
        }

        // Quick settings: drawn sliders glyph.
        Rectangle {
            width: 26
            height: 26
            radius: 13
            color: sysTrayArea.containsMouse ? Theme.surface3 : "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Canvas {
                anchors.centerIn: parent
                width: 14
                height: 12
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.strokeStyle = root.lit
                    ctx.fillStyle = root.lit
                    ctx.lineWidth = 1.4
                    ctx.lineCap = "round"
                    const rows = [2.5, 6, 9.5]
                    const knobs = [9, 5, 11]
                    for (let i = 0; i < 3; ++i) {
                        ctx.beginPath()
                        ctx.moveTo(1, rows[i])
                        ctx.lineTo(13, rows[i])
                        ctx.stroke()
                        ctx.beginPath()
                        ctx.arc(knobs[i], rows[i], 1.6, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
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
