pragma Singleton
import QtQuick

// Design tokens — verbatim from website/src/index.css (.dark) so the
// installer reads as a sibling of the landing page.
QtObject {
    readonly property color background: "#000000"
    readonly property color foreground: "#fafafa"
    readonly property color card: "#09090b"
    readonly property color cardHover: "#0d0d0f"
    readonly property color secondary: "#27272a"
    readonly property color muted: "#1a1a1a"
    readonly property color mutedFg: "#888888"
    readonly property color dim: "#52525b"
    readonly property color border: "#1f1f1f"
    readonly property color borderHover: "#2e2e33"
    readonly property color input: "#1f1f1f"
    readonly property color ring: "#d4d4d8"
    readonly property color amber: "#fbbf24"
    readonly property color danger: "#ef4444"
    readonly property color dangerFg: "#fafafa"
    readonly property color buttonFg: "#18181b"

    // Aliases kept for readability at call sites.
    readonly property color textPrimary: foreground
    readonly property color textSecondary: mutedFg
    readonly property color textMuted: mutedFg
    readonly property color textDim: dim
    readonly property color bg: background

    readonly property string fontSans: "Geist"
    readonly property string fontMono: "Geist Mono"

    readonly property int radiusMd: 6    // buttons, inputs  (rounded-md)
    readonly property int radiusXl: 12   // cards            (rounded-xl)
}
