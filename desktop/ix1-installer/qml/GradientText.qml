import QtQuick
import Ix1Installer

// Landing-page display type, measured on www.dxxp.codes: flat #fafafa in
// Geist Medium (500) with -0.02em tracking — no gradient. flatColor only
// overrides the tint (e.g. the deploy error state).
Item {
    id: root
    property alias text: glyph.text
    property int pixelSize: 54
    property real letterSpacing: -0.02 * pixelSize
    property color flatColor: Theme.textPrimary

    implicitWidth: glyph.implicitWidth
    implicitHeight: glyph.implicitHeight

    Text {
        id: glyph
        color: root.flatColor
        font.family: Theme.fontSans
        font.pixelSize: root.pixelSize
        font.weight: Font.Medium
        font.letterSpacing: root.letterSpacing
        renderType: Text.NativeRendering
    }
}
