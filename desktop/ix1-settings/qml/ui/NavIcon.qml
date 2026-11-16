import QtQuick
import QtQuick.Shapes

// Sidebar glyph: a tinted gradient tile with a white vector glyph (16×16
// path space). Up to three paths; each is either stroked or filled.
Item {
    id: icon
    property color tint: "#3B82F6"
    property var paths: []          // [{ d: "...", fill: bool }]
    width: 24
    height: 24

    Rectangle {
        anchors.fill: parent
        radius: 7
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(icon.tint, 1.28) }
            GradientStop { position: 1.0; color: Qt.darker(icon.tint, 1.08) }
        }
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.16)
    }
    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width - 10
        height: 1
        color: Qt.rgba(1, 1, 1, 0.35)
    }

    Shape {
        anchors.centerIn: parent
        width: 16
        height: 16
        scale: 0.95
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            readonly property var p: icon.paths.length > 0 ? icon.paths[0] : null
            strokeColor: p && !p.fill ? "#FFFFFF" : "transparent"
            fillColor: p && p.fill ? "#FFFFFF" : "transparent"
            strokeWidth: 1.6
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.paths.length > 0 ? icon.paths[0].d : "" }
        }
        ShapePath {
            readonly property var p: icon.paths.length > 1 ? icon.paths[1] : null
            strokeColor: p && !p.fill ? "#FFFFFF" : "transparent"
            fillColor: p && p.fill ? "#FFFFFF" : "transparent"
            strokeWidth: 1.6
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.paths.length > 1 ? icon.paths[1].d : "" }
        }
        ShapePath {
            readonly property var p: icon.paths.length > 2 ? icon.paths[2] : null
            strokeColor: p && !p.fill ? "#FFFFFF" : "transparent"
            fillColor: p && p.fill ? "#FFFFFF" : "transparent"
            strokeWidth: 1.6
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.paths.length > 2 ? icon.paths[2].d : "" }
        }
    }
}
