import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

// Navigation rail: device card, grouped nav items (subtle fill + thin accent
// bar for the current page), right hairline.
Rectangle {
    id: bar
    property int currentPage: 0
    signal navigate(int page)

    readonly property var groups: [
        { title: "Desktop", items: [
            { page: 0, name: "Personalization", tint: "#4F7BF7", paths: [
                { d: "M8 2.2a5.8 5.8 0 1 0 0 11.6a5.8 5.8 0 1 0 0-11.6Z", fill: false },
                { d: "M8 2.2a5.8 5.8 0 0 0 0 11.6Z", fill: true } ] },
            { page: 1, name: "Display", tint: "#13A3B4", paths: [
                { d: "M3 3h10a1.3 1.3 0 0 1 1.3 1.3v5.9a1.3 1.3 0 0 1-1.3 1.3h-10a1.3 1.3 0 0 1-1.3-1.3v-5.9a1.3 1.3 0 0 1 1.3-1.3Z", fill: false },
                { d: "M5.6 14h4.8M8 11.6v2.4", fill: false } ] },
            { page: 2, name: "Power", tint: "#2FA866", paths: [
                { d: "M9.2 1.4L3.6 8.9h3.9l-.9 5.7l5.8-7.6h-4Z", fill: true } ] },
            { page: 3, name: "Sound", tint: "#E8873A", paths: [
                { d: "M2.3 6.1h2.4l3.4-2.9v9.6l-3.4-2.9h-2.4Z", fill: true },
                { d: "M10.6 5.6a3.4 3.4 0 0 1 0 4.8M12.6 3.7a6.1 6.1 0 0 1 0 8.6", fill: false } ] }
        ] },
        { title: "System", items: [
            { page: 4, name: "Network", tint: "#3C8DF0", paths: [
                { d: "M1.9 6.4a8.6 8.6 0 0 1 12.2 0M4.1 8.7a5.4 5.4 0 0 1 7.8 0M6.3 11a2.3 2.3 0 0 1 3.4 0", fill: false },
                { d: "M8 12.4a1.1 1.1 0 1 0 0 2.2a1.1 1.1 0 1 0 0-2.2Z", fill: true } ] },
            { page: 5, name: "Updates", tint: "#8B5CF6", paths: [
                { d: "M13.2 8a5.2 5.2 0 1 1-1.6-3.8", fill: false },
                { d: "M12.2 1.6v3h-3", fill: false } ] },
            { page: 6, name: "About", tint: "#6B7686", paths: [
                { d: "M8 2.2a5.8 5.8 0 1 0 0 11.6a5.8 5.8 0 1 0 0-11.6Z", fill: false },
                { d: "M8 7.4v4", fill: false },
                { d: "M8 4.3a.95.95 0 1 0 0 1.9a.95.95 0 1 0 0-1.9Z", fill: true } ] }
        ] }
    ]

    color: Theme.dark ? "#131418" : "#F0F2F5"

    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: Theme.hairline
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 13
        anchors.topMargin: 16
        anchors.bottomMargin: 14
        spacing: 2

        // Device card → About.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            Layout.bottomMargin: 10
            radius: 12
            color: deviceHover.containsMouse ? Theme.surface3 : Theme.surface1
            border.width: 1
            border.color: Theme.hairline

            Rectangle {
                id: mark
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: 38
                height: 38
                radius: 11
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#26365E" }
                    GradientStop { position: 1.0; color: "#0E1426" }
                }
                border.width: 1
                border.color: Qt.rgba(0.75, 0.85, 1, 0.22)
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 16
                    height: 1
                    color: Qt.rgba(0.8, 0.88, 1, 0.35)
                }
                Image {
                    anchors.centerIn: parent
                    width: 22
                    height: 20
                    source: Qt.resolvedUrl("../assets/logo-dark.png")
                    sourceSize.width: 64
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
            }
            Column {
                anchors.left: mark.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Text {
                    width: parent.width
                    text: backend.hostName.length ? backend.hostName : "ix1"
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
                Text {
                    width: parent.width
                    text: "ix1 " + backend.osRelease
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                color: Theme.textSecondary
                font.pixelSize: 18
                opacity: deviceHover.containsMouse ? 1 : 0.6
            }
            MouseArea {
                id: deviceHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bar.navigate(6)
            }
        }

        Repeater {
            model: bar.groups
            delegate: ColumnLayout {
                readonly property var group: modelData
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.leftMargin: 10
                    Layout.topMargin: index === 0 ? 0 : 12
                    Layout.bottomMargin: 4
                    text: group.title
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    font.letterSpacing: 0.5
                    font.capitalization: Font.AllUppercase
                    opacity: 0.8
                }

                Repeater {
                    model: group.items
                    delegate: Rectangle {
                        readonly property bool current: modelData.page === bar.currentPage
                        Layout.fillWidth: true
                        Layout.preferredHeight: 36
                        radius: 9
                        color: current ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(0.05, 0.07, 0.12, 0.06))
                             : itemHover.containsMouse ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(0.05, 0.07, 0.12, 0.035))
                             : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }

                        Rectangle {
                            visible: current
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            height: 16
                            radius: 1.5
                            color: Theme.accent
                        }

                        NavIcon {
                            id: navIcon
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            tint: modelData.tint
                            paths: modelData.paths
                        }
                        Text {
                            anchors.left: navIcon.right
                            anchors.leftMargin: 11
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.name
                            color: current ? Theme.textPrimary
                                 : Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.78)
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: current ? Font.Medium : Font.Normal
                        }
                        MouseArea {
                            id: itemHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: bar.navigate(modelData.page)
                        }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}
