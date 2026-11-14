import QtQuick
import QtQuick.Layouts
import Ix1Installer

Item {
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: Math.max(24, parent.height * 0.14)
        anchors.horizontalCenter: parent.horizontalCenter
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
        }
        GradientText {
            text: backend.done ? "Done." : (backend.error ? "Failed." : backend.progress + "%")
            pixelSize: 92
            letterSpacing: -4
            gradient: !backend.error
            flatColor: Theme.danger
            Layout.topMargin: 14
        }
        // Live line — the step currently running, plus a quiet hint.
        Row {
            Layout.topMargin: 10
            spacing: 0
            Text {
                text: backend.done ? "ix1 is installed. Reboot to start using it."
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
            // Glow under the fill
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * backend.progress / 100
                height: 10
                radius: 5
                color: backend.error ? Qt.rgba(220/255, 38/255, 38/255, 0.22)
                                     : Qt.rgba(1, 1, 1, 0.13)
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }
            // Fill with a lit leading edge
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * backend.progress / 100
                height: 4
                radius: 2
                color: backend.error ? Theme.danger : Theme.textPrimary
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

        // Install log — bordered panel, lines fade in as they land.
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
                    model: backend.logLines
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
