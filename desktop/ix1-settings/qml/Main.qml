import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Ix1Settings 1.0

Window {
    id: root
    width: 780
    height: 500
    visible: true
    title: "ix1 Settings"
    color: Theme.bgBase

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    property int currentPage: 0

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 190
            Layout.fillHeight: true
            color: Theme.surface1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Text {
                    text: "ix1 Settings"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    bottomPadding: 12
                }

                Repeater {
                    model: ["Appearance", "Sound", "Network", "About"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Theme.radius
                        color: index === root.currentPage ? Theme.surface3 : "transparent"

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            text: modelData
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentPage = index
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: "Graphite / Porcelain"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgBase

            StackLayout {
                anchors.fill: parent
                anchors.margins: 22
                currentIndex: root.currentPage

                AppearancePage {}
                SoundPage {}
                NetworkPage {}
                AboutPage {}
            }
        }
    }
}
