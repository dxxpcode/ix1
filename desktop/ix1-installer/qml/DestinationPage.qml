import QtQuick
import QtQuick.Layouts
import Ix1Installer

// Destination — the site's "Install in four steps" numbered-row pattern:
// index · model + device · size, hairline-separated inside one card.
Item {
    id: page
    property bool entered: StackLayout.isCurrentItem
    opacity: entered ? 1 : 0
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
            y: Math.max(24, fl.height * 0.12) + (page.entered ? 0 : 14)
            Behavior on y { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            width: 620
            spacing: 0

            StepBadge {
                text: "step 01"
                label: "destination"
            }
            GradientText {
                text: "Select a disk."
                pixelSize: 60
                Layout.topMargin: 18
            }
            Text {
                text: "ix1 needs 8 GB. Everything on the selected device is permanently erased."
                color: Theme.mutedFg
                font.family: Theme.fontSans
                font.pixelSize: 15
                lineHeight: 1.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.topMargin: 14
            }

            // Disk options — numbered rows, hairline-separated in one card.
            Rectangle {
                Layout.topMargin: 34
                Layout.fillWidth: true
                height: Math.max(64, backend.disks.length * 64)
                radius: Theme.radiusXl
                color: Theme.card
                border.width: 1
                border.color: Theme.border

                Text {
                    visible: backend.disks.length === 0
                    anchors.centerIn: parent
                    text: "Scanning for disks…"
                    color: Theme.dim
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
                    width: parent.width
                    Repeater {
                        model: backend.disks
                        delegate: Item {
                            width: parent.width
                            height: 64

                            // Hairline divider — like the site's list rows.
                            Rectangle {
                                visible: index > 0
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: Theme.border
                            }
                            // Selection wash inside the card.
                            Rectangle {
                                z: -1
                                anchors.fill: parent
                                anchors.margins: 1
                                radius: Theme.radiusXl - 1
                                color: index === backend.selectedDisk ? "#121214"
                                       : (rowHover.hovered ? Theme.cardHover : "transparent")
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                spacing: 16

                                // Index → check: the numbered-row pattern.
                                Item {
                                    width: 22; height: 22
                                    Text {
                                        anchors.centerIn: parent
                                        visible: index !== backend.selectedDisk
                                        text: "0" + (index + 1)
                                        color: Theme.dim
                                        font.family: Theme.fontMono
                                        font.pixelSize: 12
                                    }
                                    Rectangle {
                                        anchors.centerIn: parent
                                        visible: index === backend.selectedDisk
                                        width: 18; height: 18; radius: 9
                                        color: Theme.foreground
                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            color: Theme.buttonFg
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }
                                }
                                Column {
                                    spacing: 2
                                    Text {
                                        text: modelData.model
                                        color: Theme.foreground
                                        font.family: Theme.fontSans
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        text: modelData.name
                                        color: Theme.dim
                                        font.family: Theme.fontMono
                                        font.pixelSize: 11
                                    }
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: modelData.sizeText
                                    color: Theme.foreground
                                    font.family: Theme.fontMono
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }
                                // shadcn badge (secondary) — only on the pick.
                                Rectangle {
                                    visible: index === backend.selectedDisk
                                    implicitWidth: tag.implicitWidth + 16
                                    implicitHeight: 22
                                    radius: 11
                                    color: Theme.secondary
                                    Text {
                                        id: tag
                                        anchors.centerIn: parent
                                        text: "install here"
                                        color: Theme.foreground
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                    }
                                }
                            }
                            HoverHandler { id: rowHover }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.selectedDisk = index
                            }
                        }
                    }
                }
            }

            // LUKS — Switch row, subordinate card.
            Rectangle {
                Layout.topMargin: 12
                Layout.fillWidth: true
                height: 58
                radius: Theme.radiusXl
                color: backend.encrypt ? "#121214" : (luksHover.hovered ? Theme.cardHover : Theme.card)
                border.width: 1
                border.color: backend.encrypt ? Theme.dim : Theme.border
                Behavior on color { ColorAnimation { duration: 140 } }
                Behavior on border.color { ColorAnimation { duration: 140 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    Column {
                        spacing: 2
                        Text {
                            text: "Encrypt this disk"
                            color: Theme.foreground
                            font.family: Theme.fontSans
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: "LUKS — you set the passphrase on the next step. Recommended."
                            color: Theme.dim
                            font.family: Theme.fontSans
                            font.pixelSize: 12
                        }
                    }
                    Item { Layout.fillWidth: true }
                    // shadcn Switch — 44×24 track, sliding knob.
                    Rectangle {
                        width: 40; height: 22; radius: 11
                        color: backend.encrypt ? Theme.foreground : Theme.secondary
                        border.width: backend.encrypt ? 0 : 1
                        border.color: Theme.border
                        Behavior on color { ColorAnimation { duration: 160 } }
                        Rectangle {
                            width: 16; height: 16; radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            x: backend.encrypt ? 21 : 3
                            color: backend.encrypt ? Theme.card : Theme.mutedFg
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
