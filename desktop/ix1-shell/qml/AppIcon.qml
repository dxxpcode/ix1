import QtQuick
import Ix1Shell 1.0

// Custom IX1 squircle-tile icon set, mapped from the app's desktop file name.
Image {
    id: root

    property string desktopFileName: ""
    property string appTitle: ""

    function iconName() {
        const hay = (root.desktopFileName + " " + root.appTitle).toLowerCase();
        if (hay.indexOf("software") >= 0 || hay.indexOf("store") >= 0) { return "store"; }
        if (hay.indexOf("settings") >= 0) { return "settings"; }
        if (hay.indexOf("konsole") >= 0 || hay.indexOf("terminal") >= 0) { return "terminal"; }
        if (hay.indexOf("dolphin") >= 0 || hay.indexOf("file") >= 0) { return "files"; }
        if (hay.indexOf("kate") >= 0 || hay.indexOf("editor") >= 0) { return "editor"; }
        if (hay.indexOf("systemmonitor") >= 0) { return "monitor"; }
        if (hay.indexOf("firefox") >= 0 || hay.indexOf("browser") >= 0) { return "browser"; }
        if (hay.indexOf("btop") >= 0) { return "pulse"; }
        if (hay.indexOf("htop") >= 0) { return "bars"; }
        return "grid";
    }

    source: Qt.resolvedUrl("assets/icons/tile-" + iconName() + ".svg")
    fillMode: Image.PreserveAspectFit
    smooth: true
    asynchronous: true
}
