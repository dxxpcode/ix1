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
    readonly property color danger: dark ? "#F87171" : "#DC2626"

    readonly property string fontFamily: "Inter"
    readonly property int radius: 12
}
