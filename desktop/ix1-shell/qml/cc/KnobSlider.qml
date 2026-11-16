import QtQuick
import Ix1Shell 1.0

// Classic slider row — icon at the left, thin track with accent fill and
// a white knob, % readout at the right, inside its own rounded card.
Item {
    id: root
    property string glyph: "volume-2"
    property real value: 0
    property real min: 0
    property real max: 100
    property bool available: value >= 0
    property string readout: available ? Math.round(value) + "%" : "—"
    property color fillColor: "#4A90D9"
    signal moved(real v)

    opacity: available ? 1 : 0.5

    Rectangle {
        anchors.fill: parent
        radius: 14
        color: Theme.surface2
        border.color: Theme.hairline
        border.width: 1
    }

    Glyph {
        id: ic
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 18
        height: 18
        name: root.glyph
        color: Theme.textSecondary
    }

    Item {
        id: trackZone
        anchors.left: ic.right
        anchors.leftMargin: 12
        anchors.right: pct.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        height: 22

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: 5
            radius: 2.5
            color: Theme.surface3
        }
        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: knob.x + knob.width / 2
            height: 5
            radius: 2.5
            color: root.fillColor
        }
        Rectangle {
            id: knob
            x: Math.max(0, Math.min(parent.width - width,
                        parent.width * (root.value - root.min)
                        / (root.max - root.min) - width / 2))
            anchors.verticalCenter: parent.verticalCenter
            width: 15
            height: 15
            radius: 7.5
            color: "#FFFFFF"
        }
    }

    Text {
        id: pct
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.readout
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 12
        horizontalAlignment: Text.AlignRight
        width: 34
    }

    MouseArea {
        anchors.fill: trackZone
        anchors.margins: -10
        enabled: root.available
        cursorShape: Qt.PointingHandCursor
        onPressed: function(mouse) { apply(mouse.x) }
        onPositionChanged: function(mouse) { if (pressed) apply(mouse.x) }
        function apply(x) {
            const f = Math.max(0, Math.min(1, x / trackZone.width))
            root.moved(Math.round(root.min + f * (root.max - root.min)))
        }
    }
}
