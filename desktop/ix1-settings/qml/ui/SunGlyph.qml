import QtQuick
import QtQuick.Shapes
import Ix1Settings 1.0

// Brightness sun: core disc + eight rays, in the secondary ink.
Shape {
    id: sun
    property real size: 14
    width: size
    height: size
    preferredRendererType: Shape.CurveRenderer
    readonly property real c: size / 2
    readonly property real core: size * 0.2
    readonly property real r0: size * 0.34
    readonly property real r1: size * 0.48
    readonly property color ink: Theme.textSecondary

    ShapePath {
        fillColor: sun.ink
        strokeColor: "transparent"
        PathAngleArc { centerX: sun.c; centerY: sun.c; radiusX: sun.core; radiusY: sun.core; startAngle: 0; sweepAngle: 360 }
    }
    ShapePath {
        fillColor: "transparent"
        strokeColor: sun.ink
        strokeWidth: Math.max(1.2, sun.size / 11)
        capStyle: ShapePath.RoundCap
        PathSvg {
            path: {
                let d = ""
                for (let i = 0; i < 8; ++i) {
                    const a = i * Math.PI / 4
                    d += "M" + (sun.c + Math.cos(a) * sun.r0) + " " + (sun.c + Math.sin(a) * sun.r0)
                       + "L" + (sun.c + Math.cos(a) * sun.r1) + " " + (sun.c + Math.sin(a) * sun.r1)
                }
                return d
            }
        }
    }
}
