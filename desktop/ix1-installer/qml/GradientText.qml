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
    }
    Rectangle {
        visible: root.gradient
        anchors.fill: parent
        // The site's headline reads mostly white — its two-line h1 keeps the
        // whole first line pure white and only the last ~third fades toward
        // zinc-500. Same visual on one line: white until ~60%, gentle dim to
        // the baseline.
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.62; color: "transparent" }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.48) }
        }
    }
}
