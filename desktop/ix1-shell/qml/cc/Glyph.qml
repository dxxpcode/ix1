import QtQuick

// One parameterized drawn icon — every glyph in the Control Center kit.
// Set `name` to pick the drawing; `color` tints strokes/fills.
// `strength` (0-100) only affects the "wifi" glyph's tiered arcs.
Canvas {
    id: root
    property string name: ""
    property color color: "#FFFFFF"
    property color dimColor: "transparent"
    property real strength: 100

    onNameChanged: requestPaint()
    onColorChanged: requestPaint()
    onDimColorChanged: requestPaint()
    onStrengthChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        const c = root.color
        const dim = root.dimColor !== "transparent" ? root.dimColor
                  : Qt.rgba(c.r, c.g, c.b, 0.35)
        ctx.strokeStyle = c
        ctx.fillStyle = c
        ctx.lineWidth = 1.4
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        const cx = w / 2, cy = h / 2

        if (name === "wifi") {
            const base = h * 0.80
            for (let i = 0; i < 3; ++i) {
                ctx.strokeStyle = root.strength > 25 * (i + 1) ? c : dim
                ctx.beginPath()
                ctx.arc(cx, base, w * (0.20 + i * 0.16), -Math.PI * 0.78, -Math.PI * 0.22)
                ctx.stroke()
            }
            ctx.fillStyle = root.strength >= 0 ? c : dim
            ctx.beginPath()
            ctx.arc(cx, base, 1.1, 0, Math.PI * 2)
            ctx.fill()
        } else if (name === "crescent") {
            ctx.beginPath()
            ctx.arc(cx - 1.5, cy, h * 0.38, 0, Math.PI * 2)
            ctx.fill()
            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath()
            ctx.arc(cx + 1.8, cy - 2.2, h * 0.32, 0, Math.PI * 2)
            ctx.fill()
        } else if (name === "gear") {
            ctx.beginPath()
            ctx.arc(cx, cy, h * 0.21, 0, Math.PI * 2)
            ctx.stroke()
            for (let i = 0; i < 8; ++i) {
                const a = i * Math.PI / 4
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * h * 0.33, cy + Math.sin(a) * h * 0.33)
                ctx.lineTo(cx + Math.cos(a) * h * 0.43, cy + Math.sin(a) * h * 0.43)
                ctx.stroke()
            }
        } else if (name === "sun") {
            ctx.beginPath()
            ctx.arc(cx, cy, h * 0.21, 0, Math.PI * 2)
            ctx.fill()
            for (let i = 0; i < 8; ++i) {
                const a = i * Math.PI / 4
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * h * 0.34, cy + Math.sin(a) * h * 0.34)
                ctx.lineTo(cx + Math.cos(a) * h * 0.46, cy + Math.sin(a) * h * 0.46)
                ctx.stroke()
            }
        } else if (name === "speaker") {
            ctx.beginPath()
            ctx.moveTo(w * 0.06, h * 0.36)
            ctx.lineTo(w * 0.25, h * 0.36)
            ctx.lineTo(w * 0.47, h * 0.11)
            ctx.lineTo(w * 0.47, h * 0.89)
            ctx.lineTo(w * 0.25, h * 0.64)
            ctx.lineTo(w * 0.06, h * 0.64)
            ctx.closePath()
            ctx.fill()
            if (root.strength > 0) {
                ctx.beginPath()
                ctx.arc(w * 0.52, cy, h * 0.21, -Math.PI * 0.35, Math.PI * 0.35)
                ctx.stroke()
            }
            if (root.strength > 60) {
                ctx.beginPath()
                ctx.arc(w * 0.52, cy, h * 0.38, -Math.PI * 0.35, Math.PI * 0.35)
                ctx.stroke()
            }
        } else if (name === "lock") {
            ctx.beginPath()
            ctx.arc(cx, h * 0.42, h * 0.21, Math.PI, 0)
            ctx.stroke()
            ctx.beginPath()
            ctx.rect(w * 0.26, h * 0.42, w * 0.48, h * 0.44)
            ctx.fill()
        } else if (name === "moon") {
            ctx.beginPath()
            ctx.arc(cx, cy, h * 0.34, 0, Math.PI * 2)
            ctx.fill()
            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath()
            ctx.arc(cx + h * 0.19, cy - h * 0.16, h * 0.29, 0, Math.PI * 2)
            ctx.fill()
        } else if (name === "reboot") {
            ctx.beginPath()
            ctx.arc(cx, cy, h * 0.31, -Math.PI * 0.3, Math.PI * 1.35)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(cx + h * 0.23, cy - h * 0.35)
            ctx.lineTo(cx + h * 0.34, cy - h * 0.21)
            ctx.lineTo(cx + h * 0.17, cy - h * 0.17)
            ctx.closePath()
            ctx.fill()
        } else if (name === "power") {
            ctx.beginPath()
            ctx.arc(cx, cy + h * 0.06, h * 0.30, -Math.PI * 0.38, Math.PI * 1.38)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(cx, cy - h * 0.38)
            ctx.lineTo(cx, cy - h * 0.06)
            ctx.stroke()
        } else if (name === "chevron") {
            ctx.beginPath()
            ctx.moveTo(w * 0.38, h * 0.22)
            ctx.lineTo(w * 0.62, h * 0.5)
            ctx.lineTo(w * 0.38, h * 0.78)
            ctx.stroke()
        } else if (name === "padlock") {
            ctx.beginPath()
            ctx.arc(cx, h * 0.40, h * 0.19, Math.PI, 0)
            ctx.stroke()
            ctx.beginPath()
            ctx.rect(w * 0.28, h * 0.40, w * 0.44, h * 0.42)
            ctx.fill()
        } else if (name === "check") {
            ctx.lineWidth = 1.6
            ctx.beginPath()
            ctx.moveTo(w * 0.15, h * 0.52)
            ctx.lineTo(w * 0.42, h * 0.78)
            ctx.lineTo(w * 0.86, h * 0.20)
            ctx.stroke()
        } else if (name === "send") {
            ctx.beginPath()
            ctx.moveTo(w * 0.15, h * 0.5)
            ctx.lineTo(w * 0.85, h * 0.5)
            ctx.stroke()
            ctx.beginPath()
            ctx.moveTo(w * 0.62, h * 0.30)
            ctx.lineTo(w * 0.85, h * 0.5)
            ctx.lineTo(w * 0.62, h * 0.70)
            ctx.stroke()
        }
    }
}
