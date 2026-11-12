import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Ix1Settings 1.0

Item {
    id: page

    property string selectedSsid: ""
    property string selectedSecurity: ""
    property string password: ""

    function networkParts(entry) {
        const parts = String(entry).split(":")
        return {
            ssid: parts.length > 0 ? parts[0] : "",
            signal: parts.length > 1 ? parts[1] : "",
            security: parts.length > 2 ? parts[2] : "",
            active: parts.length > 3 && parts[3] === "yes"
        }
    }

    Component.onCompleted: backend.refresh()

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Network"
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 20
                font.weight: Font.DemiBold
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 44
                height: 24
                radius: 12
                color: backend.wifiEnabled ? Theme.accent : Theme.surface3

                Rectangle {
                    width: 18
                    height: 18
                    radius: 9
                    color: "#FFFFFF"
                    anchors.verticalCenter: parent.verticalCenter
                    x: backend.wifiEnabled ? parent.width - width - 3 : 3
                    Behavior on x { NumberAnimation { duration: 150 } }
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: backend.setWifiEnabled(!backend.wifiEnabled)
                }
            }
        }

        Text {
            text: backend.wifiEnabled
                  ? (backend.wifiSsid !== "" ? "Connected to " + backend.wifiSsid : "Wi-Fi enabled — select a network")
                  : "Wi-Fi is off"
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: Theme.radius
            color: Theme.surface1
            border.color: Theme.hairline
            border.width: 1
            clip: true

            ListView {
                anchors.fill: parent
                anchors.margins: 6
                clip: true
                model: backend.wifiNetworks
                spacing: 2

                Text {
                    anchors.centerIn: parent
                    visible: backend.wifiNetworks.length === 0
                    text: "No networks found"
                    color: Theme.textSecondary
                    font.family: Theme.fontFamily
                    font.pixelSize: 13
                }

                delegate: Rectangle {
                    width: ListView.view.width
                    height: 38
                    radius: 8
                    readonly property var info: page.networkParts(modelData)
                    color: info.ssid === page.selectedSsid ? Theme.surface3 : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: info.ssid === "" ? "(hidden)" : info.ssid
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 13
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            visible: info.security !== ""
                            text: "secured"
                            color: Theme.textSecondary
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                        Text {
                            visible: info.active
                            text: "connected"
                            color: Theme.accent
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: backend.wifiEnabled && !info.active
                        onClicked: {
                            page.selectedSsid = info.ssid
                            page.selectedSecurity = info.security
                            if (info.security === "") {
                                backend.connectWifi(info.ssid, "")
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            visible: page.selectedSecurity !== "" && page.selectedSsid !== ""
            spacing: 8

            TextField {
                id: passwordField
                Layout.fillWidth: true
                placeholderText: "Password for " + page.selectedSsid
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 13
                background: Rectangle {
                    radius: 8
                    color: Theme.surface2
                    border.color: Theme.hairline
                    border.width: 1
                }
                onTextChanged: page.password = text
            }
            Rectangle {
                width: 90
                height: 32
                radius: 8
                color: Theme.accent

                Text {
                    anchors.centerIn: parent
                    text: "Connect"
                    color: Theme.dark ? "#0E0F12" : "#FFFFFF"
                    font.family: Theme.fontFamily
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        backend.connectWifi(page.selectedSsid, page.password)
                        page.password = ""
                        passwordField.text = ""
                    }
                }
            }
        }
    }
}
