import QtQuick
import Ix1Shell 1.0

// Grouped-list row — leading glyph, label, trailing state.
// `trailing`: "pill" (accent Connected chip), "lock", "check", "" (none).
// `needsPassword` expands an inline password field on click (secured wifi).
Item {
    id: row
    property string glyph: "wifi"
    property real glyphStrength: 100
    property string label: ""
    property string trailing: ""         // "pill" | "lock" | "check" | ""
    property string pillText: "Connected"
    property bool needsPassword: false
    property bool pwOpen: false
    signal activated()
    signal joined(string password)

    height: pwOpen ? 66 : 34
    clip: true
    Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: area.containsMouse ? Theme.surface3
             : (row.trailing === "pill" ? Theme.glassHover : "transparent")
    }

    Glyph {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 11
        width: 15
        height: 12
        name: row.glyph
        strength: row.glyphStrength
        color: row.trailing === "pill" ? Theme.accent : Theme.textPrimary
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 30
        anchors.right: pill.visible ? pill.left
                     : (lockGlyph.visible ? lockGlyph.left : parent.right)
        anchors.rightMargin: 6
        anchors.top: parent.top
        anchors.topMargin: 9
        text: row.label
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 12
        elide: Text.ElideRight
    }

    Glyph {
        id: lockGlyph
        visible: row.trailing === "lock"
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 11
        width: 10
        height: 12
        name: "lock"
        color: Theme.textSecondary
    }
    Glyph {
        visible: row.trailing === "check"
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 11
        width: 12
        height: 10
        name: "check"
        color: Theme.accent
    }
    Rectangle {
        id: pill
        visible: row.trailing === "pill"
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.top: parent.top
        anchors.topMargin: 8
        width: pillLabel.implicitWidth + 12
        height: 18
        radius: 9
        color: Theme.accent
        Text {
            id: pillLabel
            anchors.centerIn: parent
            text: row.pillText
            color: "#FFFFFF"
            font.family: Theme.fontFamily
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }
    }

    // Inline password field for secured networks.
    Rectangle {
        visible: row.pwOpen
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 30
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 36
        height: 26
        radius: 6
        color: Theme.surface1
        border.color: pwField.activeFocus ? Theme.accent : Theme.hairline
        border.width: 1

        TextInput {
            id: pwField
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: Text.AlignVCenter
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 12
            echoMode: TextInput.Password
            selectByMouse: true
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                visible: !pwField.text && !pwField.activeFocus
                text: "Password"
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
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
        anchors.fill: parent
        anchors.bottomMargin: row.pwOpen ? 30 : 0
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
