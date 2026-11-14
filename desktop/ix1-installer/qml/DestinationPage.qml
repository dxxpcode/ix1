import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ix1Installer

Item {
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    Repeater {
        model: 9
        Shortcut {
            sequence: (index + 1).toString()
            onActivated: if (index < backend.disks.length) backend.selectedDisk = index
        }
    }

    Flickable {
        id: fl
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: col.implicitHeight + col.y

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: fl.contentY = Math.max(0, Math.min(
                         fl.contentHeight - fl.height,
                         fl.contentY - event.angleDelta.y))
        }

        ColumnLayout {
            id: col
            x: Math.max(0, (fl.width - width) / 2)
            y: Math.max(24, fl.height * 0.14)
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

        // Segmented disk list — one bordered container, hairline dividers.
        Rectangle {
            Layout.topMargin: 34
            Layout.fillWidth: true
            height: Math.max(72, backend.disks.length * 72)
            radius: 14
            color: Theme.card
            border.width: 1
            border.color: Theme.border

            Text {
                visible: backend.disks.length === 0
                anchors.centerIn: parent
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

            Column {
                id: diskCol
                width: parent.width

                Repeater {
                    model: backend.disks
                    delegate: Item {
                        width: diskCol.width
                        height: 72

                        // Selection wash — quiet, fills the row's segment.
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            // Only the outer corners should be rounded on the
                            // first/last row; Qt clips neither, so the wash is
                            // drawn inset by the hairline instead.
                            visible: index === backend.selectedDisk
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: 13
                                color: "#121214"
                            }
                        }
                        // Hairline divider between rows (hidden beside the
                        // selected row's wash).
                        Rectangle {
                            visible: index > 0 && index !== backend.selectedDisk
                                     && index - 1 !== backend.selectedDisk
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            height: 1
                            color: "#1c1c1f"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            spacing: 16

                            // Leading check token.
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                color: index === backend.selectedDisk ? "#fafafa" : "transparent"
                                border.width: 1.5
                                border.color: index === backend.selectedDisk ? "#fafafa" : "#3f3f46"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Text {
                                    anchors.centerIn: parent
                                    visible: index === backend.selectedDisk
                                    text: "✓"
                                    color: "#18181b"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                }
                            }

                            Column {
                                spacing: 3
                                Text {
                                    text: modelData.model
                                    color: Theme.textPrimary
                                    font.family: Theme.fontSans
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
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
                                spacing: 5
                                Text {
                                    text: modelData.sizeText
                                    color: Theme.textPrimary
                                    font.family: Theme.fontMono
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    horizontalAlignment: Text.AlignRight
                                    anchors.right: parent.right
                                }
                                Rectangle {
                                    width: tagTxt.implicitWidth + 14
                                    height: 18
                                    radius: 4
                                    color: index === backend.selectedDisk ? "#242429" : "transparent"
                                    border.width: index === backend.selectedDisk ? 0 : 1
                                    border.color: "#26262a"
                                    anchors.right: parent.right
                                    Text {
                                        id: tagTxt
                                        anchors.centerIn: parent
                                        text: index === backend.selectedDisk ? "install here" : "target"
                                        color: index === backend.selectedDisk ? Theme.textSecondary : Theme.textMuted
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                        HoverHandler { id: diskHover }
                        MouseArea {
                            id: diskMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.selectedDisk = index
                        }
                        // Row hover tint behind content.
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 13
                            color: diskHover.hovered ? "#0d0d0f" : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                    }
                }
            }
        }

        // LUKS — a quieter option row, subordinate to the disk list.
        Rectangle {
            Layout.topMargin: 12
            Layout.fillWidth: true
            height: 62
            radius: 12
            color: backend.encrypt ? "#121214" : (luksHover.hovered ? "#0d0d0f" : Theme.card)
            border.width: 1
            border.color: backend.encrypt ? "#52525b"
                          : (luksHover.hovered ? "#3a3a3f" : Theme.border)
            Behavior on color { ColorAnimation { duration: 140 } }
            Behavior on border.color { ColorAnimation { duration: 140 } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                Column {
                    spacing: 3
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
