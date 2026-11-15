import QtQuick

// Tiered wi-fi glyph — three fan arcs over a base dot that fill up by
// signal strength, so a strong network and a weak one differ
// structurally, not just in opacity. Same stroke language as the
// line-icon set.
Canvas {
    id: glyph
    width: 18
    height: 18

    // 0-100. The dot is always lit; arcs come on at >25 / >50 / >75.
    property int signal: 100
    property color litColor: "#e4e4e7"
    property color unlitColor: "#33333a"

    onSignalChanged: requestPaint()
    onLitColorChanged: requestPaint()
    onUnlitColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const cx = width / 2
        const cy = height * 0.80
        ctx.lineCap = "round"
        ctx.lineWidth = Math.max(1.4, width * 0.10)

        const lit = [signal > 25, signal > 50, signal > 75]
        const radii = [width * 0.20, width * 0.36, width * 0.52]
        for (let i = 0; i < 3; ++i) {
            ctx.strokeStyle = lit[i] ? litColor : unlitColor
            ctx.beginPath()
            ctx.arc(cx, cy, radii[i], -Math.PI * 0.78, -Math.PI * 0.22)
            ctx.stroke()
        }

        ctx.fillStyle = signal > 0 ? litColor : unlitColor
        ctx.beginPath()
        ctx.arc(cx, cy, ctx.lineWidth * 0.62, 0, Math.PI * 2)
        ctx.fill()
    }
}
