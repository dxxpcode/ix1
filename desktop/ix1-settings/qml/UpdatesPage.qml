import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Ix1Settings 1.0

Item {
    id: page

    Component.onCompleted: backend.refreshUpdates()

    component UpdateButton: Rectangle {
        property string label: ""
        property bool primary: false
        signal clicked()

        implicitWidth: btnText.implicitWidth + 28
        implicitHeight: 32
        radius: 8
        color: primary ? Theme.accent : Theme.surface2
        border.color: primary ? "transparent" : Theme.hairline
        border.width: 1
        opacity: enabled ? 1.0 : 0.45

        Text {
            id: btnText
            anchors.centerIn: parent
            text: parent.label
            color: primary ? (Theme.dark ? "#0E0F12" : "#FFFFFF") : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: primary ? Font.DemiBold : Font.Normal
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            enabled: parent.enabled
            onClicked: parent.clicked()
        }
    }

    Flickable {
        anchors.fill: parent
        contentHeight: column.implicitHeight
        clip: true

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 16

            Text {
                text: "Updates"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }

            // ---- Operating system (bootc, image-based, signed) -------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: osColumn.implicitHeight + 32
                radius: Theme.radius
                color: Theme.surface1
                border.color: Theme.hairline
                border.width: 1

                ColumnLayout {
                    id: osColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "Operating system"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "ix1 " + backend.osRelease
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: backend.osImage !== "" ? backend.osImage : "bootc image"
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        elide: Text.ElideMiddle
                    }

                    Text {
                        Layout.fillWidth: true
                        text: backend.updateStatus !== ""
                              ? backend.updateStatus
                              : (backend.updateStaged
                                 ? "Update staged — restart to apply"
                                 : "Atomic image updates, verified by signature before installing.")
                        color: backend.updateStaged ? Theme.accent : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        UpdateButton {
                            label: "Check"
                            enabled: !backend.updateBusy
                            onClicked: backend.checkOsUpdate()
                        }
                        UpdateButton {
                            label: backend.updateStaged ? "Staged" : "Download Update"
                            primary: !backend.updateStaged
                            enabled: !backend.updateBusy && !backend.updateStaged
                            onClicked: backend.stageOsUpdate()
                        }
                        UpdateButton {
                            label: "Restart"
                            primary: backend.updateStaged
                            enabled: !backend.updateBusy
                            onClicked: backend.rebootSystem()
                        }
                        Item { Layout.fillWidth: true }
                        UpdateButton {
                            label: "Roll back"
                            enabled: backend.rollbackAvailable && !backend.updateBusy
                            onClicked: backend.rollbackOs()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "If an update fails, select the previous entry in the boot menu or roll back here. OS and app updates are separate."
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 11
                        wrapMode: Text.Wrap
                    }
                }
            }

            // ---- Applications (Flatpak) ------------------------------------
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: appColumn.implicitHeight + 32
                radius: Theme.radius
                color: Theme.surface1
                border.color: Theme.hairline
                border.width: 1

                ColumnLayout {
                    id: appColumn
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: "Applications (Flatpak)"
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: backend.flatpakUpdateCount < 0
                              ? "Checking applications…"
                              : (backend.flatpakUpdateCount === 0
                                 ? "All applications are up to date."
                                 : backend.flatpakUpdateCount + " application update(s) available.")
                        color: Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        UpdateButton {
                            label: "Update All"
                            primary: backend.flatpakUpdateCount > 0
                            enabled: !backend.updateBusy && backend.flatpakUpdateCount > 0
                            onClicked: backend.updateFlatpakApps()
                        }
                        UpdateButton {
                            label: "Open Software Center"
                            onClicked: backend.openSoftwareCenter()
                        }
                        Item { Layout.fillWidth: true }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }
        }
    }
}
