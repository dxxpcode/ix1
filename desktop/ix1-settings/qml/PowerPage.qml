import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

Flickable {
    id: page
    contentHeight: body.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    readonly property bool charging: backend.batteryStatus === "Charging"
    readonly property bool full: backend.batteryStatus === "Full"
    // AC connected but held (charge limit / threshold).
    readonly property bool held: backend.batteryStatus === "Not charging"
    readonly property bool low: backend.batteryPct >= 0 && backend.batteryPct <= 20
        && !charging && !held && !full
    readonly property var lockMins: [0, 1, 2, 5, 10, 15, 30]
    readonly property var suspendMins: [0, 10, 20, 30, 45, 60]
    function minutesLabel(m) { return m === 0 ? "Never" : m === 1 ? "1 minute" : m + " minutes" }

    ColumnLayout {
        id: body
        width: page.width
        spacing: 14

        PageHeader {
            title: "Power"
            subtitle: "Battery, brightness and what happens when you step away."
        }

        // Battery readout.
        Rectangle {
            visible: backend.batteryPct >= 0
            Layout.fillWidth: true
            Layout.preferredHeight: 112
            radius: 14
            color: Theme.surface1
            border.width: 1
            border.color: Theme.hairline

            Item {
                id: cell
                anchors.left: parent.left
                anchors.leftMargin: 28
                anchors.verticalCenter: parent.verticalCenter
                width: 76
                height: 36
                Rectangle {
                    id: shell
                    width: 70
                    height: 36
                    radius: 9
                    color: "transparent"
                    border.width: 2
                    border.color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.35)
                    Rectangle {
                        x: 4
                        y: 4
                        height: parent.height - 8
                        width: Math.max(6, (parent.width - 8) * backend.batteryPct / 100)
                        radius: 5
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: page.low ? "#E5484D" : page.charging ? "#2FB463" : Qt.darker(Theme.accent, 1.2) }
                            GradientStop { position: 1.0; color: page.low ? "#FF6B6F" : page.charging ? "#46D17E" : Theme.accent }
                        }
                    }
                }
                Rectangle {
                    anchors.left: shell.right
                    anchors.leftMargin: 2
                    anchors.verticalCenter: shell.verticalCenter
                    width: 4
                    height: 12
                    radius: 2
                    color: Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.35)
                }
            }

            Column {
                anchors.left: cell.right
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    text: backend.batteryPct + "%"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 30
                    font.weight: Font.Medium
                }
                Text {
                    text: page.charging ? "Charging" : page.full ? "Fully charged"
                        : page.held ? "Plugged in, not charging"
                        : page.low ? "Low battery — plug in soon" : "On battery"
                    color: page.low ? "#E5484D" : Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }
            }

            Column {
                visible: backend.batteryMinutes > 0
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    anchors.right: parent.right
                    text: Math.floor(backend.batteryMinutes / 60) + " h "
                        + (backend.batteryMinutes % 60) + " min"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 17
                    font.weight: Font.Medium
                }
                Text {
                    anchors.right: parent.right
                    text: page.charging ? "until full" : "remaining"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }
            }
        }

        SectionLabel { text: "Screen" }

        SettingsGroup {
            SettingsRow {
                title: "Brightness"
                hint: backend.brightness < 0 ? "No adjustable backlight on this display" : ""
                divider: false
                Row {
                    visible: backend.brightness >= 0
                    spacing: 10
                    SunGlyph { size: 13; anchors.verticalCenter: parent.verticalCenter }
                    IxSlider {
                        width: 260
                        anchors.verticalCenter: parent.verticalCenter
                        value: Math.max(0, backend.brightness)
                        onMoved: (v) => backend.setBrightness(Math.round(v))
                    }
                    SunGlyph { size: 17; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        width: 38
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: Math.max(0, backend.brightness) + "%"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                    }
                }
            }
        }

        SectionLabel { text: "When idle" }

        SettingsGroup {
            SettingsRow {
                title: "Lock screen"
                hint: "After this long without input"
                IxSelect {
                    buttonWidth: 150
                    options: page.lockMins.map(page.minutesLabel)
                    currentIndex: page.lockMins.indexOf(backend.idleLockMinutes)
                    onActivated: (i) => backend.setIdleLockMinutes(page.lockMins[i])
                }
            }
            SettingsRow {
                title: "Suspend"
                hint: "Sleep to save power; you'll unlock on wake"
                divider: false
                IxSelect {
                    buttonWidth: 150
                    options: page.suspendMins.map(page.minutesLabel)
                    currentIndex: page.suspendMins.indexOf(backend.idleSuspendMinutes)
                    onActivated: (i) => backend.setIdleSuspendMinutes(page.suspendMins[i])
                }
            }
        }
    }
}
