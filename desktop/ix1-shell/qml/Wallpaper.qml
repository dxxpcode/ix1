import QtQuick
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: true
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerBackground
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bgBase
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl(Theme.dark
            ? "assets/wallpaper-graphite.png"
            : "assets/wallpaper-porcelain.png")
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: true
    }
}
