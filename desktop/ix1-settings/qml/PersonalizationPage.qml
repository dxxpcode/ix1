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

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 14

            // Live preview: the chosen wallpaper with the shell's bar and dock.
            Rectangle {
                id: preview
                Layout.fillWidth: true
                Layout.minimumWidth: 320
                Layout.preferredHeight: 196
                radius: 14
                color: Theme.surface2
                clip: true

                Image {
                    anchors.fill: parent
                    source: "file://" + page.effectiveWallpaper
                    sourceSize.width: 720
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }

                // Top bar: mark, clock, tray.
                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 18
                    color: Theme.dark ? Qt.rgba(0.04, 0.05, 0.08, 0.50) : Qt.rgba(1, 1, 1, 0.45)
                    Image {
                        anchors.left: parent.left
                        anchors.leftMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        width: 10
                        height: 9
                        source: Qt.resolvedUrl(Theme.dark ? "assets/logo-dark.png" : "assets/logo-light.png")
                        sourceSize.width: 32
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(new Date(), "ddd h:mm AP")
                        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.85) : Qt.rgba(0, 0, 0, 0.75)
                        font.family: Theme.fontFamily
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }
                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4
                        Repeater {
                            model: [7, 7, 11, 7]
                            Rectangle {
                                width: modelData
                                height: 4
                                radius: 2
                                color: Theme.dark ? Qt.rgba(1, 1, 1, 0.7) : Qt.rgba(0, 0, 0, 0.5)
                            }
                        }
                    }
                }

                // Dock.
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: dockRow.width + 12
                    height: 26
                    radius: 9
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Theme.dark ? Qt.rgba(0.13, 0.19, 0.33, 0.55) : Qt.rgba(0.96, 0.98, 1, 0.55) }
                        GradientStop { position: 1.0; color: Theme.dark ? Qt.rgba(0.06, 0.09, 0.17, 0.65) : Qt.rgba(0.90, 0.93, 0.99, 0.50) }
                    }
                    border.width: 1
                    border.color: Theme.dark ? Qt.rgba(0.75, 0.85, 1, 0.18) : Qt.rgba(1, 1, 1, 0.8)
                    Row {
                        id: dockRow
                        anchors.centerIn: parent
                        spacing: 4
                        Repeater {
                            model: [["#5B9BFF", "#1E56D6"], ["#7FB0FF", "#2F6CE0"], ["#56D68B", "#1F9A55"],
                                    ["#FFC15A", "#E58A16"], ["#B38BFF", "#6D3FE0"], ["#9AA6B8", "#566173"]]
                            Rectangle {
                                width: 16
                                height: 16
                                radius: 5
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: modelData[0] }
                                    GradientStop { position: 1.0; color: modelData[1] }
                                }
                            }
                        }
                    }
                }

                // Corner mask (clip is rectangular) + hairline.
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
            }

            // Theme picker, stacked beside the preview.
            ColumnLayout {
                Layout.fillWidth: false
                Layout.minimumWidth: 220
                Layout.maximumWidth: 220
                Layout.preferredHeight: preview.height
                spacing: 10

                Repeater {
                    model: [
                        { name: "Graphite", hint: "Dark", value: "graphite", win: "#17181C", side: "#22242A",
                          line: Qt.rgba(1, 1, 1, 0.18), accent: "#8AB4FF", desk: "#0B1222" },
                        { name: "Porcelain", hint: "Light", value: "porcelain", win: "#FFFFFF", side: "#ECEEF2",
                          line: Qt.rgba(0, 0, 0, 0.12), accent: "#3563E9", desk: "#D6DEEE" }
                    ]
                    delegate: Rectangle {
                        readonly property var t: modelData
                        readonly property bool selected: backend.theme === t.value
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 14
                        color: selected ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.06) : "#FFFFFF")
                             : themeHover.containsMouse ? Theme.surface2 : Theme.surface1
                        border.width: 1
                        border.color: selected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.75)
                             : Theme.hairline
                        Behavior on color { ColorAnimation { duration: 120 } }

                        // Mini window in that theme's palette.
                        Rectangle {
                            id: art
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 78
                            height: 54
                            radius: 8
                            color: t.desk
                            clip: true
                            Rectangle {
                                x: 8; y: 8
                                width: parent.width - 8
                                height: parent.height
                                radius: 5
                                color: t.win
                                border.width: 1
                                border.color: t.line
                                Rectangle {
                                    x: 1; y: 1
                                    width: 20
                                    height: parent.height - 2
                                    radius: 4
                                    color: t.side
                                    Column {
                                        x: 5; y: 7
                                        spacing: 4
                                        Rectangle { width: 10; height: 3; radius: 1.5; color: t.accent }
                                        Rectangle { width: 8; height: 3; radius: 1.5; color: t.line }
                                        Rectangle { width: 8; height: 3; radius: 1.5; color: t.line }
                                    }
                                }
                                Column {
                                    x: 27; y: 7
                                    spacing: 4
                                    Rectangle { width: 26; height: 4; radius: 2; color: t.line }
                                    Rectangle { width: 36; height: 3; radius: 1.5; color: t.line; opacity: 0.7 }
                                    Rectangle { width: 30; height: 3; radius: 1.5; color: t.line; opacity: 0.7 }
                                }
                            }
                        }

                        Column {
                            anchors.left: art.right
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            Text {
                                text: t.name
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                                font.weight: selected ? Font.Medium : Font.Normal
                            }
                            Text {
                                text: t.hint
                                color: Theme.textSecondary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            width: 16
                            height: 16
                            radius: 8
                            color: "transparent"
                            border.width: selected ? 0 : 1.5
                            border.color: Qt.rgba(Theme.textSecondary.r, Theme.textSecondary.g, Theme.textSecondary.b, 0.6)
                            Rectangle {
                                visible: selected
                                anchors.fill: parent
                                radius: 8
                                color: Theme.accent
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: Theme.dark ? "#0E0F12" : "#FFFFFF"
                                }
                            }
                        }

                        MouseArea {
                            id: themeHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setTheme(t.value)
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 10
            SectionLabel { text: "Wallpaper"; Layout.topMargin: 0 }
            Item { Layout.fillWidth: true }
            Text {
                text: (backend.wallpapers.length + 1) + " options"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                opacity: 0.8
            }
        }

        GridLayout {
            id: grid
            Layout.fillWidth: true
            columns: 4
            columnSpacing: 14
            rowSpacing: 12
            readonly property real tileW: Math.floor((body.width - columnSpacing * (columns - 1)) / columns)

            // "Automatic" clears wallpaper= so the shell follows the theme.
            Repeater {
                model: [{ name: "Automatic", path: "" }].concat(backend.wallpapers)
                delegate: ColumnLayout {
                    readonly property bool selected: backend.wallpaper === modelData.path
                    readonly property bool auto: modelData.path === ""
                    Layout.preferredWidth: grid.tileW
                    spacing: 7

                    Item {
                        Layout.preferredWidth: grid.tileW
                        Layout.preferredHeight: Math.round(grid.tileW * 0.6)

                        Rectangle {
                            id: thumb
                            anchors.fill: parent
                            anchors.margins: 4
                            radius: 9
                            color: Theme.surface2
                            clip: true
                            scale: tileHover.containsMouse && !selected ? 1.02 : 1
                            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

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
                            // "A" badge marks the theme-following tile.
                            Rectangle {
                                visible: auto
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                radius: 13
                                color: Qt.rgba(0.06, 0.08, 0.14, 0.55)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.35)
                                Text {
                                    anchors.centerIn: parent
                                    text: "A"
                                    color: "#FFFFFF"
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
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
                                border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.08)
                            }
                        }
                        // Selection / hover ring sits outside the thumbnail.
                        Rectangle {
                            anchors.fill: parent
                            radius: 13
                            color: "transparent"
                            border.width: selected ? 2 : 1
                            border.color: selected ? Theme.accent
                                : tileHover.containsMouse ? Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.22)
                                : "transparent"
                        }
                        MouseArea {
                            id: tileHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setWallpaper(modelData.path)
                        }
                    }
                    Text {
                        Layout.leftMargin: 5
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
            Layout.leftMargin: 5
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
