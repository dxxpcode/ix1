import QtQuick

// Superellipse ("squircle") fill — the macOS-style continuous corner curve
// a plain rounded rect only approximates. `n` is the exponent (~4.5 = iOS).
Canvas {
    id: root
    property color color: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real n: 4.5

    onColorChanged: requestPaint()
    onBorderColorChanged: requestPaint()
    onBorderWidthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        const a = w / 2, b = h / 2
        const n = root.n
        ctx.beginPath()
        const steps = 64
        for (let i = 0; i <= steps; ++i) {
            const t = (i / steps) * Math.PI * 2
            const c = Math.cos(t), s = Math.sin(t)
            const x = a + a * Math.sign(c) * Math.pow(Math.abs(c), 2 / n)
            const y = b + b * Math.sign(s) * Math.pow(Math.abs(s), 2 / n)
            if (i === 0) ctx.moveTo(x, y)
            else ctx.lineTo(x, y)
        }
        ctx.closePath()
        ctx.fillStyle = root.color
        ctx.fill()
        if (root.borderWidth > 0) {
            ctx.lineWidth = root.borderWidth
            ctx.strokeStyle = root.borderColor
            ctx.stroke()
        }
    }
}
