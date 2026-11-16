import QtQuick
import QtQuick.Shapes
import Ix1Shell 1.0

// Vector icon drawn on a 24-unit grid, tinted to `color` at any size.
// Each part is [svgPath, mode]: 0 stroke, 1 fill, 2 fill + stroke,
// 3 even-odd fill.
Item {
    id: root
    property string name: ""
    property color color: CcStyle.text
    property real weight: 2

    implicitWidth: 20
    implicitHeight: 20

    function circle(cx, cy, r) {
        return "M" + (cx - r) + " " + cy + "a" + r + " " + r + " 0 1 0 " + (2 * r) + " 0"
             + "a" + r + " " + r + " 0 1 0 " + (-2 * r) + " 0z"
    }
    readonly property string _lockBody:
        "M6.7 10.5h10.6a2.2 2.2 0 0 1 2.2 2.2v6.1a2.2 2.2 0 0 1-2.2 2.2H6.7"
        + "a2.2 2.2 0 0 1-2.2-2.2v-6.1a2.2 2.2 0 0 1 2.2-2.2z"
    readonly property string _speaker:
        "M11 4.8 6.6 8.6H3.8a.8.8 0 0 0-.8.8v5.2a.8.8 0 0 0 .8.8h2.8l4.4 3.8z"
    readonly property string _rays:
        "M12 2.5v1.8M12 19.7v1.8M2.5 12h1.8M19.7 12h1.8M5.3 5.3l1.3 1.3"
        + "M17.4 17.4l1.3 1.3M5.3 18.7l1.3-1.3M17.4 6.6l1.3-1.3"

    readonly property var _icons: ({
        "wifi": [["M1.8 8.8a14.8 14.8 0 0 1 20.4 0", 0], ["M5.1 12.3a10.1 10.1 0 0 1 13.8 0", 0],
                 ["M8.4 15.7a5.3 5.3 0 0 1 7.2 0", 0], [circle(12, 19.5, 1.7), 1]],
        "bluetooth": [["M6.5 7.2 17 17.1l-5 4.4V2.5l5 4.4L6.5 16.8", 0]],
        "moon": [["M20.4 14.6A8.6 8.6 0 0 1 9.4 3.6a.6.6 0 0 0-.8-.7A9.6 9.6 0 1 0 21.1 15.4a.6.6 0 0 0-.7-.8z", 1]],
        "sun": [[circle(12, 12, 4.2), 0],
                ["M12 2.3v2M12 19.7v2M2.3 12h2M19.7 12h2M5.1 5.1l1.4 1.4M17.5 17.5l1.4 1.4M5.1 18.9l1.4-1.4M17.5 6.5l1.4-1.4", 0]],
        "brightness": [[circle(12, 12, 4.3), 2], [_rays, 0]],
        "volume": [[_speaker, 2], ["M15.4 8.8a4.6 4.6 0 0 1 0 6.4", 0], ["M18.4 5.9a8.8 8.8 0 0 1 0 12.2", 0]],
        "volume-off": [[_speaker, 2], ["M16 9.5l5 5M21 9.5l-5 5", 0]],
        "headphones": [["M3.5 18v-5.5a8.5 8.5 0 0 1 17 0V18", 0],
                       ["M20.5 15.5v2a2.5 2.5 0 0 1-2.5 2.5h-.5a1.5 1.5 0 0 1-1.5-1.5v-4a1.5 1.5 0 0 1 1.5-1.5h3z", 0],
                       ["M3.5 15.5v2A2.5 2.5 0 0 0 6 20h.5A1.5 1.5 0 0 0 8 18.5v-4A1.5 1.5 0 0 0 6.5 13h-3z", 0]],
        "lock": [[_lockBody, 0], ["M8 10.5V7.5a4 4 0 0 1 8 0v3", 0]],
        "lock-fill": [[_lockBody, 2], ["M8 10.5V7.5a4 4 0 0 1 8 0v3", 0]],
        "restart": [["M4 12a8 8 0 1 0 2.6-5.9", 0], ["M4 4v4.5h4.5", 0]],
        "power": [["M12 2.8v8.4", 0], ["M17.7 6.4a8.2 8.2 0 1 1-11.4 0", 0]],
        "sliders": [["M3 6h9.6M17.4 6H21M3 12h3.6M11.4 12H21M3 18h11.6M19.4 18H21", 0],
                    [circle(15, 6, 2.4), 0], [circle(9, 12, 2.4), 0], [circle(17, 18, 2.4), 0]],
        "gear": [["M19.14 12.94c.04-.3.06-.61.06-.94s-.02-.64-.07-.94l2.03-1.58c.18-.14.23-.41.12-.61"
                  + "l-1.92-3.32c-.12-.22-.37-.29-.59-.22l-2.39.96c-.5-.38-1.03-.7-1.62-.94l-.36-2.54"
                  + "c-.04-.24-.24-.41-.48-.41h-3.84c-.24 0-.43.17-.47.41l-.36 2.54c-.59.24-1.13.57-1.62.94"
                  + "l-2.39-.96c-.22-.08-.47 0-.59.22l-1.92 3.32c-.11.2-.07.47.12.61l2.03 1.58c-.05.3-.09.63-.09.94"
                  + "s.02.64.07.94l-2.03 1.58c-.18.14-.23.41-.12.61l1.92 3.32c.12.22.37.29.59.22l2.39-.96"
                  + "c.5.38 1.03.7 1.62.94l.36 2.54c.05.24.24.41.48.41h3.84c.24 0 .44-.17.47-.41l.36-2.54"
                  + "c.59-.24 1.13-.56 1.62-.94l2.39.96c.22.08.47 0 .59-.22l1.92-3.32c.12-.22.07-.47-.12-.61z"
                  + "M12 15.6a3.6 3.6 0 1 1 0-7.2 3.6 3.6 0 0 1 0 7.2z", 3]],
        "chevron-right": [["M9 5.5l6.5 6.5L9 18.5", 0]],
        "chevron-down": [["M5.5 9l6.5 6.5L18.5 9", 0]],
        "check": [["M4.5 12.5l5 5 10-11", 0]],
    })

    readonly property real _k: Math.min(width, height) / 24

    readonly property var _parts: _icons[name] || []

    component Part: ShapePath {
        property int index: 0
        readonly property var part: root._parts[index] || ["", 1]
        readonly property bool stroked: part[1] === 0 || part[1] === 2
        scale: Qt.size(root._k, root._k)
        strokeColor: stroked ? root.color : "transparent"
        strokeWidth: stroked ? root.weight : -1
        fillColor: part[1] === 0 ? "transparent" : root.color
        fillRule: part[1] === 3 ? ShapePath.OddEvenFill : ShapePath.WindingFill
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: part[0] }
    }

    Shape {
        anchors.centerIn: parent
        width: 24 * root._k
        height: 24 * root._k
        preferredRendererType: Shape.CurveRenderer
        Part { index: 0 }
        Part { index: 1 }
        Part { index: 2 }
        Part { index: 3 }
    }
}
