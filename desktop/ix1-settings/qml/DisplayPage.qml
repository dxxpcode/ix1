import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

Flickable {
    id: page
    contentHeight: body.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true
    Component.onCompleted: backend.refreshDisplays()

    // "2560x1600@120" -> { w, h, hz }
    function parseMode(m) {
        const at = m.split("@")
        const wh = at[0].split("x")
        return { w: parseInt(wh[0]), h: parseInt(wh[1]), hz: at.length > 1 ? Math.round(parseFloat(at[1])) : 0 }
    }

    ColumnLayout {
        id: body
        width: page.width
        spacing: 14

        PageHeader {
            title: "Display"
            subtitle: "Resolution, refresh rate and scaling."
        }

        Text {
            visible: backend.displays.length === 0
            text: "No displays reported. Display settings need KScreen (kscreen-doctor)."
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            Layout.fillWidth: true
            wrapMode: Text.Wrap
        }

        Repeater {
            model: backend.displays
            delegate: ColumnLayout {
                id: out
                property var output: modelData
                readonly property var cur: page.parseMode(output.current)
                readonly property var resolutions: {
                    const seen = []
                    for (const m of output.modes) {
                        const p = page.parseMode(m)
                        const key = p.w + "x" + p.h
                        if (seen.indexOf(key) < 0) seen.push(key)
                    }
                    return seen
                }
                readonly property var rates: {
                    const r = []
                    for (const m of output.modes) {
                        const p = page.parseMode(m)
                        if (p.w === cur.w && p.h === cur.h && r.indexOf(p.hz) < 0) r.push(p.hz)
                    }
                    return r.sort((a, b) => b - a)
                }
                readonly property var scales: [1.0, 1.25, 1.5, 1.75, 2.0]
                readonly property string niceName: output.name.indexOf("eDP") === 0
                    ? "Built-in Display" : output.name

                function modeFor(res, hz) {
                    let best = ""
                    let bestHz = -1
                    for (const m of output.modes) {
                        const p = page.parseMode(m)
                        if (p.w + "x" + p.h !== res) continue
                        if (p.hz === hz) return m
                        if (p.hz > bestHz) { bestHz = p.hz; best = m }
                    }
                    return best
                }

                Layout.fillWidth: true
                spacing: 14

                // Monitor illustration with the live wallpaper and readout.
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 196
                    radius: 14
                    color: Theme.surface1
                    border.width: 1
                    border.color: Theme.hairline

                    Item {
                        id: monitor
                        anchors.left: parent.left
                        anchors.leftMargin: 34
                        anchors.verticalCenter: parent.verticalCenter
                        width: 224
                        height: 160

                        Rectangle {
                            id: bezel
                            width: parent.width
                            height: Math.round(width * out.cur.h / Math.max(1, out.cur.w)) + 12
                            radius: 10
                            color: Theme.dark ? "#0A0B0E" : "#2A2D34"
                            border.width: 1
                            border.color: Theme.dark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.2)
                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 6
                                radius: 5
                                clip: true
                                color: "#000"
                                Image {
                                    anchors.fill: parent
                                    source: "file://" + (backend.wallpaper.length > 0 ? backend.wallpaper
                                        : "/usr/share/ix1/wallpapers/" + (backend.theme === "porcelain" ? "porcelain" : "graphite") + ".png")
                                    sourceSize.width: 480
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }
                        }
                        Rectangle {
                            anchors.top: bezel.bottom
                            anchors.horizontalCenter: bezel.horizontalCenter
                            width: 44
                            height: 12
                            color: Theme.dark ? "#2A2D34" : "#B8BEC9"
                        }
                        Rectangle {
                            anchors.top: bezel.bottom
                            anchors.topMargin: 12
                            anchors.horizontalCenter: bezel.horizontalCenter
                            width: 86
                            height: 4
                            radius: 2
                            color: Theme.dark ? "#2A2D34" : "#B8BEC9"
                        }
                    }

                    Column {
                        anchors.left: monitor.right
                        anchors.leftMargin: 34
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        Text {
                            text: out.niceName
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 17
                            font.weight: Font.Medium
                        }
                        Text {
                            text: out.output.name
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                        Item { width: 1; height: 8 }
                        Text {
                            text: out.cur.w + " × " + out.cur.h + "  ·  " + out.cur.hz + " Hz"
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }
                        Text {
                            text: "Looks like " + Math.round(out.cur.w / out.output.scale) + " × "
                                + Math.round(out.cur.h / out.output.scale) + " at "
                                + Math.round(out.output.scale * 100) + "%"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
                        }
                    }
                }

                SettingsGroup {
                    SettingsRow {
                        title: "Resolution"
                        IxSelect {
                            buttonWidth: 170
                            demoOpen: demoPopup && index === 0
                            options: out.resolutions.map(r => r.replace("x", " × "))
                            currentIndex: out.resolutions.indexOf(out.cur.w + "x" + out.cur.h)
                            onActivated: (i) => backend.setDisplayMode(out.output.name,
                                out.modeFor(out.resolutions[i], out.cur.hz))
                        }
                    }
                    SettingsRow {
                        title: "Refresh rate"
                        IxSegmented {
                            segmentWidth: 72
                            options: out.rates.map(r => r + " Hz")
                            currentIndex: out.rates.indexOf(out.cur.hz)
                            onActivated: (i) => backend.setDisplayMode(out.output.name,
                                out.modeFor(out.cur.w + "x" + out.cur.h, out.rates[i]))
                        }
                    }
                    SettingsRow {
                        title: "Scale"
                        hint: "Larger text and controls"
                        divider: false
                        IxSegmented {
                            segmentWidth: 56
                            options: out.scales.map(s => Math.round(s * 100) + "%")
                            currentIndex: {
                                for (let i = 0; i < out.scales.length; ++i)
                                    if (Math.abs(out.scales[i] - out.output.scale) < 0.01) return i
                                return -1
                            }
                            onActivated: (i) => backend.setDisplayScale(out.output.name, out.scales[i])
                        }
                    }
                }
            }
        }
    }
}
