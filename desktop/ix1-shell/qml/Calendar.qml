import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

// Clock popover: live time with seconds + a month calendar, centered
// beneath the panel's clock. Same overlay pattern as QuickSettings.
Window {
    id: root
    visible: backend.calendarOpen
    color: "transparent"
    width: 1920
    height: 1080

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: backend.closeCalendar()
    }

    property var now: new Date()
    property int monthOffset: 0
    onVisibleChanged: { if (visible) monthOffset = 0 }

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    function monthStart() {
        const d = new Date(root.now)
        d.setDate(1)
        d.setMonth(d.getMonth() + root.monthOffset)
        return d
    }

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeCalendar()
        }

        Rectangle {
            id: card
            anchors.top: parent.top
            anchors.topMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            width: 264
            height: contentCol.implicitHeight + 28
            radius: Theme.radius
            color: Theme.glass
            border.color: Theme.hairline
            border.width: 1

            Component.onCompleted: enterAnim.restart()
            onVisibleChanged: { if (visible) enterAnim.restart() }

            ParallelAnimation {
                id: enterAnim
                NumberAnimation {
                    target: card
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 140
                }
                NumberAnimation {
                    target: card
                    property: "anchors.topMargin"
                    from: 30
                    to: 40
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea { anchors.fill: parent; onClicked: {} }

            Column {
                id: contentCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 14
                spacing: 10

                // Live time — seconds live here, not in the bar.
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(root.now, "HH:mm:ss")
                    color: Theme.textPrimary
                    font.family: Theme.fontFamily
                    font.pixelSize: 24
                    font.weight: Font.Medium
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(root.now, "dddd, MMMM d")
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Theme.hairline
                }

                // Month header + navigation.
                Item {
                    width: parent.width
                    height: 22

                    Text {
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(root.monthStart(), "MMMM yyyy")
                        color: Theme.textPrimary
                        font.family: Theme.fontFamily
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "‹"
                        color: prevArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 16
                        MouseArea {
                            id: prevArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthOffset -= 1
                        }
                    }
                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "›"
                        color: nextArea.containsMouse ? Theme.textPrimary : Theme.textSecondary
                        font.pixelSize: 16
                        MouseArea {
                            id: nextArea
                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.monthOffset += 1
                        }
                    }
                }

                // Weekday initials.
                Grid {
                    width: parent.width
                    columns: 7

                    Repeater {
                        model: ["S", "M", "T", "W", "T", "F", "S"]
                        delegate: Text {
                            required property string modelData
                            width: (264 - 28) / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }
                    }
                }

                // Day grid: blanks pad the first week to the weekday.
                Grid {
                    width: parent.width
                    columns: 7

                    Repeater {
                        model: {
                            const start = root.monthStart()
                            const year = start.getFullYear()
                            const month = start.getMonth()
                            const firstWeekday = start.getDay()
                            const days = new Date(year, month + 1, 0).getDate()
                            const cells = []
                            for (let i = 0; i < firstWeekday; ++i) cells.push(0)
                            for (let d = 1; d <= days; ++d) cells.push(d)
                            return cells
                        }
                        delegate: Item {
                            required property int modelData
                            width: (264 - 28) / 7
                            height: 26

                            property bool today: {
                                const t = root.now
                                const m = root.monthStart()
                                return modelData > 0
                                    && t.getDate() === modelData
                                    && t.getMonth() === m.getMonth()
                                    && t.getFullYear() === m.getFullYear()
                            }

                            Rectangle {
                                visible: parent.today
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                radius: width / 2
                                color: Theme.accent
                            }
                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData > 0 ? parent.modelData : ""
                                color: parent.today ? "#FFFFFF" : Theme.textPrimary
                                font.family: Theme.fontFamily
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
}
