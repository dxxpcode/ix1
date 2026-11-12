import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            text: "Appearance"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.weight: Font.DemiBold
        }

        Text {
            text: "Theme"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        RowLayout {
            spacing: 14

            Repeater {
                model: [
                    { name: "Graphite", value: "graphite", bg: "#0E0F12", accent: "#8AB4FF" },
                    { name: "Porcelain", value: "porcelain", bg: "#F6F7F9", accent: "#3563E9" }
                ]
                delegate: Rectangle {
                    Layout.preferredWidth: 220
                    Layout.preferredHeight: 120
                    radius: Theme.radius
                    color: Theme.surface1
                    border.color: backend.theme === modelData.value ? Theme.accent : Theme.hairline
                    border.width: backend.theme === modelData.value ? 2 : 1

                    Column {
                        anchors.centerIn: parent
                        spacing: 8

                        Rectangle {
                            width: 96
                            height: 44
                            radius: 6
                            color: modelData.bg
                            border.color: Theme.hairline
                            border.width: 1

                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: modelData.accent
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.top: parent.top
                                anchors.topMargin: 8
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.setTheme(modelData.value)
                    }
                }
            }
        }

        Text {
            text: "Changes apply to the shell immediately and to new app windows."
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
}
