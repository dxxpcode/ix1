import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ix1Onboarding

ApplicationWindow {
    id: win
    visibility: Window.FullScreen
    visible: true
    color: Theme.bg
    flags: Qt.FramelessWindowHint
    title: "ix1 setup"

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
                source: "qrc:/Ix1Onboarding/assets/logo-white.png"
                Layout.preferredHeight: 20
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            Text {
                text: "setup"
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
        WelcomePage {}
        NetworkPage {}
        ReadyPage {}
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
                text: step === 0 ? "esc — skip everything" : "← back"
                color: backHover.hovered ? Theme.textSecondary : Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: 11
                x: backHover.hovered && step > 0 ? -3 : 0
                Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 140 } }
                HoverHandler { id: backHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: step > 0 ? win.step -= 1 : win.skip()
                }
            }
            Item { Layout.fillWidth: true }
            // Primary CTA
            Rectangle {
                id: cta
                radius: 10
                height: 44
                width: ctaLabel.implicitWidth + 56
                color: "transparent"
                gradient: Gradient {
                    orientation: Gradient.Vertical
                    GradientStop { position: 0.0; color: "#ffffff" }
                    GradientStop { position: 1.0; color: "#dcdce0" }
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
                    border.color: Qt.rgba(1, 1, 1, 0.22)
                    opacity: ctaMouse.containsMouse ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
                Text {
                    id: ctaLabel
                    anchors.centerIn: parent
                    text: step === 2 ? "Start exploring" : "Continue →"
                    color: "#18181b"
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
        if (step < 2)
            win.step += 1
        else {
            backend.finish()
            Qt.quit()
        }
    }

    function skip() {
        backend.finish()
        Qt.quit()
    }

    Shortcut { sequence: "Escape"; onActivated: win.skip() }
    // The network page owns Return/Enter — they walk and join there.
    Shortcut { sequence: "Return"; enabled: win.step !== 1; onActivated: win.advance() }
    Shortcut { sequence: "Enter"; enabled: win.step !== 1; onActivated: win.advance() }
}
