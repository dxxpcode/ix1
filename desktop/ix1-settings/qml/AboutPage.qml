import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "About"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: [
                    { key: "Operating system", value: "ix1" },
                    { key: "Version", value: "dev (bootc image)" },
                    { key: "Hostname", value: backend.hostName },
                    { key: "Kernel", value: backend.kernelVersion },
                    { key: "Session", value: "ix1 (KWin Wayland)" },
                    { key: "Settings backend", value: "NetworkManager · WirePlumber" }
                ]
                delegate: Rectangle {
                    Layout.fillWidth: true
                    height: 34
                    radius: 8
                    color: index % 2 === 0 ? Theme.surface1 : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12

                        Text {
                            text: modelData.key
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.value
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }
}
