import QtQuick
import QtQuick.Layouts
import Ix1Installer

// Deploy — the percentage IS the headline; install details live in the
// site's accordion pattern ("details ▾", hairline-separated).
Item {
    id: page
    property bool entered: StackLayout.isCurrentItem
    opacity: entered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    property bool detailsOpen: false

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
            y: Math.max(24, fl.height * 0.12) + (page.entered ? 0 : 14)
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            width: 620
            spacing: 0

            RowLayout {
                spacing: 10
                StepBadge {
                    text: "step 03"
                    label: "deploy"
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
            }
            // The counter IS the headline — gradient like the site's hero.
            GradientText {
                text: backend.done ? "Done." : (backend.error ? "Failed." : backend.progress + "%")
                pixelSize: 96
                letterSpacing: -4
                gradient: !backend.error
                flatColor: Theme.danger
                Layout.topMargin: 16
            }
            // Live line — current step + quiet hint.
            Row {
                Layout.topMargin: 8
                spacing: 0
                Text {
                    text: backend.done ? "ix1 is installed. Reboot to start using it."
                        : backend.error ? backend.error
                        : (backend.progressText !== "" ? backend.progressText : "Preparing…")
                    color: backend.error ? Theme.danger : Theme.mutedFg
                    font.family: Theme.fontSans
                    font.pixelSize: 15
                }
                Text {
                    visible: backend.installing && !backend.done && !backend.error
                    text: "  —  do not power off"
                    color: Theme.dim
                    font.family: Theme.fontSans
                    font.pixelSize: 15
                }
            }

            // shadcn Progress — thin track, indicator fill.
            Item {
                Layout.topMargin: 32
                Layout.fillWidth: true
                height: 12
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Theme.border
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * backend.progress / 100
                    height: 10
                    radius: 5
                    color: backend.error ? Qt.rgba(239/255, 68/255, 68/255, 0.20)
                                         : Qt.rgba(1, 1, 1, 0.12)
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * backend.progress / 100
                    height: 4
                    radius: 2
                    color: backend.error ? Theme.danger : Theme.foreground
                    Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8; height: 8; radius: 4
                        visible: backend.progress > 0 && !backend.done && !backend.error
                        color: "#ffffff"
                    }
                }
            }

            // Phase checklist — pending → pulsing → done.
            RowLayout {
                Layout.topMargin: 24
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
                            color: phaseDone ? Theme.foreground
                                 : phaseFailed ? Theme.danger
                                 : phaseActive ? Theme.amber : Theme.secondary
                            SequentialAnimation on opacity {
                                running: phaseActive && !phaseFailed
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.3; duration: 700; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 700; easing.type: Easing.InOutSine }
                            }
                        }
                        Text {
                            text: modelData.l
                            color: phaseDone ? Theme.mutedFg
                                 : phaseActive ? Theme.foreground : Theme.dim
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                        Rectangle {
                            visible: index < 2
                            Layout.fillWidth: true
                            height: 1
                            color: phaseDone ? Theme.dim : Theme.border
                        }
                    }
                }
            }

            // shadcn Accordion — hairline item, "details" + rotating chevron.
            ColumnLayout {
                Layout.topMargin: 28
                Layout.fillWidth: true
                spacing: 0
                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.border }
                Item {
                    Layout.fillWidth: true
                    height: 48
                    RowLayout {
                        anchors.fill: parent
                        Text {
                            text: "details"
                            color: accHover.hovered ? Theme.foreground : Theme.mutedFg
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: backend.logLines.length + " lines"
                            color: Theme.dim
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                        Text {
                            text: "▾"
                            color: Theme.mutedFg
                            font.pixelSize: 12
                            rotation: page.detailsOpen ? 180 : 0
                            Behavior on rotation { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }
                    }
                    HoverHandler { id: accHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.detailsOpen = !page.detailsOpen
                    }
                }
                Column {
                    visible: page.detailsOpen
                    Layout.fillWidth: true
                    Layout.bottomMargin: 8
                    spacing: 8
                    Repeater {
                        model: backend.logLines
                        Text {
                            text: modelData
                            color: modelData.startsWith("→") ? Theme.foreground
                                 : modelData.startsWith("✗") ? Theme.danger
                                 : Theme.dim
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            opacity: 0
                            NumberAnimation on opacity { to: 1; duration: 260; running: true }
                        }
                    }
                    Text {
                        visible: backend.logLines.length === 0
                        text: "no output yet"
                        color: Theme.dim
                        font.family: Theme.fontMono
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
