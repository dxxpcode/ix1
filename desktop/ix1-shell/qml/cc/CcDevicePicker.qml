import QtQuick
import Ix1Shell 1.0

// "Output Device" picker — labelled field showing the active sink with a
// dropdown list of the others.
Column {
    id: root
    property var model: []
    property bool open: false
    signal selected(var item)

    readonly property string current: {
        for (const d of model) {
            if (d.active) return d.name
        }
        return model.length ? model[0].name : "Speakers"
    }

    spacing: 0

    Item {
        width: parent.width
        height: 18
        CcIcon {
            x: 9
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 20
            name: "headphones"
            weight: 1.8
            color: CcStyle.textMuted
        }
        Text {
            x: 41
            anchors.verticalCenter: parent.verticalCenter
            text: "Output Device"
            color: CcStyle.textMuted
            font.family: CcStyle.font
            font.pixelSize: 12
        }
    }

    Item {
        width: parent.width
        height: 35

        Rectangle {
            id: field
            x: 41
            width: parent.width - x - 5
            height: parent.height
            radius: 10
            color: area.pressed ? CcStyle.surfacePressed
                 : (area.containsMouse ? CcStyle.surfaceHover : CcStyle.surface)
            border.width: 1
            border.color: CcStyle.surfaceBorder

            CcIcon {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                width: 15
                height: 15
                name: "lock"
                weight: 1.7
                color: CcStyle.text
            }
            Text {
                x: 36
                width: parent.width - x - 40
                anchors.verticalCenter: parent.verticalCenter
                text: root.current
                color: CcStyle.text
                font.family: CcStyle.font
                font.pixelSize: 12
                elide: Text.ElideRight
            }
            CcIcon {
                anchors.right: parent.right
                anchors.rightMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                width: 15
                height: 15
                name: "chevron-down"
                color: CcStyle.textMuted
                rotation: root.open ? 180 : 0
                Behavior on rotation { NumberAnimation { duration: 150 } }
            }
            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.open = !root.open
            }
        }
    }

    Item {
        width: parent.width
        height: list.height > 0 ? list.height + 6 : 0
        CcExpander {
            id: list
            x: 41
            y: 6
            width: parent.width - x - 5
            open: root.open
            Repeater {
                model: root.model
                delegate: CcListRow {
                    required property var modelData
                    width: parent.width
                    icon: "headphones"
                    label: modelData.name
                    trailing: modelData.active ? "check" : ""
                    onActivated: {
                        root.selected(modelData)
                        root.open = false
                    }
                }
            }
        }
    }
}
