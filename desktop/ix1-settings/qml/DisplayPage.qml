import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Ix1Settings 1.0

Item {
    Component.onCompleted: backend.refreshDisplays()

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Display"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        Text {
            visible: backend.displays.length === 0
            text: "No displays reported. Display configuration requires KScreen (kscreen-doctor)."
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        Repeater {
            model: backend.displays
            delegate: Rectangle {
                property var output: modelData
                Layout.fillWidth: true
                height: 150
                radius: Theme.radius
                color: Theme.surface1
                border.color: Theme.hairline
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        text: modelData.name
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Resolution"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        ComboBox {
                            id: modeBox
                            Layout.preferredWidth: 210
                            model: modelData.modes
                            Component.onCompleted: currentIndex = modelData.modes.indexOf(modelData.current)
                            onActivated: backend.setDisplayMode(output.name, output.modes[currentIndex])
                        }
                        Item { Layout.fillWidth: true }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "Scale"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Repeater {
                            model: [1.0, 1.25, 1.5, 1.75, 2.0]
                            delegate: Rectangle {
                                width: 52
                                height: 28
                                radius: 14
                                color: Math.abs(output.scale - modelData) < 0.01
                                    ? Theme.accent : Theme.surface2
                                border.color: Theme.hairline
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.toFixed(2).replace(/\.?0+$/, "") + "×"
                                    color: Math.abs(output.scale - modelData) < 0.01
                                        ? (Theme.dark ? "#0E0F12" : "#FFFFFF") : Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: backend.setDisplayScale(output.name, modelData)
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
