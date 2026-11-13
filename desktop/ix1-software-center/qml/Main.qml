import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import Ix1SoftwareCenter 1.0

Window {
    id: root
    width: Math.min(900, Math.max(320, Screen.desktopAvailableWidth - 24))
    height: Math.min(560, Math.max(240, Screen.desktopAvailableHeight - 24))
    visible: true
    title: "ix1 Software Center"
    color: Theme.bgBase

    property string searchText: ""
    property var detailApp: null
    property int detailPage: 0

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
        function onOperationFinished() {
            if (root.detailApp) {
                root.detailApp = backend.appDetails(root.detailApp.id)
            }
        }
    }

    onSearchTextChanged: backend.setFilter(searchText)

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            color: Theme.surface1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6

                Text {
                    text: "ix1 Software Center"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    bottomPadding: 12
                }

                Repeater {
                    model: ["Discover", "Installed"]
                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: Theme.radius
                        color: index === root.detailPage ? Theme.surface3 : "transparent"

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
                            onClicked: { root.detailPage = index; root.detailApp = null }
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    text: backend.statusText
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgBase

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12

                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    placeholderText: "Search Flathub applications…"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    padding: 10
                    background: Rectangle {
                        radius: Theme.radius
                        color: Theme.surface1
                        border.color: Theme.hairline
                        border.width: 1
                    }
                    onTextChanged: root.searchText = text
                }

                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.detailPage

                    DiscoverPage {
                        onOpenDetails: function(id) {
                            root.detailApp = backend.appDetails(id)
                        }
                    }
                    InstalledPage {
                        onOpenDetails: function(id) {
                            root.detailApp = backend.appDetails(id)
                        }
                    }
                }
            }
        }
    }

    // Application detail overlay.
    Rectangle {
        anchors.fill: parent
        visible: root.detailApp !== null
        color: Qt.rgba(0, 0, 0, 0.5)
        z: 10

        MouseArea {
            anchors.fill: parent
            onClicked: root.detailApp = null
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(480, parent.width - 32)
            height: Math.min(520, parent.height - 48, detailColumn.implicitHeight + 48)
            radius: Theme.radius + 4
            color: Theme.surface1
            border.color: Theme.hairline
            border.width: 1

            MouseArea { anchors.fill: parent; onClicked: function(mouse) { mouse.accepted = true } }

            ColumnLayout {
                id: detailColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 24
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: root.detailApp ? root.detailApp.name : ""
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.detailApp ? root.detailApp.id : ""
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.detailApp ? root.detailApp.summary : ""
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    wrapMode: Text.WordWrap
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.hairline
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 16
                    rowSpacing: 8

                    Text { text: "Version"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    Text { text: root.detailApp ? root.detailApp.version : ""; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    Text { text: "Branch"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    Text { text: root.detailApp ? root.detailApp.branch : ""; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    Text { text: "Architecture"; color: Theme.textSecondary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                    Text { text: root.detailApp ? root.detailApp.arch : ""; color: Theme.textPrimary; font.family: Theme.fontFamily; font.pixelSize: 12 }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.hairline
                }

                Text {
                    text: "Permissions"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
                Text {
                    Layout.fillWidth: true
                    text: root.detailApp ? root.detailApp.permissions : ""
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 110
                        height: 36
                        radius: Theme.radius
                        color: closeArea.containsMouse ? Theme.surface3 : Theme.surface2
                        border.color: Theme.hairline
                        border.width: 1
                        Text {
                            anchors.centerIn: parent
                            text: "Close"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                        MouseArea {
                            id: closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.detailApp = null
                        }
                    }

                    Rectangle {
                        visible: root.detailApp && !root.detailApp.installed
                        width: 110
                        height: 36
                        radius: Theme.radius
                        color: installArea.containsMouse ? Theme.accent : Theme.accent
                        opacity: root.detailApp && root.detailApp.state === 1 ? 0.6 : 1
                        Text {
                            anchors.centerIn: parent
                            text: root.detailApp && root.detailApp.state === 1 ? "Installing…" : "Install"
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: installArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !(root.detailApp && root.detailApp.state === 1)
                            onClicked: backend.installApp(root.detailApp.id)
                        }
                    }

                    Rectangle {
                        visible: root.detailApp && root.detailApp.installed
                        width: 110
                        height: 36
                        radius: Theme.radius
                        color: launchArea.containsMouse ? Theme.accent : Theme.accent
                        Text {
                            anchors.centerIn: parent
                            text: "Open"
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: launchArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: backend.launchApp(root.detailApp.id)
                        }
                    }

                    Rectangle {
                        visible: root.detailApp && root.detailApp.installed
                        width: 110
                        height: 36
                        radius: Theme.radius
                        color: removeArea.containsMouse ? Theme.danger : Theme.danger
                        Text {
                            anchors.centerIn: parent
                            text: root.detailApp && root.detailApp.state === 1 ? "Working…" : "Remove"
                            color: "#FFFFFF"
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                        }
                        MouseArea {
                            id: removeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: !(root.detailApp && root.detailApp.state === 1)
                            onClicked: backend.removeApp(root.detailApp.id)
                        }
                    }
                }
            }
        }
    }
}
