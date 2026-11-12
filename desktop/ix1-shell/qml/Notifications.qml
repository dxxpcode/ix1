import QtQuick
import org.kde.layershell 1.0

Window {
    id: root
    visible: items.length > 0
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorRight
    width: 372
    height: col.implicitHeight + 52

    Component.onCompleted: Theme.mode = backend.theme

    property var items: []

    function removeById(id) {
        const next = []
        for (let i = 0; i < items.length; ++i) {
            if (items[i].id !== id) {
                next.push(items[i])
            }
        }
        items = next
    }

    Connections {
        target: backend
        function onNotificationAdded(appName, summary, body, id, expireTimeout) {
            items = items.concat([{
                id: id,
                appName: appName,
                summary: summary,
                body: body,
                expire: expireTimeout > 0 ? expireTimeout : 5000
            }])
        }
        function onNotificationClosed(id) {
            root.removeById(id)
        }
    }

    Item {
        anchors.fill: parent

        Column {
            id: col
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.right: parent.right
            anchors.rightMargin: 12
            width: 348
            spacing: 8

            Repeater {
                model: items

                delegate: Rectangle {
                    required property var modelData

                    width: col.width
                    height: cardCol.implicitHeight + 20
                    radius: Theme.radius
                    color: Theme.surface1
                    border.color: Theme.hairline
                    border.width: 1

                    Timer {
                        interval: modelData.expire
                        running: true
                        onTriggered: backend.dismissNotification(modelData.id)
                    }

                    Column {
                        id: cardCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 10
                        spacing: 2

                        Row {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: modelData.appName
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                width: parent.width - 30
                            }
                            Item { width: 1; height: 1; Layout.fillWidth: true }
                            Rectangle {
                                width: 20
                                height: 20
                                radius: 6
                                color: closeArea.containsMouse ? Theme.surface3 : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: "×"
                                    color: Theme.textSecondary
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 14
                                }
                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: backend.dismissNotification(modelData.id)
                                }
                            }
                        }

                        Text {
                            visible: modelData.summary.length > 0
                            text: modelData.summary
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                        Text {
                            visible: modelData.body.length > 0
                            text: modelData.body
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
}
