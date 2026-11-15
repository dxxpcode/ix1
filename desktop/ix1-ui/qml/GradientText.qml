import QtQuick


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
    property bool shimmer: false   // loops the highlight sweep
    property bool sweep: false     // plays a single pass

    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    ShimmerText {
        id: glyph
        color: root.gradient ? "#fafafa" : root.flatColor
        fontFamily: Theme.fontSans
        fontPixelSize: root.pixelSize
        fontWeight: Font.Medium
        fontLetterSpacing: root.letterSpacing
        running: root.shimmer
        sweep: root.sweep
    }
    Rectangle {
        visible: root.gradient
        anchors.fill: glyph
        // bg-gradient-to-b from-white via-white to-zinc-500 over the line
        // box (which extends below the glyph baseline, like the site's).
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "transparent" }
            GradientStop { position: 0.5;  color: "transparent" }
            GradientStop { position: 1.0;  color: Qt.rgba(0, 0, 0, 0.548) }
        }
    }
}
