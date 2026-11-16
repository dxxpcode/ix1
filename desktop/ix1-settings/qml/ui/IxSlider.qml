import QtQuick
import Ix1Settings 1.0

// Thin track, accent fill, white knob with a hairline ring and soft shadow.
Item {
    id: slider
    property real from: 0
    property real to: 100
    property real value: 0
    signal moved(real value)

    implicitHeight: 28
    readonly property real frac: Math.max(0, Math.min(1, (value - from) / (to - from)))

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        x: 9
        width: parent.width - 18
        height: 4
        radius: 2
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0.05, 0.07, 0.12, 0.10)

        Rectangle {
            width: track.width * slider.frac
            height: parent.height
            radius: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.darker(Theme.accent, 1.25) }
                GradientStop { position: 1.0; color: Theme.accent }
            }
        }
    }

    Rectangle {
        x: track.x + track.width * slider.frac - width / 2
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 1
        width: 20
        height: 20
        radius: 10
        color: Qt.rgba(0, 0, 0, Theme.dark ? 0.35 : 0.12)
    }
    Rectangle {
        id: knob
        x: track.x + track.width * slider.frac - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        radius: 9
        color: "#FFFFFF"
        border.width: 1
        border.color: Qt.rgba(0.05, 0.07, 0.12, 0.14)
        scale: drag.pressed ? 1.1 : 1
        Behavior on scale { NumberAnimation { duration: 100 } }
    }

    MouseArea {
        id: drag
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function update(mx) {
            const f = Math.max(0, Math.min(1, (mx - track.x) / track.width))
            slider.value = slider.from + f * (slider.to - slider.from)
            slider.moved(slider.value)
        }
        onPressed: (m) => update(m.x)
        onPositionChanged: (m) => { if (pressed) update(m.x) }
    }
}
