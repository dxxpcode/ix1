import QtQuick

// Drawn Lucide-style check — a stroked path, not a text glyph.
// `progress` runs 0→1 to animate the draw-in (~300ms OutCubic
// via the Behavior below); set `animate` false to render complete.
Canvas {
    id: check

    property real progress: 0
    property color checkColor: Theme.success
    property real strokeWidth: 2
    property bool animate: true

    width: 14
    height: 14

    Component.onCompleted: if (!animate) progress = 1
    Behavior on progress { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    onProgressChanged: requestPaint()
    onCheckColorChanged: requestPaint()
    onStrokeWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)
        const p = Math.min(Math.max(progress, 0), 1)
        if (p <= 0) return
        const w = width, h = height
        // Lucide "check": M4 12.5 L9.5 18 L20 6.5, normalized.
        const ax = 0.17 * w, ay = 0.54 * h
        const bx = 0.42 * w, by = 0.75 * h
        const cx = 0.83 * w, cy = 0.27 * h
        const total = Math.hypot(bx - ax, by - ay) + Math.hypot(cx - bx, cy - by)
        ctx.strokeStyle = checkColor
        ctx.lineWidth = strokeWidth
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.setLineDash([total * p, total * 2])
        ctx.beginPath()
        ctx.moveTo(ax, ay)
        ctx.lineTo(bx, by)
        ctx.lineTo(cx, cy)
        ctx.stroke()
    }
}
