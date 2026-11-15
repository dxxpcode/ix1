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
            onActivated: if (index < backend.disks.length &&
                            backend.disks[index].installable !== false)
                backend.selectedDisk = index
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
            height: Math.max(78, backend.disks.length * 78)
            radius: 14
            color: Theme.card
            border.width: 1
            border.color: Theme.border

            Row {
                visible: backend.disks.length === 0
                anchors.centerIn: parent
                spacing: 10
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = "#a1a1aa"
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(8, 8, 6, -Math.PI / 2, -Math.PI / 2 + Math.PI * 1.4)
                        ctx.stroke()
                    }
                    RotationAnimation on rotation {
                        running: backend.disks.length === 0
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 900
                    }
                }
                Text {
                    text: "scanning disks"
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Column {
                id: diskCol
                width: parent.width

                Repeater {
                    model: backend.disks
                    delegate: Item {
                        id: row
                        width: diskCol.width
                        height: 78

                        readonly property bool avail: modelData.installable !== false
                        readonly property bool sel: index === backend.selectedDisk
                        readonly property real frac: {
                            let m = 0
                            for (const d of backend.disks) m = Math.max(m, d.size || 0)
                            return m > 0 ? (modelData.size || 0) / m : 0
                        }
                        property real appear: 0

                        opacity: (avail ? 1.0 : 0.42) * appear
                        transform: Translate { y: (1 - row.appear) * 8 }

                        // Staggered entry — the list builds row by row.
                        SequentialAnimation {
                            running: true
                            PauseAnimation { duration: 60 + index * 45 }
                            NumberAnimation {
                                target: row; property: "appear"
                                to: 1; duration: 300; easing.type: Easing.OutCubic
                            }
                        }

                        // Selection cell — an elevated chip inside the segment.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 13
                            visible: row.sel
                            color: "#141416"
                            border.width: 1
                            border.color: "#38383e"
                        }
                        // Hairline divider between rows (hidden beside the
                        // selected row's cell).
                        Rectangle {
                            visible: index > 0 && !row.sel
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
                            anchors.leftMargin: 18
                            anchors.rightMargin: 20
                            spacing: 14

                            // Device glyph.
                            Rectangle {
                                width: 34; height: 34; radius: 9
                                color: row.sel ? "#1d1d21" : "#0d0d0f"
                                border.width: 1
                                border.color: row.sel ? "#33333a" : "#232327"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Image {
                                    anchors.centerIn: parent
                                    width: 18; height: 18
                                    sourceSize.width: 36; sourceSize.height: 36
                                    source: "qrc:/Ix1Installer/assets/icons/"
                                            + (modelData.tran === "usb" || modelData.removable
                                               ? "usb" : modelData.tran === "nvme" ? "nvme" : "drive")
                                            + ".svg"
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    text: modelData.model
                                    color: Theme.textPrimary
                                    font.family: Theme.fontSans
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                }
                                Text {
                                    text: modelData.name + " · "
                                          + (modelData.tran || "disk")
                                          + (modelData.fss ? " · " + modelData.fss
                                             : modelData.parts > 0
                                               ? " · " + modelData.parts
                                                 + (modelData.parts === 1 ? " partition" : " partitions")
                                               : "")
                                    color: Theme.textMuted
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                }
                                // Relative capacity hairline.
                                Rectangle {
                                    width: parent.width
                                    height: 2
                                    radius: 1
                                    color: "#1c1c1f"
                                    Rectangle {
                                        height: parent.height
                                        radius: 1
                                        width: Math.max(2, parent.width * row.frac)
                                        color: row.sel ? "#a1a1aa" : "#3f3f46"
                                        Behavior on color { ColorAnimation { duration: 160 } }
                                    }
                                }
                            }
                            Column {
                                spacing: 5
                                Row {
                                    anchors.right: parent.right
                                    spacing: 4
                                    Text {
                                        id: sizeNum
                                        text: (modelData.sizeText || "").split(" ")[0]
                                        color: Theme.textPrimary
                                        font.family: Theme.fontMono
                                        font.pixelSize: 17
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        text: (modelData.sizeText || "").split(" ")[1] || ""
                                        color: Theme.textMuted
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                        anchors.baseline: sizeNum.baseline
                                    }
                                }
                                Rectangle {
                                    width: tagTxt.implicitWidth + 14
                                    height: 18
                                    radius: 4
                                    color: row.sel ? "#242429" : "transparent"
                                    border.width: row.sel ? 0 : 1
                                    border.color: "#26262a"
                                    anchors.right: parent.right
                                    Text {
                                        id: tagTxt
                                        anchors.centerIn: parent
                                        text: !row.avail ? (modelData.note || "unavailable")
                                              : row.sel ? "install here" : "target"
                                        color: row.sel ? Theme.textSecondary : Theme.textMuted
                                        font.family: Theme.fontMono
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            // Trailing check token — drawn emerald check,
                            // pops in on selection.
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                scale: row.sel ? 1 : 0.4
                                opacity: row.sel ? 1 : 0
                                color: Qt.rgba(16/255, 185/255, 129/255, 0.10)
                                border.width: 1
                                border.color: Qt.rgba(16/255, 185/255, 129/255, 0.35)
                                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                CheckMark {
                                    anchors.centerIn: parent
                                    width: 12; height: 12
                                    strokeWidth: 1.8
                                    progress: row.sel ? 1 : 0
                                }
                            }
                        }
                        HoverHandler { id: diskHover; enabled: row.avail }
                        MouseArea {
                            anchors.fill: parent
                            enabled: row.avail
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: backend.selectedDisk = index
                        }
                        // Row hover tint behind content.
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 13
                            color: diskHover.hovered && !row.sel ? "#0d0d0f" : "transparent"
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
                anchors.leftMargin: 18
                anchors.rightMargin: 20
                spacing: 14
                Rectangle {
                    width: 34; height: 34; radius: 9
                    color: backend.encrypt ? "#1d1d21" : "#0d0d0f"
                    border.width: 1
                    border.color: backend.encrypt ? "#33333a" : "#232327"
                    Behavior on color { ColorAnimation { duration: 140 } }
                    Behavior on border.color { ColorAnimation { duration: 140 } }
                    Image {
                        anchors.centerIn: parent
                        width: 18; height: 18
                        sourceSize.width: 36; sourceSize.height: 36
                        source: "qrc:/Ix1Installer/assets/icons/shield.svg"
                    }
                }
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
