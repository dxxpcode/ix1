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
    // 50px headroom for the tooltip / pin menu, the dock, 55px of floor
    // for the reflection.
    height: 181
    // Anchors size the window under the layer shell; set it explicitly so
    // offscreen (headless render) grabs show the dock too.
    width: 1920

    // Applied by main.cpp. Only the dock (and an open pin menu) takes
    // clicks; KWin blurs behind the dock's rounded card.
    readonly property rect inputRect: {
        const top = menu.visible ? menu.y : dock.y
        return Qt.rect(dock.x, top, dock.width, dock.y + dock.height + 14 - top)
    }
    readonly property rect blurRect: Qt.rect(dock.x, dock.y, dock.width, dock.height)
    readonly property real blurRadius: dock.radius

    // Hovered cell (drives the tooltip) and the cell whose pin menu is open.
    property Item hoverCell: null
    property Item menuCell: null

    function cellCenterX(cell) {
        return cell.mapToItem(root.contentItem, cell.width / 2, 0).x
    }
    function clampToDock(x, w) {
        return Math.max(dock.x, Math.min(dock.x + dock.width - w, x))
    }

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    Timer {
        id: tipDelay
        interval: 450
        onTriggered: tip.shown = root.hoverCell !== null
    }
    onHoverCellChanged: {
        tip.shown = false
        if (hoverCell) {
            tip.cell = hoverCell
            tipDelay.restart()
        } else {
            tipDelay.stop()
        }
        if (menuCell && hoverCell && hoverCell !== menuCell) {
            menuCell = null
        }
    }

    Rectangle {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 55
        width: dockRow.implicitWidth + 20
        height: dockRow.implicitHeight + 20
        radius: 22
        // Translucent navy glass (sampled from the concept): the wallpaper
        // shows through, lighter at the top, with a lit bottom rim.
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.dark ? Qt.rgba(0.17, 0.26, 0.44, 0.40) : Qt.rgba(0.93, 0.96, 1, 0.40) }
            GradientStop { position: 1.0; color: Theme.dark ? Qt.rgba(0.07, 0.12, 0.22, 0.52) : Qt.rgba(0.84, 0.89, 0.98, 0.36) }
        }
        border.color: Theme.dark ? Qt.rgba(0.75, 0.85, 1, 0.17) : Qt.rgba(1, 1, 1, 0.75)
        border.width: 1

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 2 * parent.radius
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.dark ? Qt.rgba(0.7, 0.8, 1, 0.32) : Qt.rgba(0.05, 0.07, 0.12, 0.10) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        HoverHandler { id: dockHover }

        Row {
            id: dockRow
            anchors.centerIn: parent
            spacing: 6

            Repeater {
                model: backend.dockApps

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property string label: modelData.name
                    readonly property string appId: modelData.appId
                    readonly property bool pinned: modelData.pinned
                    readonly property bool hovered: area.containsMouse
                        || (demoDock !== "" && index === 1)

                    // KWin reports open app ids to the backend; bind to the
                    // property so this re-evaluates when the open set changes.
                    readonly property bool running:
                        backend.runningApps.map(function (id) {
                            return id.toLowerCase()
                        }).indexOf(appId.toLowerCase()) >= 0

                    width: 56
                    height: 56

                    Component.onCompleted: {
                        if (demoDock !== "" && index === 1) {
                            if (demoDock === "menu") {
                                root.menuCell = cell
                            } else {
                                root.hoverCell = cell
                                tip.shown = true
                            }
                        }
                    }

                    // Soft coloured reflection pooled on the "floor" under the
                    // dock; brighter under running apps.
                    Shape {
                        id: pool
                        readonly property real w: 76
                        readonly property real a: (Theme.dark ? 1 : 0.55) * (cell.running ? 1.25 : 0.8)
                        width: w
                        height: w
                        x: (parent.width - w) / 2
                        y: parent.height + 11
                        transform: Scale { yScale: 0.72 }
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
                        visible: cell.running
                        readonly property real w: 56
                        width: w
                        height: w
                        x: (parent.width - w) / 2
                        y: parent.height + 11
                        transform: Scale { yScale: 0.55 }
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

                    // Hover lifts the icon slightly; press squeezes it.
                    AppIcon {
                        id: icon
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: cell.hovered && !area.pressed ? -2 : 0
                        width: 44
                        height: 44
                        desktopFileName: cell.modelData.desktopFile
                        appTitle: cell.label
                        transformOrigin: Item.Bottom
                        scale: area.pressed ? 0.9 : (cell.hovered ? 1.06 : 1)
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    }

                    Item {
                        visible: cell.running
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
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        onContainsMouseChanged: {
                            if (containsMouse) {
                                root.hoverCell = cell
                            } else if (root.hoverCell === cell) {
                                root.hoverCell = null
                            }
                        }
                        onClicked: function (mouse) {
                            if (mouse.button === Qt.RightButton) {
                                root.menuCell = root.menuCell === cell ? null : cell
                                tip.shown = false
                                return
                            }
                            root.menuCell = null
                            backend.launchApp(cell.modelData.desktopFile)
                        }
                    }
                }
            }

            // Divider + app launcher, as in the concept.
            Item {
                width: 13
                height: 56
                Rectangle {
                    anchors.centerIn: parent
                    width: 1
                    height: 36
                    color: Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0.05, 0.07, 0.12, 0.14)
                }
            }

            Item {
                id: launcherCell
                readonly property string label: "Apps"
                readonly property bool hovered: launcherArea.containsMouse
                width: 56
                height: 56

                Grid {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: launcherCell.hovered && !launcherArea.pressed ? -2 : 0
                    columns: 3
                    spacing: 5
                    transformOrigin: Item.Bottom
                    scale: launcherArea.pressed ? 0.9 : (launcherCell.hovered ? 1.06 : 1)
                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                    Repeater {
                        model: 9
                        Rectangle {
                            width: 6
                            height: 6
                            radius: 3
                            color: Theme.dark ? "#E6EAF2" : "#3A4252"
                        }
                    }
                }

                MouseArea {
                    id: launcherArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: {
                        if (containsMouse) {
                            root.hoverCell = launcherCell
                        } else if (root.hoverCell === launcherCell) {
                            root.hoverCell = null
                        }
                    }
                    onClicked: {
                        root.menuCell = null
                        backend.toggleLauncher()
                    }
                }
            }
        }
    }

    // App-name tooltip above the hovered icon: a small glass label in the
    // dock's palette, with a soft shadow and a notch pointing at the icon.
    Item {
        id: tip
        property bool shown: false
        property Item cell: null
        readonly property bool active: shown && cell !== null && root.menuCell === null
        readonly property color fillTop: Theme.dark
            ? Qt.rgba(0.15, 0.20, 0.32, 0.92) : Qt.rgba(1, 1, 1, 0.94)
        readonly property color fillBottom: Theme.dark
            ? Qt.rgba(0.09, 0.12, 0.21, 0.94) : Qt.rgba(0.95, 0.97, 1, 0.96)
        readonly property color rim: Theme.dark
            ? Qt.rgba(0.75, 0.85, 1, 0.16) : Qt.rgba(0.05, 0.08, 0.16, 0.10)
        readonly property real notchX: cell
            ? Math.max(14, Math.min(width - 14, root.cellCenterX(cell) - x)) : width / 2

        visible: opacity > 0
        opacity: active ? 1 : 0
        scale: active ? 1 : 0.94
        transformOrigin: Item.Bottom
        Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
        width: tipText.implicitWidth + 28
        height: 30
        x: cell ? root.clampToDock(root.cellCenterX(cell) - width / 2, width) : 0
        y: dock.y - height - 14

        // Soft drop shadow (stacked, so it also renders on the software scenegraph).
        Repeater {
            model: 5
            Rectangle {
                required property int index
                anchors.fill: label
                anchors.leftMargin: -(index + 1)
                anchors.rightMargin: -(index + 1)
                anchors.topMargin: 2
                anchors.bottomMargin: -(index + 1) * 1.6
                radius: label.radius + index + 1
                color: Qt.rgba(0, 0, 0.05, Theme.dark ? 0.07 : 0.022)
            }
        }

        Rectangle {
            id: label
            anchors.fill: parent
            radius: 10
            gradient: Gradient {
                GradientStop { position: 0.0; color: tip.fillTop }
                GradientStop { position: 1.0; color: tip.fillBottom }
            }
            border.color: tip.rim
            border.width: 1

            // Lit top edge.
            Rectangle {
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 2 * parent.radius
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop {
                        position: 0.5
                        color: Theme.dark ? Qt.rgba(0.8, 0.88, 1, 0.28) : Qt.rgba(1, 1, 1, 1)
                    }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        // Notch pointing down at the icon; its fill overlaps the label's
        // bottom border so the two read as one shape.
        Shape {
            x: tip.notchX - 6
            y: tip.height - 1.5
            width: 12
            height: 7
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: tip.fillBottom
                strokeColor: tip.rim
                strokeWidth: 1
                startX: 0; startY: 0
                PathLine { x: 6; y: 6 }
                PathLine { x: 12; y: 0 }
            }
            ShapePath {
                fillColor: "transparent"
                strokeColor: tip.fillBottom
                strokeWidth: 2
                startX: 1; startY: 0.5
                PathLine { x: 11; y: 0.5 }
            }
        }

        Text {
            id: tipText
            anchors.centerIn: label
            anchors.verticalCenterOffset: -0.5
            text: tip.cell ? tip.cell.label : ""
            color: Theme.dark ? Qt.rgba(0.94, 0.96, 1, 1) : Qt.rgba(0.07, 0.09, 0.14, 1)
            font.family: Theme.fontFamily
            font.pixelSize: 13
            font.letterSpacing: 0.1
        }
    }

    // Right-click pin menu.
    Rectangle {
        id: menu
        visible: root.menuCell !== null
        readonly property bool pinned: root.menuCell ? root.menuCell.pinned : false
        width: menuText.implicitWidth + 28
        height: 32
        radius: 10
        x: root.menuCell ? root.clampToDock(root.cellCenterX(root.menuCell) - width / 2, width) : 0
        y: dock.y - height - 8
        color: Theme.dark ? Qt.rgba(0.08, 0.09, 0.12, 0.96) : Qt.rgba(1, 1, 1, 0.98)
        border.color: Theme.hairline
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 3
            radius: 7
            color: menuArea.containsMouse ? Theme.glassHover : "transparent"
        }
        Text {
            id: menuText
            anchors.centerIn: parent
            text: menu.pinned ? "Remove from Dock" : "Keep in Dock"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }
        MouseArea {
            id: menuArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                const c = root.menuCell
                root.menuCell = null
                backend.setPinned(c.appId, !c.pinned)
            }
        }
    }

    // Close the pin menu once the pointer has left both dock and menu.
    Timer {
        running: root.menuCell !== null && demoDock === ""
            && !dockHover.hovered && !menuArea.containsMouse
        interval: 900
        onTriggered: root.menuCell = null
    }
}
