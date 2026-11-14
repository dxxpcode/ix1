import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ix1Installer

ApplicationWindow {
    id: win
    visibility: Window.FullScreen
    visible: true
    color: Theme.bg
    flags: Qt.FramelessWindowHint
    title: "ix1 install"

    property int step: typeof initialStep !== "undefined" ? initialStep : 0

    // Landing-page canvas: near-black base, hero glow, dot grid.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0a0a0c" }
            GradientStop { position: 0.5; color: "#050506" }
            GradientStop { position: 1.0; color: "#000000" }
        }
    }
    Rectangle {
        width: Math.min(parent.width * 1.3, 1500)
        height: 420
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: -160
        radius: width / 2
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.055) }
            GradientStop { position: 0.55; color: Qt.rgba(1, 1, 1, 0.018) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
    // Dot grid, fading with height — painted once, cheap in software.
    Canvas {
        anchors.fill: parent
        opacity: 0.5
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            const gap = 26
            for (let y = 0; y < height; y += gap) {
                const fade = Math.max(0, 0.5 - y / height)
                ctx.fillStyle = Qt.rgba(1, 1, 1, fade * 0.10)
                for (let x = 13; x < width; x += gap)
                    ctx.fillRect(x, y, 1.4, 1.4)
            }
        }
    }

    // Header — same chrome as the landing page nav.
    Rectangle {
        id: header
        anchors.top: parent.top
        width: parent.width
        height: 60
        color: Qt.rgba(0, 0, 0, 0.7)
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            spacing: 9
            Image {
                source: "qrc:/Ix1Installer/assets/logo-white.png"
                Layout.preferredHeight: 20
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            Text {
                text: "install"
                color: Theme.textMuted
                font.family: Theme.fontSans
                font.pixelSize: 13
                font.weight: Font.Medium
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "v0.8.0 — fedora 44 · x86_64"
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.border }
    }

    // Progress hairline directly under the header — fills a third per step.
    Rectangle {
        anchors.top: header.bottom
        anchors.topMargin: -1
        width: parent.width * (step + 1) / 3
        height: 2
        color: Theme.textPrimary
        Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    }

    // Content — pages crossfade in on step changes.
    StackLayout {
        id: pages
        anchors.top: header.bottom
        anchors.bottom: footer.top
        anchors.topMargin: 1
        width: parent.width
        currentIndex: win.step
        DestinationPage {}
        AccountPage {}
        DeployPage { id: deployPage }
    }

    // Footer
    Rectangle {
        id: footer
        anchors.bottom: parent.bottom
        width: parent.width
        height: 76
        color: Theme.bg
        Rectangle { anchors.top: parent.top; width: parent.width; height: 1; color: Theme.border }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 32
            anchors.rightMargin: 32
            Text {
                text: step === 0 ? "esc — quit installer" : "← back"
                color: backHover.hovered ? Theme.textSecondary : Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: 11
                visible: step < 2
                x: backHover.hovered && step > 0 ? -3 : 0
                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                HoverHandler { id: backHover }
                MouseArea {
                    anchors.fill: parent
                    enabled: step > 0 && !backend.installing && !backend.done
                    onClicked: win.step -= 1
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                }
            }
            Item { Layout.fillWidth: true }
            // Primary / danger CTA
            Rectangle {
                id: cta
                visible: step < 2 || backend.done
                radius: 10
                height: 44
                width: ctaLabel.implicitWidth + 56
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: step === 1 ? "#f15454" : "#ffffff" }
                    GradientStop { position: 1.0; color: step === 1 ? Theme.danger : "#dcdce0" }
                }
                scale: ctaMouse.pressed ? 0.965 : 1.0
                Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                // Hover ring — soft halo outside the button.
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 8
                    height: parent.height + 8
                    radius: 13
                    color: "transparent"
                    border.width: 1
                    border.color: step === 1 ? Qt.rgba(220/255, 38/255, 38/255, 0.45)
                                             : Qt.rgba(1, 1, 1, 0.22)
                    opacity: ctaMouse.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
                // Inner top highlight — lit edge.
                Rectangle {
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 2
                    height: 1
                    radius: 1
                    color: Qt.rgba(1, 1, 1, step === 1 ? 0.28 : 0.0)
                }
                Text {
                    id: ctaLabel
                    anchors.centerIn: parent
                    text: step === 0 ? "Continue →" : (step === 1 ? "Erase & install" : "Reboot")
                    color: step === 1 ? "#fff" : "#18181b"
                    font.family: Theme.fontSans
                    font.pixelSize: 14
                    font.weight: Font.Medium
                }
                MouseArea {
                    id: ctaMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: win.advance()
                }
            }
        }
    }

    function advance() {
        if (step === 0) {
            if (backend.selectedDisk >= 0) win.step = 1
        } else if (step === 1) {
            if (backend.userName !== "" && backend.password !== "" &&
                (!backend.encrypt || backend.luksPassphrase !== "")) {
                win.step = 2
                backend.startInstall()
            }
        } else if (backend.done) {
            backend.reboot()
        }
    }

    Shortcut { sequence: "Escape"; onActivated: {
        if (step === 0) Qt.quit()
        else if (step === 2) deployPage.cancelCountdown()
    } }
    Shortcut { sequence: "R"; onActivated: if (step === 2 && backend.done) backend.reboot() }
    Shortcut { sequence: "Return"; onActivated: win.advance() }
    Shortcut { sequence: "Enter"; onActivated: win.advance() }
}
