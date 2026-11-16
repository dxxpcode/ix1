import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

Flickable {
    id: page
    contentHeight: body.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    readonly property string themeWallpaper: "/usr/share/ix1/wallpapers/"
        + (backend.theme === "porcelain" ? "porcelain" : "graphite") + ".png"
    readonly property string effectiveWallpaper: backend.wallpaper.length > 0
        ? backend.wallpaper : themeWallpaper

    ColumnLayout {
        id: body
        width: page.width
        spacing: 14

        PageHeader {
            title: "Personalization"
            subtitle: "Theme and wallpaper for your desktop."
        }

        // Live preview: the chosen wallpaper with the shell's bar and dock.
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 164
            radius: 14
            color: Theme.surface2
            clip: true
            border.width: 1
            border.color: Theme.hairline

            Image {
                anchors.fill: parent
                anchors.margins: 1
                source: "file://" + page.effectiveWallpaper
                sourceSize.width: 720
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                height: 14
                color: Theme.dark ? Qt.rgba(0.05, 0.06, 0.09, 0.55) : Qt.rgba(1, 1, 1, 0.55)
                Row {
                    anchors.right: parent.right
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    Repeater {
                        model: 4
                        Rectangle {
                            width: index === 3 ? 18 : 8
                            height: 4
                            radius: 2
                            color: Theme.dark ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.55)
                        }
                    }
                }
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: -6
                radius: parent.radius + 6
                color: "transparent"
                border.width: 7
                border.color: Theme.bgBase
            }
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: Theme.hairline
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                width: dockRow.width + 14
                height: 28
                radius: 9
                color: Theme.dark ? Qt.rgba(0.10, 0.15, 0.27, 0.55) : Qt.rgba(0.94, 0.96, 1, 0.55)
                border.width: 1
                border.color: Theme.dark ? Qt.rgba(0.75, 0.85, 1, 0.18) : Qt.rgba(1, 1, 1, 0.8)
                Row {
                    id: dockRow
                    anchors.centerIn: parent
                    spacing: 5
                    Repeater {
                        model: ["#2F7BF6", "#3B82F6", "#22C55E", "#F59E0B", "#8B5CF6", "#64748B"]
                        Rectangle {
                            width: 18
                            height: 18
                            radius: 5
                            color: modelData
                        }
                    }
                }
            }
        }

        SectionLabel { text: "Appearance" }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Repeater {
                model: [
                    { name: "Graphite", value: "graphite", win: "#17181C", side: "#1D1F24",
                      line: Qt.rgba(1, 1, 1, 0.16), accent: "#8AB4FF", desk: "#0B1222" },
                    { name: "Porcelain", value: "porcelain", win: "#FFFFFF", side: "#ECEEF2",
                      line: Qt.rgba(0, 0, 0, 0.12), accent: "#3563E9", desk: "#DCE3F1" }
                ]
                delegate: Item {
                    readonly property var t: modelData
                    readonly property bool selected: backend.theme === t.value
                    Layout.fillWidth: true
                    Layout.preferredHeight: 128

                    Rectangle {
                        anchors.fill: parent
                        radius: 14
                        color: Theme.surface1
                        border.width: selected ? 2 : 1
                        border.color: selected ? Theme.accent : Theme.hairline

                        // Mini window drawn in that theme's palette.
                        Rectangle {
                            id: art
                            anchors.top: parent.top
                            anchors.topMargin: 14
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width - 28
                            height: 74
                            radius: 8
                            color: t.desk
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 10
                                anchors.bottomMargin: 0
                                radius: 6
                                color: t.win
                                border.width: 1
                                border.color: t.line
                                Rectangle {
                                    width: parent.width * 0.28
                                    height: parent.height - 2
                                    x: 1; y: 1
                                    radius: 5
                                    color: t.side
                                    Column {
                                        x: 7; y: 9
                                        spacing: 5
                                        Repeater {
                                            model: 3
                                            Rectangle {
                                                width: index === 0 ? 26 : 20
                                                height: 4
                                                radius: 2
                                                color: index === 0 ? t.accent : t.line
                                            }
                                        }
                                    }
                                }
                                Column {
                                    x: parent.width * 0.28 + 10
                                    y: 9
                                    spacing: 6
                                    Rectangle { width: 54; height: 6; radius: 3; color: t.line }
                                    Rectangle { width: 82; height: 4; radius: 2; color: t.line; opacity: 0.7 }
                                    Rectangle { width: 66; height: 4; radius: 2; color: t.line; opacity: 0.7 }
                                }
                            }
                        }

                        Text {
                            anchors.left: art.left
                            anchors.top: art.bottom
                            anchors.topMargin: 11
                            text: t.name
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            font.weight: selected ? Font.Medium : Font.Normal
                        }
                        Rectangle {
                            anchors.right: art.right
                            anchors.top: art.bottom
                            anchors.topMargin: 11
                            width: 16
                            height: 16
                            radius: 8
                            color: selected ? Theme.accent : "transparent"
                            border.width: selected ? 0 : 1
                            border.color: Theme.textSecondary
                            Text {
                                visible: selected
                                anchors.centerIn: parent
                                text: "✓"
                                color: Theme.dark ? "#0E0F12" : "#FFFFFF"
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.setTheme(t.value)
                    }
                }
            }
        }

        SectionLabel { text: "Wallpaper" }

        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 12
            rowSpacing: 10
            readonly property real tileW: Math.floor((body.width - columnSpacing * (columns - 1)) / columns)

            // "Automatic" clears wallpaper= so the shell follows the theme.
            Repeater {
                model: [{ name: "Automatic", path: "" }].concat(backend.wallpapers)
                delegate: ColumnLayout {
                    readonly property bool selected: backend.wallpaper === modelData.path
                    readonly property bool auto: modelData.path === ""
                    Layout.preferredWidth: grid.tileW
                    spacing: 6

                    Item {
                        Layout.preferredWidth: grid.tileW
                        Layout.preferredHeight: Math.round(grid.tileW * 0.62)

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: "transparent"
                            border.width: 2
                            border.color: selected ? Theme.accent : "transparent"
                        }
                        Rectangle {
                            id: thumb
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 8
                            color: Theme.surface2
                            clip: true

                            Image {
                                visible: !auto
                                anchors.fill: parent
                                source: auto ? "" : "file://" + modelData.path
                                sourceSize.width: 320
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                            }
                            Row {
                                visible: auto
                                anchors.fill: parent
                                Item {
                                    width: parent.width / 2
                                    height: parent.height
                                    clip: true
                                    Image {
                                        width: thumb.width
                                        height: thumb.height
                                        source: auto ? "file:///usr/share/ix1/wallpapers/graphite.png" : ""
                                        sourceSize.width: 320
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }
                                Item {
                                    width: parent.width / 2
                                    height: parent.height
                                    clip: true
                                    Image {
                                        x: -parent.width
                                        width: thumb.width
                                        height: thumb.height
                                        source: auto ? "file:///usr/share/ix1/wallpapers/porcelain.png" : ""
                                        sourceSize.width: 320
                                        fillMode: Image.PreserveAspectCrop
                                    }
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: -4
                                radius: parent.radius + 4
                                color: "transparent"
                                border.width: 4
                                border.color: Theme.bgBase
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: parent.radius
                                color: "transparent"
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.10)
                            }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setWallpaper(modelData.path)
                        }
                    }
                    Text {
                        Layout.leftMargin: 4
                        text: auto ? "Automatic" : modelData.name.charAt(0).toUpperCase() + modelData.name.slice(1)
                        color: selected ? Theme.textPrimary : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                        font.weight: selected ? Font.Medium : Font.Normal
                    }
                }
            }
        }

        Text {
            Layout.topMargin: 2
            Layout.leftMargin: 4
            Layout.bottomMargin: 8
            text: "Automatic follows the theme. Add your own images to ~/.local/share/ix1/wallpapers."
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }
    }
}
