import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

Item {
    Component.onCompleted: backend.refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Sound"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        Text {
            text: "Output volume — " + backend.volume + "%"
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

                Text {
                    text: "−"
                    color: Theme.textSecondary
                    font.pixelSize: 16
                }
                Slider {
                    id: volumeSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 150
                    value: backend.volume < 0 ? 0 : backend.volume
                    onMoved: backend.setVolume(Math.round(value))
                }
                Text {
                    text: "+"
                    color: Theme.textSecondary
                    font.pixelSize: 16
                }
            }
        }

        Text {
            text: "Volume is managed by WirePlumber (wpctl). Mute and per-app controls are handled by the shell's quick settings."
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
}
