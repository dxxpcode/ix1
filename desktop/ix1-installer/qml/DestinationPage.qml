import QtQuick
import QtQuick.Layouts
import Ix1Installer

Item {
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.centerIn: parent
        width: 620
        spacing: 0

        Text {
            text: "step 01 — destination"
            color: Theme.textMuted
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.letterSpacing: 2.2
        }
        GradientText {
            text: "Select a disk."
            pixelSize: 54
            Layout.topMargin: 16
        }
        Text {
            text: "ix1 needs 8 GB. Everything on the selected device is permanently erased."
            color: Theme.textSecondary
            font.family: Theme.fontSans
            font.pixelSize: 15
            lineHeight: 1.6
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.topMargin: 14
        }

        Column {
            Layout.topMargin: 34
            width: parent.width
            spacing: 10

            Text {
                visible: backend.disks.length === 0
                text: "Scanning for disks…"
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 12
                SequentialAnimation on opacity {
                    running: backend.disks.length === 0
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.35; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Repeater {
                model: backend.disks
                delegate: Rectangle {
                    width: parent.width
                    height: 68
                    radius: 12
                    color: index === backend.selectedDisk
                           ? "#121214"
                           : (diskHover.hovered ? "#0d0d0f" : Theme.card)
                    border.width: 1
                    border.color: index === backend.selectedDisk
                                  ? "#8b8b93"
                                  : (diskHover.hovered ? "#3a3a3f" : Theme.border)
                    scale: diskMouse.pressed ? 0.99 : 1.0
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Behavior on color { ColorAnimation { duration: 140 } }

                    // Inner top hairline — the lit edge of the selected card.
                    Rectangle {
                        visible: index === backend.selectedDisk
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 2
                        height: 1
                        radius: 1
                        color: Qt.rgba(1, 1, 1, 0.14)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 15
                        Rectangle {
                            width: 40; height: 40; radius: 10
                            color: index === backend.selectedDisk ? "#1b1b1f" : "#161618"
                            border.width: 1
                            border.color: index === backend.selectedDisk ? "#333338" : "#26262a"
                            Behavior on color { ColorAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            Text {
                                anchors.centerIn: parent
                                text: "▦"
                                color: index === backend.selectedDisk ? Theme.textPrimary : Theme.textSecondary
                                font.pixelSize: 15
                            }
                        }
                        Column {
                            spacing: 2
                            Text {
                                text: modelData.model
                                color: Theme.textPrimary
                                font.family: Theme.fontSans
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: modelData.name
                                color: Theme.textMuted
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Column {
                            spacing: 2
                            Text {
                                text: modelData.sizeText
                                color: Theme.textPrimary
                                font.family: Theme.fontMono
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                text: index === backend.selectedDisk ? "install here" : "target"
                                color: index === backend.selectedDisk ? Theme.textSecondary : Theme.textMuted
                                font.family: Theme.fontMono
                                font.pixelSize: 10
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        Rectangle {
                            width: 16; height: 16; radius: 8
                            color: "transparent"
                            border.width: index === backend.selectedDisk ? 5 : 1.5
                            border.color: index === backend.selectedDisk ? Theme.textPrimary : "#3f3f46"
                            Behavior on border.width { NumberAnimation { duration: 140 } }
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                        }
                    }
                    HoverHandler { id: diskHover }
                    MouseArea {
                        id: diskMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.selectedDisk = index
                    }
                }
            }

            // LUKS toggle
            Rectangle {
                width: parent.width
                height: 66
                radius: 12
                color: backend.encrypt ? "#121214" : (luksHover.hovered ? "#0d0d0f" : Theme.card)
                border.width: 1
                border.color: backend.encrypt ? "#52525b"
                              : (luksHover.hovered ? "#3a3a3f" : Theme.border)
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    Column {
                        spacing: 2
                        Text {
                            text: "Encrypt this disk"
                            color: Theme.textPrimary
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: "LUKS — you set the passphrase on the next step. Recommended."
                            color: Theme.textMuted
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                        }
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 44; height: 26; radius: 13
                        color: backend.encrypt ? Theme.textPrimary : "#3f3f46"
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Rectangle {
                            width: 22; height: 22; radius: 11
                            y: 2
                            x: backend.encrypt ? 20 : 2
                            color: backend.encrypt ? "#09090b" : Theme.textPrimary
                            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                        }
                    }
                }
                HoverHandler { id: luksHover }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.encrypt = !backend.encrypt
                }
            }
        }
    }
}
