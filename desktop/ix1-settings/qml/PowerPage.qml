import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Ix1Settings 1.0

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Power"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        Text {
            text: "Brightness — " + (backend.brightness < 0 ? "n/a" : backend.brightness + "%")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            height: 44
            radius: Theme.radius
            color: Theme.surface1
            border.color: Theme.hairline
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 12

                Text { text: "☀"; color: Theme.textSecondary; font.pixelSize: 15 }
                Slider {
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: backend.brightness < 0 ? 0 : backend.brightness
                    onMoved: backend.setBrightness(Math.round(value))
                }
                Text { text: "☀"; color: Theme.textSecondary; font.pixelSize: 17 }
            }
        }

        Text {
            text: "Idle"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            height: 100
            radius: Theme.radius
            color: Theme.surface1
            border.color: Theme.hairline
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Lock screen after"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        Layout.preferredWidth: 160
                        model: ["Never", "1 minute", "2 minutes", "5 minutes",
                                "10 minutes", "15 minutes", "30 minutes"]
                        property var mins: [0, 1, 2, 5, 10, 15, 30]
                        Component.onCompleted: currentIndex = mins.indexOf(backend.idleLockMinutes)
                        onActivated: backend.setIdleLockMinutes(mins[currentIndex])
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text {
                        text: "Suspend after"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }
                    ComboBox {
                        Layout.preferredWidth: 160
                        model: ["Never", "10 minutes", "20 minutes", "30 minutes",
                                "45 minutes", "60 minutes"]
                        property var mins: [0, 10, 20, 30, 45, 60]
                        Component.onCompleted: currentIndex = mins.indexOf(backend.idleSuspendMinutes)
                        onActivated: backend.setIdleSuspendMinutes(mins[currentIndex])
                    }
                }
            }
        }

        Text {
            visible: backend.batteryPct >= 0
            text: "Battery — " + backend.batteryPct + "%"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        Text {
            text: "Brightness applies through logind. Lock and suspend timers are handled by the shell's idle watcher."
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        Item { Layout.fillHeight: true }
    }
}
