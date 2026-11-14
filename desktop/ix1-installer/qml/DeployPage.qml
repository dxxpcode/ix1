import QtQuick
import QtQuick.Layouts
import Ix1Installer

Item {
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.centerIn: parent
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
        Text {
            text: backend.done ? "ix1 is installed. Reboot to start using it."
                : backend.error ? backend.error
                : "Deploying ix1. Do not power off."
            color: Theme.textSecondary
            font.family: Theme.fontSans
            font.pixelSize: 15
            Layout.topMargin: 10
        }

        Rectangle {
            Layout.topMargin: 28
            Layout.fillWidth: true
            height: 4
            radius: 2
            color: "#27272a"
            Rectangle {
                height: parent.height
                radius: 2
                width: parent.width * backend.progress / 100
                color: backend.error ? Theme.danger : Theme.textPrimary
                Behavior on width { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
            }
        }

        Column {
            Layout.topMargin: 26
            spacing: 9
            Repeater {
                model: backend.logLines
                Text {
                    text: modelData
                    color: modelData.startsWith("→") ? Theme.textPrimary
                         : modelData.startsWith("✗") ? Theme.danger
                         : Theme.textDim
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                }
            }
        }
    }
}
