import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

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
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    property string searchText: ""

    onVisibleChanged: {
        if (visible) {
            searchInput.text = ""
            searchInput.forceActiveFocus()
            enterAnim.restart()
        }
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation {
            target: dimmer
            property: "opacity"
            from: 0
            to: 1
            duration: 180
        }
        NumberAnimation {
            target: card
            property: "opacity"
            from: 0
            to: 1
            duration: 180
        }
        NumberAnimation {
            target: card
            property: "scale"
            from: 0.94
            to: 1
            duration: 240
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        id: dimmer
        anchors.fill: parent
        color: Theme.dark ? Qt.rgba(0, 0, 0, 0.45) : Qt.rgba(20, 30, 50, 0.25)

        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeLauncher()
        }
    }

    Rectangle {
        id: card
        transformOrigin: Item.Center
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        width: 580
        height: 380
        radius: Theme.radiusLarge
        color: Theme.glass
        border.color: Theme.hairline
        border.width: 1

        MouseArea { anchors.fill: parent; onClicked: {} }

        Column {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            Rectangle {
                width: parent.width
                height: 40
                radius: Theme.radius
                color: Theme.glassHover
                border.color: Theme.hairline
                border.width: 1

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
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

            GridView {
                width: parent.width
                height: parent.height - 52
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: backend.apps
                cellWidth: width / 4
                cellHeight: 96

                delegate: Item {
                    required property string name
                    required property string desktopFile
                    required property string categories

                    readonly property bool matches: searchText.length === 0
                        || name.toLowerCase().indexOf(searchText.toLowerCase()) >= 0
                        || categories.toLowerCase().indexOf(searchText.toLowerCase()) >= 0

                    width: GridView.view.cellWidth
                    height: matches ? GridView.view.cellHeight : 0
                    visible: matches

                    Column {
                        anchors.centerIn: parent
                        spacing: 4
                        width: parent.width

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 64
                            height: 64
                            radius: 16
                            scale: appArea.containsMouse ? 1.06 : 1.0
                            color: appArea.containsMouse ? Theme.glassHover : "transparent"

                            Behavior on scale {
                                NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
                            }

                            AppIcon {
                                anchors.centerIn: parent
                                width: 52
                                height: 52
                                desktopFileName: desktopFile
                                appTitle: name
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 8
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
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

    Shortcut {
        sequence: "Escape"
        onActivated: backend.closeLauncher()
    }
}
