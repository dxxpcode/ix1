import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ix1Onboarding

Item {
    id: networkPage
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    property string password: ""
    readonly property var selNet: backend.selectedNetwork >= 0
        && backend.selectedNetwork < backend.networks.length
        ? backend.networks[backend.selectedNetwork] : null
    // selNet is a fresh QVariantMap on every refresh — key clearing on
    // the ssid itself so a rescan never silently drops a typed password.
    readonly property string selSsid: selNet !== null ? selNet.ssid : ""
    // The password row appears for a secured, not-yet-connected selection.
    readonly property bool wantsPassword:
        selNet !== null && selNet.secured && !selNet.active

    function clearPassword() {
        password = ""
        pwField.text = ""
    }
    onWantsPasswordChanged: if (!wantsPassword) clearPassword()
    onSelSsidChanged: clearPassword()

    Repeater {
        model: 9
        Shortcut {
            sequence: (index + 1).toString()
            onActivated: if (index < backend.networks.length)
                backend.selectedNetwork = index
        }
    }
    // Rescan on entry, light refresh while the page is up.
    onVisibleChanged: if (visible) backend.rescan()
    Timer {
        interval: 5000
        repeat: true
        running: networkPage.visible
        onTriggered: backend.refresh()
    }

    Flickable {
        id: fl
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: col.implicitHeight + col.y

        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            onWheel: fl.contentY = Math.max(0, Math.min(
                         fl.contentHeight - fl.height,
                         fl.contentY - event.angleDelta.y))
        }

        ColumnLayout {
            id: col
            x: Math.max(0, (fl.width - width) / 2)
            y: Math.max(24, fl.height * 0.14)
            width: 620
            spacing: 0

        RowLayout {
            spacing: 10
            Text {
                text: "step 02 — connect"
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 2.2
            }
            Item { Layout.fillWidth: true }
            Text {
                visible: backend.connectedSsid !== ""
                text: "online — " + backend.connectedSsid
                color: Theme.success
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 1.2
            }
        }
        GradientText {
            text: "Get online."
            pixelSize: 54
            Layout.topMargin: 16
        }
        Text {
            text: "Pick a network — or skip and set it up later from the desktop."
            color: Theme.textSecondary
            font.family: Theme.fontSans
            font.pixelSize: 15
            lineHeight: 1.6
            wrapMode: Text.Wrap
            Layout.fillWidth: true
            Layout.topMargin: 14
        }

        // Segmented network list — one bordered container, hairline dividers.
        Rectangle {
            Layout.topMargin: 34
            Layout.fillWidth: true
            height: Math.max(78, Math.min(backend.networks.length, 5) * 78 + pwCard.height)
            radius: 14
            color: Theme.card
            border.width: 1
            border.color: Theme.border

            Row {
                visible: backend.networks.length === 0
                anchors.centerIn: parent
                spacing: 10
                Canvas {
                    width: 16; height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        ctx.strokeStyle = "#a1a1aa"
                        ctx.lineWidth = 2
                        ctx.lineCap = "round"
                        ctx.beginPath()
                        ctx.arc(8, 8, 6, -Math.PI / 2, -Math.PI / 2 + Math.PI * 1.4)
                        ctx.stroke()
                    }
                    RotationAnimation on rotation {
                        running: backend.networks.length === 0
                        loops: Animation.Infinite
                        from: 0; to: 360; duration: 900
                    }
                }
                Text {
                    text: backend.scanning ? "scanning networks" : "no networks found"
                    color: Theme.textMuted
                    font.family: Theme.fontMono
                    font.pixelSize: 12
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Column {
                id: netCol
                width: parent.width

                Repeater {
                    model: backend.networks
                    delegate: Item {
                        id: row
                        width: netCol.width
                        height: 78

                        readonly property bool active: modelData.active
                        readonly property bool sel: index === backend.selectedNetwork
                        readonly property bool connecting:
                            backend.connectingSsid === modelData.ssid
                        property real appear: 0

                        opacity: appear
                        transform: Translate { y: (1 - row.appear) * 8 }

                        // Staggered entry — the list builds row by row.
                        SequentialAnimation {
                            running: true
                            PauseAnimation { duration: 60 + index * 45 }
                            NumberAnimation {
                                target: row; property: "appear"
                                to: 1; duration: 300; easing.type: Easing.OutCubic
                            }
                        }

                        // Selection cell — an elevated chip inside the segment.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 13
                            visible: row.sel
                            color: "#141416"
                            border.width: 1
                            border.color: "#38383e"
                        }
                        // Hairline divider between rows (hidden beside the
                        // selected row's cell).
                        Rectangle {
                            visible: index > 0 && !row.sel
                                     && index - 1 !== backend.selectedNetwork
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            height: 1
                            color: "#1c1c1f"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 18
                            anchors.rightMargin: 20
                            spacing: 14

                            // Wi-Fi glyph — arcs filled by signal strength.
                            Rectangle {
                                width: 34; height: 34; radius: 9
                                color: row.sel ? "#1d1d21" : "#0d0d0f"
                                border.width: 1
                                border.color: row.sel ? "#33333a" : "#232327"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 140 } }
                                Image {
                                    anchors.centerIn: parent
                                    width: 18; height: 18
                                    sourceSize.width: 36; sourceSize.height: 36
                                    source: "qrc:/Ix1Onboarding/assets/icons/wifi.svg"
                                    opacity: row.active ? 1
                                             : Math.max(0.35, modelData.signal / 100)
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 3
                                Text {
                                    text: modelData.ssid
                                    color: Theme.textPrimary
                                    font.family: Theme.fontSans
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                                Text {
                                    text: (modelData.secured ? "secured" : "open")
                                          + " · " + modelData.signal + "%"
                                          + (row.connecting ? " · connecting"
                                             : "")
                                    color: Theme.textMuted
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                }
                                // Signal hairline — the capacity-bar motif.
                                Rectangle {
                                    width: parent.width
                                    height: 2
                                    radius: 1
                                    color: "#1c1c1f"
                                    Rectangle {
                                        height: parent.height
                                        radius: 1
                                        width: Math.max(2, parent.width
                                                        * modelData.signal / 100)
                                        color: row.active ? Theme.success
                                               : row.sel ? "#a1a1aa" : "#3f3f46"
                                        Behavior on color { ColorAnimation { duration: 160 } }
                                    }
                                }
                            }
                            Rectangle {
                                width: tagTxt.implicitWidth + 14
                                height: 18
                                radius: 4
                                color: row.sel || row.active ? "#242429" : "transparent"
                                border.width: row.sel || row.active ? 0 : 1
                                border.color: "#26262a"
                                Text {
                                    id: tagTxt
                                    anchors.centerIn: parent
                                    text: row.active ? "connected"
                                          : row.connecting ? "joining"
                                          : "network"
                                    color: row.active ? Theme.success
                                          : row.sel ? Theme.textSecondary
                                          : Theme.textMuted
                                    font.family: Theme.fontMono
                                    font.pixelSize: 10
                                }
                            }

                            // Trailing check token — drawn emerald check,
                            // pops in on connect.
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                scale: row.active ? 1 : 0.4
                                opacity: row.active ? 1 : 0
                                color: Qt.rgba(16/255, 185/255, 129/255, 0.10)
                                border.width: 1
                                border.color: Qt.rgba(16/255, 185/255, 129/255, 0.35)
                                Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                                Behavior on opacity { NumberAnimation { duration: 140 } }
                                CheckMark {
                                    anchors.centerIn: parent
                                    width: 12; height: 12
                                    strokeWidth: 1.8
                                    progress: row.active ? 1 : 0
                                }
                            }
                        }
                        HoverHandler { id: netHover }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: backend.selectedNetwork = index
                        }
                        // Row hover tint behind content.
                        Rectangle {
                            z: -1
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: 13
                            color: netHover.hovered && !row.sel ? "#0d0d0f" : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }
                        }
                    }
                }
            }

            // Password card — slides open below the list when a secured,
            // unconnected network is selected. Same field language as the
            // login form.
            Rectangle {
                id: pwCard
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                height: wantsPassword ? 50 : 0
                clip: true
                radius: 10
                color: wantsPassword ? "#0e0e10" : "transparent"
                border.width: wantsPassword ? 1 : 0
                border.color: pwField.activeFocus ? Theme.textSecondary : "#27272a"
                Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on border.color { ColorAnimation { duration: 140 } }
                property bool reveal: false

                Image {
                    anchors.left: parent.left
                    anchors.leftMargin: 15
                    anchors.verticalCenter: pwField.verticalCenter
                    width: 16; height: 16
                    sourceSize.width: 36; sourceSize.height: 36
                    source: "qrc:/Ix1Onboarding/assets/icons/lock.svg"
                    opacity: pwField.activeFocus || pwField.text !== "" ? 1 : 0.5
                    Behavior on opacity { NumberAnimation { duration: 160 } }
                }
                TextInput {
                    id: pwField
                    anchors.left: parent.left
                    anchors.right: pwEye.left
                    anchors.leftMargin: 44
                    anchors.rightMargin: 6
                    height: 50
                    enabled: wantsPassword
                    verticalAlignment: Text.AlignVCenter
                    color: Theme.textPrimary
                    font.family: Theme.fontSans
                    font.pixelSize: 15
                    echoMode: pwCard.reveal ? TextInput.Normal : TextInput.Password
                    selectByMouse: true
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pwField.text === "" && !pwField.activeFocus
                        text: "network password"
                        color: Theme.textDim
                        font.family: Theme.fontSans
                        font.pixelSize: 15
                    }
                    onTextChanged: networkPage.password = text
                    onAccepted: backend.connectSelected(networkPage.password)
                }
                // Show/hide toggle.
                Rectangle {
                    id: pwEye
                    anchors.right: joinBtn.left
                    anchors.rightMargin: 2
                    anchors.verticalCenter: pwField.verticalCenter
                    width: 34; height: 34; radius: 8
                    color: pwEyeHover.hovered ? "#1b1b1f" : "transparent"
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Image {
                        anchors.centerIn: parent
                        width: 17; height: 17
                        sourceSize.width: 36; sourceSize.height: 36
                        source: "qrc:/Ix1Onboarding/assets/icons/eye"
                                + (pwCard.reveal ? "" : "-off") + ".svg"
                        opacity: pwEyeHover.hovered ? 1 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }
                    HoverHandler { id: pwEyeHover }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: pwCard.reveal = !pwCard.reveal
                    }
                }
                // Join affordance.
                Rectangle {
                    id: joinBtn
                    anchors.right: parent.right
                    anchors.rightMargin: 6
                    anchors.verticalCenter: pwField.verticalCenter
                    width: joinTxt.implicitWidth + 22
                    height: 36; radius: 8
                    color: joinHover.hovered ? "#f0f0f2" : "#e4e4e7"
                    scale: joinMouse.pressed ? 0.95 : 1.0
                    Behavior on scale { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                    Behavior on color { ColorAnimation { duration: 120 } }
                    Text {
                        id: joinTxt
                        anchors.centerIn: parent
                        text: "join →"
                        color: "#18181b"
                        font.family: Theme.fontSans
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                    HoverHandler { id: joinHover }
                    MouseArea {
                        id: joinMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: backend.connectSelected(networkPage.password)
                    }
                }
            }
        }

        // Connect error — the quiet amber line, same register as the
        // installer's warnings.
        Text {
            visible: backend.connectError !== ""
            text: backend.connectError
            color: Theme.amber
            font.family: Theme.fontMono
            font.pixelSize: 11
            Layout.topMargin: 14
        }
        }
    }
}
