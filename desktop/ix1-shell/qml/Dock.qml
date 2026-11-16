import QtQuick
import QtQuick.Shapes
import QtQuick.Window
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: true
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerTop
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    height: 120
    // Anchors size the window under the layer shell; set it explicitly so
    // offscreen (headless render) grabs show the dock too.
    width: 1920

    // Input region (applied by main.cpp): only the dock itself takes
    // clicks; the transparent strip and the reflection pass them through.
    readonly property rect inputRect:
        Qt.rect(dock.x, 0, dock.width, dock.y + dock.height + 14)

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Rectangle {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
        width: dockRow.implicitWidth + 20
        height: dockRow.implicitHeight + 20
        radius: Theme.radiusLarge
        color: Theme.glass
        border.color: Theme.hairline
        border.width: 1

        // Dock-wide pointer x for magnification. Icon buttons are on top of
        // this tracker, so each forwards its own hover position here.
        MouseArea {
            id: dockTrack
            anchors.fill: parent
            anchors.bottomMargin: -14
            hoverEnabled: true
            property real hoverX: -1
            onPositionChanged: function (mouse) { hoverX = mouse.x }
            onExited: hoverX = -1
        }

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: backend.apps

                delegate: Rectangle {
                    required property string name
                    required property string desktopFile
                    required property int index

                    // Taskbar-style running indicator (KWin reports the
                    // open app ids to the backend over the session bus).
                    // Bind to the runningApps property so it re-evaluates
                    // when the open set changes — an isRunning() call
                    // would not subscribe to runningAppsChanged.
                    readonly property string appId:
                        desktopFile.replace(/^.*\//, "")
                                   .replace(/\.desktop$/, "")
                                   .toLowerCase()
                    readonly property bool running:
                        backend.runningApps.map(function (id) {
                            return id.toLowerCase()
                        }).indexOf(appId) >= 0

                    readonly property real centerX: dockRow.x + x + width / 2
                    readonly property real mag: {
                        if (dockTrack.hoverX < 0) return 1.0
                        const d = Math.abs(dockTrack.hoverX - centerX)
                        return 1 + 0.35 * Math.max(0, 1 - d / 120)
                    }

                    width: 56
                    height: 56
                    radius: 16
                    scale: mag * (dockButtonArea.pressed ? 0.9 : 1)
                    transformOrigin: Item.Bottom
                    color: dockButtonArea.containsMouse ? Theme.glassHover : "transparent"

                    Behavior on scale {
                        NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
                    }

                    // Soft coloured reflection pooled on the "floor" under the
                    // dock; brighter under running apps.
                    Shape {
                        id: pool
                        readonly property real w: 76
                        readonly property real a: (Theme.dark ? 1 : 0.55) * (parent.running ? 1.25 : 0.8)
                        width: w
                        height: w
                        x: (parent.width - w) / 2
                        y: parent.height + 11
                        transform: Scale { yScale: 0.7 }
                        preferredRendererType: Shape.CurveRenderer
                        ShapePath {
                            strokeWidth: -1
                            fillGradient: RadialGradient {
                                centerX: pool.w / 2; centerY: 0
                                focalX: pool.w / 2; focalY: 0
                                centerRadius: pool.w / 2
                                GradientStop { position: 0.0; color: Qt.alpha(icon.tint, 0.55 * pool.a) }
                                GradientStop { position: 0.45; color: Qt.alpha(icon.tint, 0.2 * pool.a) }
                                GradientStop { position: 1.0; color: Qt.alpha(icon.tint, 0) }
                            }
                            PathRectangle { width: pool.w; height: pool.w }
                        }
                    }

                    Shape {
                        id: hot
                        visible: parent.running
                        readonly property real w: 56
                        width: w
                        height: w
                        x: (parent.width - w) / 2
                        y: parent.height + 11
                        transform: Scale { yScale: 0.5 }
                        ShapePath {
                            strokeWidth: -1
                            fillGradient: RadialGradient {
                                centerX: hot.w / 2; centerY: 0
                                focalX: hot.w / 2; focalY: 0
                                centerRadius: hot.w / 2
                                GradientStop { position: 0.0; color: Qt.alpha("#5AB8FF", Theme.dark ? 0.75 : 0.4) }
                                GradientStop { position: 1.0; color: Qt.alpha("#5AB8FF", 0) }
                            }
                            PathRectangle { width: hot.w; height: hot.w }
                        }
                    }

                    AppIcon {
                        id: icon
                        anchors.centerIn: parent
                        width: 44
                        height: 44
                        desktopFileName: desktopFile
                        appTitle: name
                    }

                    Item {
                        visible: parent.running
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: -1
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 18
                        height: 5

                        Shape {
                            id: halo
                            readonly property real w: 40
                            width: w
                            height: w
                            x: (parent.width - w) / 2
                            y: parent.height / 2 - w * 0.2
                            transform: Scale { yScale: 0.4 }
                            ShapePath {
                                strokeWidth: -1
                                fillGradient: RadialGradient {
                                    centerX: halo.w / 2; centerY: halo.w / 2
                                    focalX: halo.w / 2; focalY: halo.w / 2
                                    centerRadius: halo.w / 2
                                    GradientStop { position: 0.0; color: Qt.alpha("#74F8FD", 0.45) }
                                    GradientStop { position: 1.0; color: Qt.alpha("#74F8FD", 0) }
                                }
                                PathRectangle { width: halo.w; height: halo.w }
                            }
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: "#74F8FD"
                        }
                    }

                    MouseArea {
                        id: dockButtonArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: function (mouse) {
                            dockTrack.hoverX = centerX - width / 2 + mouse.x
                        }
                        onExited: dockTrack.hoverX = -1
                        onClicked: backend.launchApp(desktopFile)
                    }
                }
            }
        }
    }
}
