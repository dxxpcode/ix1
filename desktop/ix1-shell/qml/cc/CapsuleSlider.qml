import QtQuick
import Ix1Shell 1.0

// iOS-style fill slider — the capsule IS the control. The accent fill
// carries the glyph; the % readout lives at the track's right edge so it
// stays visible even when the fill is a sliver.
Item {
    id: root
    property string glyph: "speaker"
    property real value: 0      // current, in [min, max]
    property real min: 0
    property real max: 100
    property bool available: value >= 0
    property string readout: available ? Math.round(value) + "%" : "N/A"
    property color fillColor: Theme.dark
        ? Qt.darker(Theme.accent, 1.35) : Theme.accent
    property color fillColorHot: Theme.dark
        ? Qt.darker(Theme.accent, 1.5) : Qt.darker(Theme.accent, 1.12)
    signal moved(real v)

    opacity: available ? 1 : 0.45

    Squircle {
        id: track
        anchors.fill: parent
        n: 9
        color: Theme.surface3
    }
    Item {
        id: fillClip
        width: Math.max(36, track.width * Math.max(0, root.value - root.min)
                        / (root.max - root.min))
        height: parent.height
        clip: true

        Squircle {
            width: track.width
            height: parent.height
            n: 9
            color: area.pressed ? root.fillColorHot : root.fillColor
        }
        Glyph {
            anchors.left: parent.left
            anchors.leftMargin: 13
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 15
            name: root.glyph
            color: "#FFFFFF"
            strength: root.value
        }
    }
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        text: root.readout
        color: root.available
               && track.width * Math.max(0, root.value - root.min) / (root.max - root.min)
                  > track.width - 52 ? "#FFFFFF" : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.available
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: function(mouse) { apply(mouse.x) }
        onPositionChanged: function(mouse) { if (pressed) apply(mouse.x) }
        function apply(x) {
            const f = Math.max(0, Math.min(1, x / track.width))
            root.moved(Math.round(root.min + f * (root.max - root.min)))
        }
    }
}
