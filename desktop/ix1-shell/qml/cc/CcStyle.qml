pragma Singleton
import QtQuick
import Ix1Shell 1.0

// Control Center palette, metrics and typeface (Noto Sans, bundled).
QtObject {
    readonly property bool dark: Theme.dark

    readonly property FontLoader _regular: FontLoader { source: "../assets/fonts/NotoSans-Regular.ttf" }
    readonly property FontLoader _medium: FontLoader { source: "../assets/fonts/NotoSans-Medium.ttf" }
    readonly property FontLoader _semibold: FontLoader { source: "../assets/fonts/NotoSans-SemiBold.ttf" }
    readonly property string font: _regular.status === FontLoader.Ready ? _regular.font.family : "Noto Sans"

    readonly property color card: dark ? "#121A2B" : "#F4F6FA"
    readonly property color cardBorder: dark ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0.06, 0.09, 0.16, 0.10)
    // Translucent navy glass (same palette as the dock): wallpaper shows
    // through, lighter at the top, KWin blurs behind the card.
    readonly property color cardGlassTop: dark ? Qt.rgba(0.13, 0.19, 0.33, 0.60)
                                               : Qt.rgba(0.96, 0.98, 1, 0.62)
    readonly property color cardGlassBottom: dark ? Qt.rgba(0.06, 0.09, 0.17, 0.70)
                                                  : Qt.rgba(0.90, 0.93, 0.99, 0.55)
    readonly property color cardGlassRim: dark ? Qt.rgba(0.75, 0.85, 1, 0.15)
                                               : Qt.rgba(1, 1, 1, 0.80)
    readonly property color cardGlassEdge: dark ? Qt.rgba(0.8, 0.88, 1, 0.26)
                                                : Qt.rgba(1, 1, 1, 1)
    readonly property color cardGlassRimBottom: dark ? Qt.rgba(0.7, 0.8, 1, 0.28)
                                                     : Qt.rgba(0.05, 0.07, 0.12, 0.12)
    readonly property color surface: dark ? "#232A3B" : "#FFFFFF"
    readonly property color surfaceHover: dark ? "#2A3245" : "#F9FAFC"
    readonly property color surfacePressed: dark ? "#303850" : "#EEF1F6"
    readonly property color surfaceBorder: dark ? Qt.rgba(1, 1, 1, 0.055) : Qt.rgba(0.06, 0.09, 0.16, 0.07)
    readonly property color circle: dark ? "#232A3B" : "#FFFFFF"
    readonly property color divider: dark ? Qt.rgba(1, 1, 1, 0.09) : Qt.rgba(0.06, 0.09, 0.16, 0.09)
    readonly property color rowHover: dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(0.06, 0.09, 0.16, 0.04)

    readonly property color accentStart: "#2F74FC"
    readonly property color accentEnd: "#418DFE"
    readonly property color accent: dark ? "#4A8EFC" : "#2F74FC"
    readonly property color track: dark ? "#333A4E" : "#DDE2EB"
    readonly property color knob: dark ? "#EEF2FD" : "#FFFFFF"

    readonly property color text: dark ? "#F4F6FB" : "#141A26"
    readonly property color textMuted: dark ? "#A2AABD" : "#667085"
    readonly property color textOnAccent: "#FFFFFF"
    readonly property color textOnAccentMuted: Qt.rgba(1, 1, 1, 0.74)

    readonly property int radius: 12
    readonly property int radiusCard: 20
}
