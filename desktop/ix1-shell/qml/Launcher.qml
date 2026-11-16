import QtQuick
import QtQuick.Window
import QtQuick.Shapes
import org.kde.layershell as LayerShellQt
import Ix1Shell 1.0

Window {
    id: root
    visible: backend.launcherOpen
    color: "transparent"

    LayerShellQt.Window.layer: LayerShellQt.Window.LayerOverlay
    LayerShellQt.Window.anchors: LayerShellQt.Window.AnchorTop
        | LayerShellQt.Window.AnchorBottom
        | LayerShellQt.Window.AnchorLeft
        | LayerShellQt.Window.AnchorRight
    LayerShellQt.Window.keyboardInteractivity: LayerShellQt.Window.KeyboardInteractivityExclusive
    // Anchors size the window under the layer shell; set it explicitly so
    // offscreen (headless render) grabs work too.
    width: 1920
    height: 1080

    Component.onCompleted: {
        Theme.mode = backend.theme
        if (visible) reset()
    }
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    readonly property int columns: 6
    readonly property var groupOrder: ["Internet", "Productivity", "Development", "Media",
                                       "Games", "Utilities", "System", "Other"]

    property string query: ""
    property string category: "All"
    // Highlight: 0..recentShown.length-1 is the Recent row, then the grid.
    property int sel: 0
    property int selStyle: 1

    readonly property var groups: {
        const present = {}
        for (const a of backend.launcherApps) present[a.group] = true
        return ["All"].concat(groupOrder.filter(g => present[g]))
    }

    readonly property var results: {
        const q = query.trim().toLowerCase()
        let list = backend.launcherApps.filter(a => category === "All" || a.group === category)
        if (q.length === 0) return list
        const hay = a => (a.name + " " + a.group + " "
                          + a.desktopFile.split("/").pop().replace(".desktop", "")).toLowerCase()
        list = list.filter(a => hay(a).indexOf(q) >= 0)
        // Name-prefix matches first, then the rest, each alphabetical.
        return list.filter(a => a.name.toLowerCase().indexOf(q) === 0)
            .concat(list.filter(a => a.name.toLowerCase().indexOf(q) !== 0))
    }

    readonly property var recentShown: query.length === 0 && category === "All"
        ? backend.recentApps.slice(0, columns) : []
    readonly property int total: recentShown.length + results.length

    function reset() {
        searchInput.text = ""
        category = "All"
        sel = 0
        searchInput.forceActiveFocus()
        if (typeof demoLaunch !== "undefined" && demoLaunch.length > 0) {
            for (const part of demoLaunch.split(",")) {
                const kv = part.split(":")
                if (kv[0] === "q") searchInput.text = kv[1]
                else if (kv[0] === "cat") category = kv[1]
                else if (kv[0] === "sel") sel = parseInt(kv[1])
                else if (kv[0] === "v") selStyle = parseInt(kv[1])
            }
        }
    }

    function selectedApp() {
        if (sel < 0 || sel >= total) return null
        return sel < recentShown.length ? recentShown[sel] : results[sel - recentShown.length]
    }

    function launch(app) {
        if (!app) return
        backend.launchApp(app.desktopFile)
        backend.closeLauncher()
    }

    function move(dx, dy) {
        const nR = recentShown.length
        const nG = results.length
        if (total === 0) return
        if (sel < nR) {
            if (dx !== 0) sel = Math.max(0, Math.min(nR - 1, sel + dx))
            else if (dy > 0 && nG > 0) sel = nR + Math.min(sel, nG - 1)
            return
        }
        const g = sel - nR
        if (dx !== 0) {
            sel = nR + Math.max(0, Math.min(nG - 1, g + dx))
        } else if (dy > 0) {
            if (g + columns < nG) sel = nR + g + columns
            else if (Math.floor(g / columns) < Math.floor((nG - 1) / columns)) sel = nR + nG - 1
        } else if (dy < 0) {
            if (g - columns >= 0) sel = nR + g - columns
            else if (nR > 0) sel = Math.min(g % columns, nR - 1)
        }
    }

    function cycleCategory(step) {
        const i = groups.indexOf(category)
        category = groups[(i + step + groups.length) % groups.length]
    }

    onQueryChanged: sel = 0
    onCategoryChanged: { sel = 0; scroller.contentY = 0 }

    onVisibleChanged: {
        if (visible) {
            reset()
            enterAnim.restart()
        }
    }

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: dimmer; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: card; property: "opacity"; from: 0; to: 1; duration: 180 }
        NumberAnimation { target: card; property: "scale"; from: 0.96; to: 1; duration: 240; easing.type: Easing.OutCubic }
    }

    Rectangle {
        id: dimmer
        anchors.fill: parent
        color: Theme.dark ? Qt.rgba(0.01, 0.02, 0.05, 0.50) : Qt.rgba(0.08, 0.12, 0.2, 0.22)

        MouseArea {
            anchors.fill: parent
            onClicked: backend.closeLauncher()
        }
    }

    // Soft shadow under the card.
    Rectangle {
        anchors.fill: card
        anchors.topMargin: 18
        anchors.margins: -8
        radius: card.radius + 8
        color: Qt.rgba(0, 0, 0, Theme.dark ? 0.30 : 0.12)
        opacity: card.opacity
        scale: card.scale
    }

    Rectangle {
        id: card
        transformOrigin: Item.Center
        anchors.centerIn: parent
        width: 764
        height: 568
        radius: 24
        // Navy glass, same palette as the dock and Control Center.
        gradient: Gradient {
            GradientStop { position: 0.0; color: Theme.dark ? Qt.rgba(0.13, 0.19, 0.33, 0.74) : Qt.rgba(0.97, 0.98, 1, 0.84) }
            GradientStop { position: 1.0; color: Theme.dark ? Qt.rgba(0.06, 0.09, 0.17, 0.84) : Qt.rgba(0.91, 0.94, 0.99, 0.80) }
        }
        border.width: 1
        border.color: Theme.dark ? Qt.rgba(0.75, 0.85, 1, 0.16) : Qt.rgba(1, 1, 1, 0.85)

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 2 * parent.radius
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.dark ? Qt.rgba(0.8, 0.88, 1, 0.28) : "#FFFFFF" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        MouseArea { anchors.fill: parent; onClicked: searchInput.forceActiveFocus() }

        // ---- Search ----------------------------------------------------
        Rectangle {
            id: search
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 22
            height: 48
            radius: 14
            color: Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.75)
            border.width: 1
            border.color: searchInput.activeFocus
                ? (Theme.dark ? Qt.rgba(0.75, 0.85, 1, 0.30) : Qt.rgba(0.2, 0.39, 0.91, 0.35))
                : Theme.hairline

            Shape {
                id: lens
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                width: 18
                height: 18
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.textSecondary
                    strokeWidth: 1.8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc { centerX: 7.8; centerY: 7.8; radiusX: 6; radiusY: 6; startAngle: 0; sweepAngle: 360 }
                }
                ShapePath {
                    strokeColor: Theme.textSecondary
                    strokeWidth: 1.8
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    startX: 12.3; startY: 12.3
                    PathLine { x: 16.4; y: 16.4 }
                }
            }

            TextInput {
                id: searchInput
                anchors.left: lens.right
                anchors.leftMargin: 12
                anchors.right: escCap.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.textPrimary
                selectionColor: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35)
                font.family: Theme.fontFamily
                font.pixelSize: 16
                clip: true
                onTextChanged: {
                    // A new search starts across every app; Tab narrows it after.
                    if (text.length > 0 && root.query.length === 0) root.category = "All"
                    root.query = text
                }

                Keys.onPressed: (e) => {
                    switch (e.key) {
                    case Qt.Key_Left: root.move(-1, 0); break
                    case Qt.Key_Right: root.move(1, 0); break
                    case Qt.Key_Up: root.move(0, -1); break
                    case Qt.Key_Down: root.move(0, 1); break
                    case Qt.Key_Tab: root.cycleCategory(1); break
                    case Qt.Key_Backtab: root.cycleCategory(-1); break
                    case Qt.Key_Return:
                    case Qt.Key_Enter: root.launch(root.selectedApp()); break
                    case Qt.Key_Escape:
                        if (text.length > 0) text = ""
                        else backend.closeLauncher()
                        break
                    default: return
                    }
                    e.accepted = true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text.length === 0
                    text: "Search apps"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 16
                }
            }

            KeyCap {
                id: escCap
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                label: "esc"
            }
        }

        // ---- Category pills -----------------------------------------------
        Row {
            id: pills
            anchors.top: search.bottom
            anchors.topMargin: 14
            anchors.left: parent.left
            anchors.leftMargin: 22
            spacing: 4

            Repeater {
                model: root.groups
                delegate: Rectangle {
                    readonly property bool current: modelData === root.category
                    width: pillText.implicitWidth + 24
                    height: 30
                    radius: 9
                    color: current ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(1, 1, 1, 0.9))
                         : pillArea.containsMouse ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.5))
                         : "transparent"
                    border.width: current ? 1 : 0
                    border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0.05, 0.07, 0.12, 0.08)
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        id: pillText
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -1
                        text: modelData
                        color: current ? Theme.textPrimary : Theme.textSecondary
                        font.family: Theme.fontFamily
                        font.pixelSize: 12
                    }
                    Rectangle {
                        visible: current
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 14
                        height: 2
                        radius: 1
                        color: Theme.accent
                    }
                    MouseArea {
                        id: pillArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.category = modelData
                            searchInput.forceActiveFocus()
                        }
                    }
                }
            }
        }

        Rectangle {
            id: rule
            anchors.top: pills.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            height: 1
            color: Theme.hairline
        }

        // ---- Results -------------------------------------------------------
        Flickable {
            id: scroller
            anchors.top: rule.bottom
            anchors.bottom: footer.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            clip: true
            contentHeight: content.height + 8
            boundsBehavior: Flickable.StopAtBounds

            function ensureVisible(item) {
                const y = item.mapToItem(content, 0, 0).y
                if (y < contentY) contentY = Math.max(0, y - 30)
                else if (y + item.height > contentY + height)
                    contentY = Math.min(contentHeight - height, y + item.height - height + 8)
            }

            Column {
                id: content
                width: scroller.width
                topPadding: 10

                SectionHeader {
                    visible: root.recentShown.length > 0
                    title: "Recent"
                }
                Row {
                    visible: root.recentShown.length > 0
                    Repeater {
                        model: root.recentShown
                        delegate: AppTile {
                            app: modelData
                            selected: root.sel === index
                            onHovered: root.sel = index
                            onActivated: root.launch(modelData)
                        }
                    }
                }

                SectionHeader {
                    title: root.query.length > 0 ? "Results"
                         : root.category === "All" ? "All apps" : root.category
                    detail: root.results.length + (root.results.length === 1 ? " app" : " apps")
                }
                Grid {
                    columns: root.columns
                    Repeater {
                        model: root.results
                        delegate: AppTile {
                            app: modelData
                            selected: root.sel === root.recentShown.length + index
                            onHovered: root.sel = root.recentShown.length + index
                            onActivated: root.launch(modelData)
                        }
                    }
                }

                Item {
                    visible: root.results.length === 0
                    width: parent.width
                    height: 160
                    Column {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "No apps match “" + root.query + "”"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.category !== "All"
                            text: "Searching in " + root.category + " — Tab to change category"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }

        // ---- Footer hints --------------------------------------------------
        Rectangle {
            id: footer
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 42
            radius: card.radius
            color: "transparent"

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                height: 1
                color: Theme.hairline
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                spacing: 18
                Repeater {
                    model: [{ k: "↑↓←→", t: "Navigate" }, { k: "⏎", t: "Open" }, { k: "tab", t: "Category" }]
                    delegate: Row {
                        spacing: 7
                        KeyCap { label: modelData.k; anchors.verticalCenter: parent.verticalCenter }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.t
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                }
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 24
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedApp() ? root.selectedApp().name : ""
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }
    }

    component KeyCap: Rectangle {
        property string label
        width: Math.max(22, capText.implicitWidth + 12)
        height: 20
        radius: 6
        color: Theme.dark ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.8)
        border.width: 1
        border.color: Theme.hairline
        Text {
            id: capText
            anchors.centerIn: parent
            text: parent.label
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 10
        }
    }

    component SectionHeader: Item {
        property string title
        property string detail
        width: parent ? parent.width : 0
        height: 30
        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: parent.title
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 11
            font.letterSpacing: 0.6
            font.capitalization: Font.AllUppercase
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            visible: parent.detail.length > 0
            text: parent.detail
            color: Theme.textSecondary
            opacity: 0.7
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }
    }

    component AppTile: Item {
        id: tile
        property var app
        property bool selected: false
        signal hovered()
        signal activated()
        width: scroller.width / root.columns
        height: 112

        onSelectedChanged: if (selected) scroller.ensureVisible(tile)

        // Hover: a faint wash only.
        Rectangle {
            anchors.centerIn: parent
            width: parent.width - 10
            height: parent.height - 8
            radius: 18
            visible: !tile.selected
            color: tileArea.containsMouse ? (Theme.dark ? Qt.rgba(1, 1, 1, 0.04) : Qt.rgba(1, 1, 1, 0.40))
                                          : "transparent"
        }

        // Selected: a lifted glass tile, lit from above, with the app's own
        // colour glowing under the icon and a short accent bar.
        Item {
            id: plate
            anchors.centerIn: parent
            width: parent.width - 10
            height: parent.height - 8
            opacity: tile.selected ? 1 : 0
            scale: tile.selected ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            // Variant 1 — a whisper of fill with a crisp accent ring.
            Rectangle {
                visible: root.selStyle === 1
                anchors.fill: parent
                radius: 18
                color: Theme.dark ? Qt.rgba(1, 1, 1, 0.05) : Qt.rgba(1, 1, 1, 0.55)
                border.width: 1
                border.color: Theme.dark ? Qt.rgba(0.55, 0.75, 1, 0.75) : Qt.rgba(0.2, 0.39, 0.91, 0.55)
            }

            // Variant 2 — a deep accent-tinted plate.
            Rectangle {
                visible: root.selStyle === 2
                anchors.fill: parent
                anchors.topMargin: 3
                anchors.margins: -1
                radius: 19
                color: Qt.rgba(0, 0, 0, Theme.dark ? 0.22 : 0.06)
            }
            Rectangle {
                visible: root.selStyle === 2
                anchors.fill: parent
                radius: 18
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.dark ? Qt.rgba(0.44, 0.58, 0.93, 0.42) : Qt.rgba(0.7, 0.78, 0.96, 0.95) }
                    GradientStop { position: 1.0; color: Theme.dark ? Qt.rgba(0.33, 0.45, 0.78, 0.34) : Qt.rgba(0.6, 0.7, 0.93, 0.9) }
                }
                border.width: 1
                border.color: Theme.dark ? Qt.rgba(0.75, 0.85, 1, 0.45) : Qt.rgba(0.2, 0.39, 0.91, 0.3)
            }
            Rectangle {
                visible: root.selStyle === 2
                anchors.top: parent.top
                anchors.topMargin: 1
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 28
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.5; color: Theme.dark ? Qt.rgba(0.9, 0.94, 1, 0.8) : "#FFFFFF" }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Variant 3 — no plate: the icon floats over its own glow with an
            // accent underline.
            Shape {
                visible: root.selStyle === 3
                anchors.horizontalCenter: parent.horizontalCenter
                y: 4
                width: 96
                height: 80
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: "transparent"
                    fillGradient: RadialGradient {
                        centerX: 48; centerY: 42; centerRadius: 46
                        focalX: 48; focalY: 42
                        GradientStop { position: 0.0; color: Qt.alpha(tileIcon.tint, Theme.dark ? 0.5 : 0.28) }
                        GradientStop { position: 1.0; color: Qt.alpha(tileIcon.tint, 0) }
                    }
                    PathAngleArc { centerX: 48; centerY: 42; radiusX: 46; radiusY: 38; startAngle: 0; sweepAngle: 360 }
                }
            }
            Rectangle {
                visible: root.selStyle === 3
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 5
                anchors.horizontalCenter: parent.horizontalCenter
                width: 18
                height: 3
                radius: 1.5
                color: Theme.dark ? "#74F8FD" : Theme.accent
            }
        }

        AppIcon {
            id: tileIcon
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: tile.selected ? 11 : 14
            width: 56
            height: 56
            desktopFileName: tile.app ? tile.app.desktopFile : ""
            appTitle: tile.app ? tile.app.name : ""
            scale: tileArea.pressed ? 0.92 : tile.selected ? 1.06 : 1
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutBack } }
            Behavior on anchors.topMargin { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        Text {
            anchors.top: tileIcon.bottom
            anchors.topMargin: tile.selected ? 11 : 9
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 16
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tile.app ? tile.app.name : ""
            color: tile.selected
                 ? (root.selStyle === 1 ? Theme.accent : Theme.textPrimary)
                 : Qt.rgba(Theme.textPrimary.r, Theme.textPrimary.g, Theme.textPrimary.b, 0.78)
            font.family: Theme.fontFamily
            font.pixelSize: 12
            font.weight: tile.selected ? Font.DemiBold : Font.Normal
            Behavior on anchors.topMargin { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        MouseArea {
            id: tileArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: tile.hovered()
            onClicked: tile.activated()
        }
    }
}
