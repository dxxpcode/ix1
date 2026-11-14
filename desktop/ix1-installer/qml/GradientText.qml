import QtQuick
import Ix1Installer

// Landing-page headline: white→zinc gradient. A translucent black overlay
// dims the glyphs toward zinc; the canvas is already black, so the overlay
// is invisible everywhere the text isn't — same visual as a masked gradient,
// and it renders under the software rasterizer.
Item {
    id: root
    property alias text: glyph.text
    property int pixelSize: 54
    property real letterSpacing: -2.5
    // Flat-color fallback (e.g. danger on the deploy error state).
    property bool gradient: true
    property color flatColor: Theme.textPrimary

    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    Text {
        id: glyph
        color: root.gradient ? "#fafafa" : root.flatColor
        font.family: Theme.fontSans
        font.pixelSize: root.pixelSize
        font.weight: Font.Bold
        font.letterSpacing: root.letterSpacing
        renderType: Text.NativeRendering
    }
    Rectangle {
        visible: root.gradient
        anchors.fill: parent
        // Faithful port of the site's headline gradient: the text element's
        // bg-gradient-to-b from-white via-white to-zinc-500 maps over the
        // whole line box (which, like the site's, extends below the glyph
        // baseline). Over a #fafafa glyph, dimming to zinc-500 (#71717a)
        // at the element's bottom edge is a black overlay at ~55% alpha.
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.5;  color: "transparent" }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.548) }
        }
    }
}
