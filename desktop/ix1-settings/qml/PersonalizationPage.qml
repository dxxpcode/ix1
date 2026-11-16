import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Ix1Settings 1.0

Item {
    ScrollView {
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            width: parent.width
            spacing: 16

            Text {
                text: "Personalization"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }

            Text {
                text: "Theme"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            RowLayout {
                spacing: 14

                Repeater {
                    model: [
                        { name: "Graphite", value: "graphite", bg: "#0E0F12", accent: "#8AB4FF" },
                        { name: "Porcelain", value: "porcelain", bg: "#F6F7F9", accent: "#3563E9" }
                    ]
                    delegate: Rectangle {
                        Layout.preferredWidth: 220
                        Layout.preferredHeight: 120
                        radius: Theme.radius
                        color: Theme.surface1
                        border.color: backend.theme === modelData.value ? Theme.accent : Theme.hairline
                        border.width: backend.theme === modelData.value ? 2 : 1

                        Column {
                            anchors.centerIn: parent
                            spacing: 8

                            Rectangle {
                                width: 96
                                height: 44
                                radius: 6
                                color: modelData.bg
                                border.color: Theme.hairline
                                border.width: 1

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: modelData.accent
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.top: parent.top
                                    anchors.topMargin: 8
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.name
                                color: Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 13
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.setTheme(modelData.value)
                        }
                    }
                }
            }

            Text {
                text: "Wallpaper"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 13
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 14
                rowSpacing: 12

                Repeater {
                    model: backend.wallpapers
                    delegate: ColumnLayout {
                        spacing: 4

                        Rectangle {
                            Layout.preferredWidth: 214
                            Layout.preferredHeight: 120
                            radius: 10
                            color: Theme.surface2
                            clip: true
                            border.color: backend.wallpaper === modelData.path
                                ? Theme.accent : Theme.hairline
                            border.width: backend.wallpaper === modelData.path ? 2 : 1

                            // Headless renders use demo: placeholders for the
                            // real files; painted as the palette each ships in.
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                radius: parent.radius - 1
                                visible: modelData.path.toString().indexOf("demo:") === 0
                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: {
                                            const n = modelData.name
                                            if (n === "porcelain" || n === "morning") return "#EDEFF5"
                                            if (n === "dusk") return "#1B1033"
                                            if (n === "wave") return "#06201F"
                                            return "#0A1428"
                                        }
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: {
                                            const n = modelData.name
                                            if (n === "porcelain" || n === "morning") return "#DDE3F0"
                                            if (n === "dusk") return "#0B0716"
                                            if (n === "wave") return "#03100F"
                                            return "#050A16"
                                        }
                                    }
                                }
                            }
                            Image {
                                anchors.fill: parent
                                anchors.margins: parent.border.width
                                visible: modelData.path.toString().indexOf("demo:") !== 0
                                source: modelData.path.toString().indexOf("demo:") !== 0
                                    ? "file://" + modelData.path : ""
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                                asynchronous: true
                            }
                            // Accent glow band, evoking the wallpapers' ribbon.
                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.topMargin: parent.height * 0.45
                                height: 2
                                radius: 1
                                visible: modelData.path.toString().indexOf("demo:") === 0
                                color: {
                                    const n = modelData.name
                                    if (n === "porcelain" || n === "morning") return "#B9C8F5"
                                    if (n === "dusk") return "#A64AE8"
                                    if (n === "wave") return "#2DD4D4"
                                    return "#3B82F6"
                                }
                                opacity: 0.9
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: backend.setWallpaper(modelData.path)
                            }
                        }
                        Text {
                            text: modelData.name
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            Text {
                text: "Wallpapers apply to the desktop immediately. Your own images go in ~/.local/share/ix1/wallpapers."
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                Layout.fillWidth: true
                wrapMode: Text.Wrap
            }
        }
    }
}
