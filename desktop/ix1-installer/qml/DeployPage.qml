import QtQuick
import QtQuick.Layouts
import Ix1Installer

Item {
    id: deployPage
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Displayed % eases toward the real value instead of snapping.
    property real shown: backend.progress
    Behavior on shown { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

    // Elapsed seconds come from the backend's wall-clock timer — the
    // install blocks the GUI thread today, so a QML timer can't tick.
    property int rebootIn: -1
    function cancelCountdown() { deployPage.rebootIn = -1 }
    Connections {
        target: backend
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
                text: "elapsed " + deployPage.fmtElapsed(backend.installElapsed)
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
            // Completion badge — an emerald disc that pops in,
            // then the white check draws itself inside it.
            Rectangle {
                visible: backend.done
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                Layout.alignment: Qt.AlignBottom
                Layout.bottomMargin: 13
                radius: 21
                color: Theme.success
                scale: 0.4 + deployPage.ring * 0.6
                CheckMark {
                    anchors.centerIn: parent
                    width: 22; height: 22
                    strokeWidth: 2.4
                    checkColor: "#fafafa"
                    progress: Math.max(0, (deployPage.ring - 0.45) * 2.2)
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
                      + " · " + backend.installElapsed + "s"
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
        // Reboot countdown after completion — the seconds read primary.
        Row {
            Layout.topMargin: 8
            visible: backend.done && deployPage.rebootIn > 0
            spacing: 0
            Text {
                text: "rebooting in "
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
            Text {
                text: deployPage.rebootIn
                color: Theme.textPrimary
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.weight: Font.Medium
            }
            Text {
                text: " — esc to stay"
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }
        Text {
            Layout.topMargin: 8
            visible: backend.done && deployPage.rebootIn <= 0
            text: "reboot from the footer, or press r"
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
                    Item {
                        width: 10; height: 10
                        Rectangle {
                            visible: !phaseDone
                            anchors.centerIn: parent
                            width: 8; height: 8; radius: 4
                            color: phaseFailed ? Theme.danger
                                 : phaseActive ? Theme.amber : "#333338"
                            SequentialAnimation on opacity {
                                running: phaseActive && !phaseFailed
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                            }
                        }
                        CheckMark {
                            visible: phaseDone
                            anchors.centerIn: parent
                            width: 10; height: 10
                            strokeWidth: 1.6
                            progress: phaseDone ? 1 : 0
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
            // Lit top edge — matches the cards' inner highlight.
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2
                height: 1
                radius: 1
                color: Qt.rgba(1, 1, 1, 0.05)
            }
            Column {
                id: logCol
                anchors.fill: parent
                anchors.margins: 15
                anchors.topMargin: 15
                spacing: 8
                // Panel header — transcript label + event count.
                RowLayout {
                    width: logCol.width
                    Text {
                        text: "install log"
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                        font.letterSpacing: 1.6
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: backend.logLines.length + " events"
                        color: Theme.textDim
                        font.family: Theme.fontMono
                        font.pixelSize: 10
                    }
                }
                Rectangle {
                    width: logCol.width
                    height: 1
                    color: "#1c1c1f"
                }
                Repeater {
                    model: backend.logLines.slice(Math.max(0, backend.logLines.length - 6))
                    Text {
                        readonly property bool newest: index === backend.logLines.slice(Math.max(0, backend.logLines.length - 6)).length - 1
                        text: modelData
                        color: modelData.startsWith("✗") ? Theme.danger
                             : newest || modelData.startsWith("→") ? Theme.textPrimary
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
