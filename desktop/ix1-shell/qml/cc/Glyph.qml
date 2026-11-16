import QtQuick

// Lucide icon. `name` maps to a bundled SVG in assets/icons-lucide/.
// The SVGs ship in two baked tints — white strokes for dark surfaces,
// slate for light — and the requested `color`'s luminance picks the
// variant; its luminance also fades the icon so dim text colors read dim.
Item {
    id: root
    property string name: ""
    property color color: "#FFFFFF"
    property real strength: 100

    readonly property real _lum: 0.2126 * color.r + 0.7152 * color.g + 0.0722 * color.b
    readonly property bool _light: _lum > 0.5

    Image {
        anchors.fill: parent
        source: (root._light ? "../assets/icons-lucide/" : "../assets/icons-lucide-dark/")
                + root.name + ".svg"
        sourceSize: Qt.size(96, 96)
        fillMode: Image.PreserveAspectFit
        smooth: true
        opacity: (root._light ? root._lum : 1.0) * root.color.a
    }
}
