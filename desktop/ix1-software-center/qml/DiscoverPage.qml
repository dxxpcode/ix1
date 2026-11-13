import QtQuick
import QtQuick.Layouts
import Ix1SoftwareCenter 1.0

Item {
    id: page
    signal openDetails(string id)

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Discover"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 80
                height: 34
                radius: Theme.radius
                color: refreshArea.containsMouse ? Theme.surface3 : Theme.surface2
                border.color: Theme.hairline
                border.width: 1
                Text {
                    anchors.centerIn: parent
                    text: "Refresh"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                MouseArea {
                    id: refreshArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.refreshRemote()
                }
            }
        }

        Text {
            visible: backend.remoteLoading
            text: "Loading Flathub applications…"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: backend.remoteApps
            spacing: 6

            delegate: Rectangle {
                width: ListView.view.width
                height: 64
                radius: Theme.radius
                color: rowArea.containsMouse ? Theme.surface2 : Theme.surface1
                border.color: Theme.hairline
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: model.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: model.summary
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    Text {
                        visible: model.installed
                        text: "Installed"
                        color: Theme.accent
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                    }

                    Rectangle {
                        visible: model.state === 1
                        width: 90
                        height: 28
                        radius: 8
                        color: Theme.surface3
                        Text {
                            anchors.centerIn: parent
                            text: "Working…"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: page.openDetails(model.id)
                }
            }
        }
    }
}
