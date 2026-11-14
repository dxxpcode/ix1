import QtQuick
import Ix1Installer

// Landing-page display type: Geist Medium, -0.02em tracking, with the
// site's white→zinc-500 vertical fade mapped over the line box — pure
// white through the midpoint, ~55% black at the bottom edge so the
// baseline lands near luminance ~155, matching the live site's rendered
// curve. flatColor switches to a solid tint (deploy error state).
Item {
    id: root
    property alias text: glyph.text
    property int pixelSize: 54
    property real letterSpacing: -0.02 * pixelSize
    property bool gradient: true
    property color flatColor: Theme.textPrimary

    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    Text {
        id: glyph
        color: root.gradient ? "#fafafa" : root.flatColor
        font.family: Theme.fontSans
        font.pixelSize: root.pixelSize
        font.weight: Font.Medium
        font.letterSpacing: root.letterSpacing
        renderType: Text.NativeRendering
    }
    Rectangle {
        visible: root.gradient
        anchors.fill: parent
        // bg-gradient-to-b from-white via-white to-zinc-500 over the line
        // box (which extends below the glyph baseline, like the site's).
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.5;  color: "transparent" }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.548) }
        }
    }
}
