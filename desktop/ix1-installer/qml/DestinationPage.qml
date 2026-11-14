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
        Text {
            text: "Select a disk."
            color: Theme.textPrimary
            font.family: Theme.fontSans
            font.pixelSize: 54
            font.weight: Font.Bold
            font.letterSpacing: -2.5
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
            }

            Repeater {
                model: backend.disks
                delegate: Rectangle {
                    width: parent.width
                    height: 66
                    radius: 12
                    color: index === backend.selectedDisk
                           ? Theme.cardHover
                           : (diskHover.hovered ? "#0d0d0f" : Theme.card)
                    border.width: 1
                    border.color: index === backend.selectedDisk
                                  ? Theme.borderSel
                                  : (diskHover.hovered ? "#3a3a3f" : Theme.border)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        spacing: 15
                        Rectangle {
                            width: 40; height: 40; radius: 10
                            color: "#161618"
                            border.width: 1; border.color: "#26262a"
                            Text {
                                anchors.centerIn: parent
                                text: "▦"
                                color: Theme.textSecondary
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
                                text: "target"
                                color: Theme.textMuted
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
                color: luksHover.hovered ? "#0d0d0f" : Theme.card
                border.width: 1
                border.color: luksHover.hovered ? "#3a3a3f" : Theme.border

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
