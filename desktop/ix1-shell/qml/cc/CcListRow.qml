import QtQuick
import Ix1Shell 1.0

// List row for expanders — icon, label, trailing "check" / "lock" /
// "connected". `needsPassword` reveals an inline password field.
Item {
    id: row
    property string icon: ""
    property real iconOpacity: 1
    property string label: ""
    property string trailing: ""
    property bool needsPassword: false
    property bool pwOpen: false
    signal activated()
    signal joined(string password)

    height: pwOpen ? 76 : 38
    clip: true
    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: area.containsMouse ? CcStyle.rowHover : "transparent"
    }

    CcIcon {
        x: 10
        y: 10
        width: 18
        height: 18
        name: row.icon
        opacity: row.iconOpacity
        color: row.trailing === "connected" || row.trailing === "check" ? CcStyle.accent : CcStyle.text
    }

    Text {
        x: 40
        width: parent.width - x - trailingItem.width - 16
        height: 38
        verticalAlignment: Text.AlignVCenter
        text: row.label
        color: CcStyle.text
        font.family: CcStyle.font
        font.pixelSize: 13
        elide: Text.ElideRight
    }

    Item {
        id: trailingItem
        anchors.right: parent.right
        anchors.rightMargin: 10
        width: row.trailing === "connected" ? connected.implicitWidth : 16
        height: 38

        Text {
            id: connected
            visible: row.trailing === "connected"
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            text: "Connected"
            color: CcStyle.accent
            font.family: CcStyle.font
            font.pixelSize: 12
        }
        CcIcon {
            visible: row.trailing === "check" || row.trailing === "lock"
            anchors.centerIn: parent
            width: 15
            height: 15
            name: row.trailing === "lock" ? "lock" : "check"
            color: row.trailing === "lock" ? CcStyle.textMuted : CcStyle.accent
        }
    }

    Rectangle {
        visible: row.pwOpen
        x: 40
        y: 40
        width: parent.width - x - 10
        height: 30
        radius: 8
        color: CcStyle.dark ? "#1A2132" : "#F4F6FA"
        border.width: 1
        border.color: pwField.activeFocus ? CcStyle.accent : CcStyle.surfaceBorder

        TextInput {
            id: pwField
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            verticalAlignment: Text.AlignVCenter
            color: CcStyle.text
            font.family: CcStyle.font
            font.pixelSize: 13
            echoMode: TextInput.Password
            selectByMouse: true
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: !pwField.text && !pwField.activeFocus
                text: "Password"
                color: CcStyle.textMuted
                font.family: CcStyle.font
                font.pixelSize: 13
            }
            onAccepted: {
                row.joined(text)
                row.pwOpen = false
                text = ""
            }
        }
    }

    MouseArea {
        id: area
        width: parent.width
        height: 38
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (row.needsPassword) {
                row.pwOpen = !row.pwOpen
                if (row.pwOpen) {
                    pwField.forceActiveFocus()
                }
            } else {
                row.activated()
            }
        }
    }
}
