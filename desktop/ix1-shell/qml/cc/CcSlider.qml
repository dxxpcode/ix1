import QtQuick
import Ix1Shell 1.0

// Slider pane — leading icon, thin track with knob, trailing readout.
Item {
    id: root
    property string icon: "volume"
    property real value: 0
    property real min: 0
    property real max: 100
    property bool available: true
    property string readout: available ? Math.round(value) + "%" : "N/A"
    signal moved(real v)

    implicitHeight: 52

    readonly property real _f: available
        ? Math.max(0, Math.min(1, (value - min) / (max - min))) : 0

    Rectangle {
        anchors.fill: parent
        radius: CcStyle.radius
        color: CcStyle.surface
        border.width: 1
        border.color: CcStyle.surfaceBorder
    }

    CcIcon {
        x: 19
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        name: root.icon
        color: CcStyle.text
        opacity: root.available ? 1 : 0.45
    }

    Item {
        id: track
        anchors.left: parent.left
        anchors.leftMargin: 61
        anchors.right: parent.right
        anchors.rightMargin: 63
        anchors.verticalCenter: parent.verticalCenter
        height: 5
        opacity: root.available ? 1 : 0.45

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: CcStyle.track
        }
        Rectangle {
            height: parent.height
            width: Math.max(height, knob.x + knob.width / 2)
            radius: height / 2
            color: CcStyle.accent
        }
        Rectangle {
            x: knob.x
            y: knob.y + 1.5
            width: knob.width
            height: knob.height
            radius: width / 2
            color: Qt.rgba(0, 0, 0, CcStyle.dark ? 0.35 : 0.14)
            visible: root.available
        }
        Rectangle {
            id: knob
            visible: root.available
            width: drag.pressed ? 18 : 16
            height: width
            radius: width / 2
            x: root._f * track.width - width / 2
            anchors.verticalCenter: parent.verticalCenter
            color: CcStyle.knob
            border.width: CcStyle.dark ? 0 : 1
            border.color: Qt.rgba(0.06, 0.09, 0.16, 0.10)
            Behavior on width { NumberAnimation { duration: 90 } }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        text: root.readout
        color: root.available ? CcStyle.text : CcStyle.textMuted
        font.family: CcStyle.font
        font.pixelSize: 13
        horizontalAlignment: Text.AlignRight
    }

    MouseArea {
        id: drag
        enabled: root.available
        x: track.x - 10
        width: track.width + 20
        height: parent.height
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        function apply(mx, my) {
            const p = mapToItem(track, mx, my)
            const f = Math.max(0, Math.min(1, p.x / track.width))
            root.moved(Math.round(root.min + f * (root.max - root.min)))
        }
        onPressed: function(m) { apply(m.x, m.y) }
        onPositionChanged: function(m) { if (pressed) apply(m.x, m.y) }
    }
}
