import QtQuick
import QtQuick.Layouts
import Ix1Installer

// Account — the site's download-Card pattern: one card holds the whole
// form; the amber erase line sits under a hairline inside the same card.
Item {
    id: page
    property bool entered: StackLayout.isCurrentItem
    opacity: entered ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

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
                text: "step 02"
                label: "account"
            }
            GradientText {
                text: "Create your login."
                pixelSize: 60
                Layout.topMargin: 18
            }
            Text {
                text: "The account for the installed system."
                color: Theme.mutedFg
                font.family: Theme.fontSans
                font.pixelSize: 15
                Layout.topMargin: 14
            }

            // The form card — bg-card, hairline border, rounded-xl, p-6.
            Rectangle {
                Layout.topMargin: 34
                Layout.fillWidth: true
                implicitHeight: form.implicitHeight + 48
                radius: Theme.radiusXl
                color: Theme.card
                border.width: 1
                border.color: Theme.border

                ColumnLayout {
                    id: form
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 24
                    spacing: 18

                    Repeater {
                        model: [
                            { l: "full name",       ph: "Alex",                val: "full" },
                            { l: "username",        ph: "alex",                val: "user" },
                            { l: "password",        ph: "a strong password",   val: "pass" },
                            { l: "disk passphrase", ph: "for luks encryption", val: "luks",
                              hide: !backend.encrypt },
                        ]
                        delegate: ColumnLayout {
                            visible: !modelData.hide
                            Layout.fillWidth: true
                            spacing: 8

                            // shadcn Label — text-sm font-medium
                            Text {
                                text: modelData.l
                                color: Theme.mutedFg
                                font.family: Theme.fontSans
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            // shadcn Input — h-10, rounded-md, border-input,
                            // focus-visible ring-ring (offset ring).
                            Item {
                                Layout.fillWidth: true
                                height: 40
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width + 6
                                    height: parent.height + 6
                                    radius: Theme.radiusMd + 3
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Qt.rgba(212/255, 212/255, 216/255, 0.35)
                                    opacity: field.activeFocus ? 1 : 0
                                    Behavior on opacity { NumberAnimation { duration: 160 } }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    radius: Theme.radiusMd
                                    color: "transparent"
                                    border.width: 1
                                    border.color: field.activeFocus ? Theme.dim
                                                  : (fieldHover.hovered ? Theme.borderHover : Theme.input)
                                    Behavior on border.color { ColorAnimation { duration: 140 } }
                                }
                                TextInput {
                                    id: field
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    verticalAlignment: Text.AlignVCenter
                                    color: Theme.foreground
                                    font.family: Theme.fontSans
                                    font.pixelSize: 14
                                    echoMode: modelData.val === "pass" || modelData.val === "luks"
                                              ? TextInput.Password : TextInput.Normal
                                    selectByMouse: true
                                    activeFocusOnTab: true
                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: field.text === "" && !field.activeFocus
                                        text: modelData.ph
                                        color: Theme.dim
                                        font.family: Theme.fontSans
                                        font.pixelSize: 14
                                    }
                                    onTextChanged: {
                                        if (modelData.val === "full") backend.fullName = text
                                        else if (modelData.val === "user") backend.userName = text
                                        else if (modelData.val === "pass") backend.password = text
                                        else if (modelData.val === "luks") backend.luksPassphrase = text
                                    }
                                }
                                HoverHandler { id: fieldHover }
                            }
                            // strength meter under the password field
                            Row {
                                visible: modelData.val === "pass"
                                spacing: 6
                                Repeater {
                                    model: 4
                                    Rectangle {
                                        width: 130; height: 3; radius: 1.5
                                        color: index < page.strength
                                               ? (page.strength < 3 ? Theme.amber : Theme.foreground)
                                               : Theme.secondary
                                        Behavior on color { ColorAnimation { duration: 180 } }
                                    }
                                }
                            }
                            Text {
                                visible: modelData.val === "pass"
                                text: page.strength < 1 ? "at least 8 characters"
                                    : page.strength < 3 ? "weak — add numbers or symbols"
                                    : page.strength < 4 ? "fair"
                                    : "strong"
                                color: page.strength > 0 && page.strength < 3 ? Theme.amber : Theme.dim
                                font.family: Theme.fontMono
                                font.pixelSize: 11
                            }
                        }
                    }

                    // Hairline, then the amber erase line inside the card.
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.topMargin: 6
                        height: 1
                        color: Theme.border
                    }
                    Row {
                        Layout.topMargin: 2
                        spacing: 8
                        Text {
                            text: "⚠"
                            color: Theme.amber
                            font.pixelSize: 12
                        }
                        Text {
                            font.family: Theme.fontMono
                            font.pixelSize: 12
                            color: Theme.mutedFg
                            text: {
                                const d = backend.selectedDisk >= 0 && backend.disks[backend.selectedDisk]
                                          ? backend.disks[backend.selectedDisk].name : "the target disk";
                                d + (backend.encrypt ? " will be erased and encrypted."
                                                     : " will be erased.")
                            }
                        }
                    }
                }
            }
        }
    }

    property int strength: {
        const p = backend.password
        if (!p) return 0
        let s = 1
        if (p.length >= 8) s++
        if (/[0-9]/.test(p) && /[a-zA-Z]/.test(p)) s++
        if (/[^a-zA-Z0-9]/.test(p)) s++
        return s
    }
}
