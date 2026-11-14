import QtQuick
import QtQuick.Layouts
import Ix1Installer

Item {
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    ColumnLayout {
        anchors.top: parent.top
        anchors.topMargin: Math.max(24, parent.height * 0.14)
        anchors.horizontalCenter: parent.horizontalCenter
        width: 620
        spacing: 0

        Text {
            text: "step 02 — account"
            color: Theme.textMuted
            font.family: Theme.fontMono
            font.pixelSize: 11
            font.letterSpacing: 2.2
        }
        GradientText {
            text: "Create your login."
            pixelSize: 54
            Layout.topMargin: 16
        }
        Text {
            text: "The account for the installed system."
            color: Theme.textSecondary
            font.family: Theme.fontSans
            font.pixelSize: 15
            Layout.topMargin: 14
        }

        ColumnLayout {
            Layout.topMargin: 26
            Layout.fillWidth: true
            spacing: 12

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
                    spacing: 7
                    Text {
                        text: modelData.l
                        color: Theme.textMuted
                        font.family: Theme.fontMono
                        font.pixelSize: 11
                        font.letterSpacing: 1.6
                    }
                    Item {
                        Layout.fillWidth: true
                        height: 50
                        // Focus ring — a soft halo outside the field border.
                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 6
                            height: parent.height + 6
                            radius: 13
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.14)
                            opacity: field.activeFocus ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 160 } }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 10
                            color: field.activeFocus ? "#0e0e10" : Theme.card
                            border.width: 1
                            border.color: field.activeFocus ? Theme.textSecondary
                                          : (fieldHover.hovered ? "#3a3a3f" : "#27272a")
                            Behavior on border.color { ColorAnimation { duration: 140 } }
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                        TextInput {
                            id: field
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 15
                            verticalAlignment: Text.AlignVCenter
                            color: Theme.textPrimary
                            font.family: Theme.fontSans
                            font.pixelSize: 15
                            echoMode: modelData.val === "pass" || modelData.val === "luks"
                                      ? TextInput.Password : TextInput.Normal
                            selectByMouse: true
                            activeFocusOnTab: true
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: field.text === "" && !field.activeFocus
                                text: modelData.ph
                                color: Theme.textDim
                                font.family: Theme.fontSans
                                font.pixelSize: 15
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
                    Column {
                        visible: modelData.val === "pass"
                        spacing: 8
                        Row {
                            spacing: 6
                            Repeater {
                                model: 4
                                Rectangle {
                                    width: 138; height: 3; radius: 2
                                    color: index < strength
                                           ? (strength < 3 ? Theme.amber : Theme.textPrimary)
                                           : "#26262a"
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }
                        }
                        Text {
                            text: strength < 1 ? "at least 8 characters"
                                : strength < 3 ? "weak — add numbers or symbols"
                                : strength < 4 ? "fair"
                                : "strong"
                            color: strength > 0 && strength < 3 ? Theme.amber : Theme.textMuted
                            font.family: Theme.fontMono
                            font.pixelSize: 11
                        }
                    }
                }
            }

            // Warning as a quiet amber line — informs, doesn't compete.
            Row {
                Layout.topMargin: 10
                spacing: 8
                Text {
                    text: "⚠"
                    color: Theme.amber
                    font.pixelSize: 12
                }
                Text {
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    color: Theme.textSecondary
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
