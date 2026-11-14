pragma Singleton
import QtQuick

QtObject {
    property string mode: "graphite"
    readonly property bool dark: mode === "graphite"

    readonly property color bgBase: dark ? "#0E0F12" : "#F6F7F9"
    readonly property color surface1: dark ? "#17181C" : "#FFFFFF"
    readonly property color surface2: dark ? "#1D1F24" : "#ECEEF2"
    readonly property color surface3: dark ? "#24262B" : "#E2E5EA"
    readonly property color hairline: dark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0.05, 0.07, 0.12, 0.08)
    readonly property color textPrimary: dark ? "#F2F3F5" : "#16181D"
    readonly property color textSecondary: dark ? "#9BA1AB" : "#5B6472"
    readonly property color accent: dark ? "#8AB4FF" : "#3563E9"
    readonly property color accentSoft: dark ? Qt.rgba(0.54, 0.71, 1.0, 0.14)
                                             : Qt.rgba(0.21, 0.39, 0.91, 0.10)

    // Translucent chrome for panel/dock/launcher/quick settings.
    readonly property color glass: dark ? Qt.rgba(0.09, 0.094, 0.11, 0.66)
                                         : Qt.rgba(1, 1, 1, 0.66)
    readonly property color glassHover: dark ? Qt.rgba(0.14, 0.15, 0.18, 0.72)
                                             : Qt.rgba(0.92, 0.94, 0.97, 0.72)

    readonly property string fontFamily: "Inter"
    readonly property int radius: 12
    readonly property int radiusLarge: 16
}
