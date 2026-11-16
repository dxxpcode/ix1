import QtQuick
import Ix1Shell 1.0

// Toggle tile — icon, title, state line, trailing chevron. The body
// toggles; the chevron zone emits chevronClicked().
Item {
    id: tile
    property string icon: ""
    property int iconSize: 36
    property real iconWeight: 2
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool flashing: false
    signal toggled()
    signal chevronClicked()

    implicitHeight: 66

    readonly property color _fg: active ? CcStyle.textOnAccent : CcStyle.text
    readonly property color _fgMuted: active ? CcStyle.textOnAccentMuted : CcStyle.textMuted

    Gradient {
        id: accentFill
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: CcStyle.accentStart }
        GradientStop { position: 1.0; color: CcStyle.accentEnd }
    }

    Rectangle {
        anchors.fill: parent
        radius: CcStyle.radius
        color: body.pressed || chev.pressed ? CcStyle.surfacePressed
             : (body.containsMouse || chev.containsMouse ? CcStyle.surfaceHover : CcStyle.surface)
        gradient: tile.active ? accentFill : null
        border.width: 1
        border.color: tile.active ? Qt.rgba(1, 1, 1, 0.10) : CcStyle.surfaceBorder
        Behavior on color { ColorAnimation { duration: 120 } }
    }
    Rectangle {
        anchors.fill: parent
        radius: CcStyle.radius
        visible: tile.active && (body.containsMouse || chev.containsMouse)
        color: Qt.rgba(1, 1, 1, body.pressed || chev.pressed ? 0.10 : 0.06)
    }
    Rectangle {
        id: flash
        anchors.fill: parent
        radius: CcStyle.radius
        color: "transparent"
        border.width: 2
        border.color: CcStyle.accentEnd
        opacity: 0
        SequentialAnimation on opacity {
            running: tile.flashing
            loops: 2
            NumberAnimation { to: 1; duration: 220 }
            NumberAnimation { to: 0; duration: 320 }
        }
    }

    CcIcon {
        x: 33 - width / 2
        anchors.verticalCenter: parent.verticalCenter
        width: tile.iconSize
        height: tile.iconSize
        name: tile.icon
        weight: tile.iconWeight
        color: tile._fg
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 63
        anchors.right: parent.right
        anchors.rightMargin: 26
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        Text {
            width: parent.width
            text: tile.title
            color: tile._fg
            font.family: CcStyle.font
            font.pixelSize: 15
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: tile.subtitle
            color: tile._fgMuted
            font.family: CcStyle.font
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: body
        anchors.fill: parent
        anchors.rightMargin: chev.width
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.toggled()
    }
    MouseArea {
        id: chev
        anchors.right: parent.right
        width: 40
        height: parent.height
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.chevronClicked()

        CcIcon {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            name: "chevron-right"
            weight: 2.2
            color: tile.active ? CcStyle.textOnAccent : CcStyle.textMuted
        }
    }
}
