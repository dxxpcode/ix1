import QtQuick
import QtQuick.Layouts
import Ix1Installer

Item {
    id: deployPage
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Displayed % eases toward the real value instead of snapping.
    property real shown: 0
    Behavior on shown { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
    Connections {
        target: backend
        function onProgressChanged() { deployPage.shown = backend.progress }
    }

    // Elapsed install timer + reboot countdown on completion.
    property int elapsed: 0
    property int rebootIn: -1
    function cancelCountdown() { deployPage.rebootIn = -1 }
    Timer {
        interval: 1000
        running: backend.installing && !backend.done
        repeat: true
        onTriggered: deployPage.elapsed++
    }
    Connections {
        target: backend
        function onInstallingChanged() { if (backend.installing) deployPage.elapsed = 0 }
        function onDoneChanged() { if (backend.done) deployPage.rebootIn = 10 }
    }
    Timer {
        interval: 1000
        repeat: true
        running: deployPage.rebootIn > 0
        onTriggered: {
            deployPage.rebootIn--
            if (deployPage.rebootIn === 0)
                backend.reboot()
        }
    }

    function fmtElapsed(s) {
        return (Math.floor(s / 60) < 10 ? "0" : "") + Math.floor(s / 60)
               + ":" + (s % 60 < 10 ? "0" : "") + s % 60
    }

    // Completion ring — draws itself when the install lands.
    property real ring: backend.done ? 1 : 0
    Behavior on ring { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }

    Flickable {
        id: fl
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: col.implicitHeight + col.y

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: fl.contentY = Math.max(0, Math.min(
                         fl.contentHeight - fl.height,
                         fl.contentY - event.angleDelta.y))
        }

        ColumnLayout {
            id: col
            x: Math.max(0, (fl.width - width) / 2)
            y: Math.max(24, fl.height * 0.14)
            width: 620
            spacing: 0

        RowLayout {
            spacing: 10
            Text {
                text: "step 03 — deploy"
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 2.2
            }
            // live pulse while writing
            Rectangle {
                visible: backend.installing && !backend.done && !backend.error
                width: 6; height: 6; radius: 3
                color: Theme.amber
                SequentialAnimation on opacity {
                    running: parent.visible
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                }
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: backend.installing
                text: "elapsed " + deployPage.fmtElapsed(deployPage.elapsed)
                color: Theme.textDim
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 1.2
            }
        }
        RowLayout {
            Layout.topMargin: 14
            spacing: 18
            GradientText {
                text: backend.done ? "Done." : (backend.error ? "Failed." : Math.round(deployPage.shown) + "%")
                pixelSize: 92
                gradient: !backend.error
                flatColor: Theme.danger
            }
            // Completion ring draws itself beside the headline.
            Canvas {
                visible: backend.done
                Layout.preferredWidth: 40
                Layout.preferredHeight: 40
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 14
                property real r: deployPage.ring
                onRChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    ctx.strokeStyle = "#fafafa"
                    ctx.lineWidth = 2
                    ctx.lineCap = "round"
                    const cx = width / 2, cy = height / 2, rad = 17
                    ctx.beginPath()
                    ctx.arc(cx, cy, rad, -Math.PI / 2,
                            -Math.PI / 2 + Math.PI * 2 * Math.min(r * 2, 1))
                    ctx.stroke()
                    if (r > 0.5) {
                        const t = Math.min((r - 0.5) * 2, 1)
                        ctx.beginPath()
                        ctx.moveTo(cx - 8, cy + 0.5)
                        ctx.lineTo(cx - 8 + 6 * t, cy + 0.5 + 6 * t)
                        if (t > 0.5)
                            ctx.lineTo(cx - 2 + 12 * (t - 0.5) * 2,
                                       cy + 6.5 - 13 * (t - 0.5) * 2)
                        ctx.stroke()
                    }
                }
            }
        }
        // Live line — running step, or the post-install summary.
        Row {
            Layout.topMargin: 10
            spacing: 0
            Text {
                text: backend.done
                    ? "installed to " + (backend.disks[backend.selectedDisk] || {}).name
                      + (backend.encrypt ? " · encrypted" : "")
                      + " · " + deployPage.elapsed + "s"
                    : backend.error ? backend.error
                    : (backend.progressText !== "" ? backend.progressText : "Preparing…")
                color: backend.error ? Theme.danger : Theme.textSecondary
                font.family: Theme.fontSans
                font.pixelSize: 15
            }
            Text {
                visible: backend.installing && !backend.done && !backend.error
                text: "  —  do not power off"
                color: Theme.textDim
                font.family: Theme.fontSans
                font.pixelSize: 15
            }
        }
        // Reboot countdown after completion.
        Text {
            Layout.topMargin: 6
            visible: backend.done
            text: deployPage.rebootIn > 0
                  ? "rebooting in " + deployPage.rebootIn + " — esc to stay"
                  : "reboot from the footer, or press r"
            color: Theme.textMuted
            font.family: Theme.fontMono
            font.pixelSize: 11
        }

        Item {
            Layout.topMargin: 30
            Layout.fillWidth: true
            height: 14
            // Track
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 4
                radius: 2
                color: "#1f1f23"
            }
            // Phase-boundary ticks on the track.
            Repeater {
                model: [0.2, 0.9]
                Rectangle {
                    x: parent.width * modelData - 0.5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1; height: 10
                    color: deployPage.shown / 100 >= modelData ? "#3f3f46" : "#26262a"
                }
            }
            // Glow under the fill
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * deployPage.shown / 100
                height: 10
                radius: 5
                color: backend.error ? Qt.rgba(220/255, 38/255, 38/255, 0.22)
                                     : Qt.rgba(1, 1, 1, 0.13)
            }
            // Fill with a lit leading edge
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * deployPage.shown / 100
                height: 4
                radius: 2
                color: backend.error ? Theme.danger : Theme.textPrimary
                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 8; height: 8; radius: 4
                    visible: deployPage.shown > 0 && !backend.done && !backend.error
                    color: "#ffffff"
                }
            }
        }

        // Phase checklist — pending → pulsing → done.
        RowLayout {
            Layout.topMargin: 26
            Layout.fillWidth: true
            spacing: 10
            Repeater {
                model: [
                    { l: "prepare disk", end: 20 },
                    { l: "deploy image", end: 90 },
                    { l: "finalize",     end: 100 }
                ]
                delegate: RowLayout {
                    spacing: 8
                    property bool phaseDone: backend.done || backend.progress >= modelData.end
                    property bool phaseActive: !phaseDone && (backend.installing || backend.error !== "")
                    property bool phaseFailed: phaseActive && backend.error !== ""
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: phaseDone ? Theme.textPrimary
                             : phaseFailed ? Theme.danger
                             : phaseActive ? Theme.amber : "#333338"
                        SequentialAnimation on opacity {
                            running: phaseActive && !phaseFailed
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                        }
                    }
                    Text {
                        text: modelData.l
                        color: phaseDone ? Theme.textSecondary
                             : phaseActive ? Theme.textPrimary : Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                    }
                    Rectangle {
                        visible: index < 2
                        Layout.fillWidth: true
                        height: 1
                        color: phaseDone ? "#3a3a3f" : "#1c1c1f"
                    }
                }
            }
        }

        // Install log — terminal viewport: last 6 lines, auto-follows.
        Rectangle {
            Layout.topMargin: 30
            Layout.fillWidth: true
            visible: backend.logLines.length > 0
            height: logCol.implicitHeight + 30
            radius: 12
            color: "#0a0a0b"
            border.width: 1
            border.color: "#1c1c1f"
            Column {
                id: logCol
                anchors.fill: parent
                anchors.margins: 15
                anchors.topMargin: 15
                spacing: 8
                Repeater {
                    model: backend.logLines.slice(Math.max(0, backend.logLines.length - 6))
                    Text {
                        text: modelData
                        color: modelData.startsWith("→") ? Theme.textPrimary
                             : modelData.startsWith("✗") ? Theme.danger
                             : Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                        opacity: 0
                        NumberAnimation on opacity { to: 1; duration: 260; running: true }
                    }
                }
            }
        }
        }
    }
}
