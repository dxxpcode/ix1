import QtQuick
import org.kde.layershell 1.0

Window {
    id: root
    visible: backend.launcherOpen
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityExclusive

    Component.onCompleted: Theme.mode = backend.theme

    property string searchText: ""

    onVisibleChanged: {
        if (visible) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(20, 30, 50, 0.25)

        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeLauncher()
        }
    }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 620
        height: 440
        radius: Theme.radius
        color: Theme.surface1
        border.color: Theme.hairline
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            Rectangle {
                width: parent.width
                height: 40
                radius: 10
                color: Theme.surface2

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    clip: true
                    onTextChanged: root.searchText = text

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: searchInput.text.length === 0
                        text: "Search applications…"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                    }
                }
            }

            ListView {
                width: parent.width
                height: parent.height - 52
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: backend.apps

                delegate: Item {
                    required property string name
                    required property string desktopFile
                    required property string categories
                    required property int index

                    readonly property bool matches: searchText.length === 0
                        || name.toLowerCase().indexOf(searchText.toLowerCase()) >= 0
                        || categories.toLowerCase().indexOf(searchText.toLowerCase()) >= 0

                    width: ListView.view.width
                    height: matches ? 44 : 0
                    visible: matches

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 2
                        radius: 8
                        color: appArea.containsMouse ? Theme.surface2 : "transparent"

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 12

                            Rectangle {
                                width: 28
                                height: 28
                                radius: 7
                                color: Theme.surface3
                                anchors.verticalCenter: parent.verticalCenter

                                Text {
                                    anchors.centerIn: parent
                                    text: name.length > 0 ? name.charAt(0).toUpperCase() : "?"
                                    color: Theme.textPrimary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: name
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                elide: Text.ElideRight
                                width: parent.width - 120
                            }
                        }

                        MouseArea {
                            id: appArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                backend.launchApp(desktopFile)
                                backend.closeLauncher()
                            }
                        }
                    }
                }
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: backend.closeLauncher()
    }
}
