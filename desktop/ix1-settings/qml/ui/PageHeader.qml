import QtQuick
import QtQuick.Layouts
import Ix1Settings 1.0

ColumnLayout {
    property string title
    property string subtitle
    Layout.fillWidth: true
    spacing: 4

    Text {
        text: parent.title
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 24
        font.weight: Font.Medium
    }
    Text {
        visible: text.length > 0
        text: parent.subtitle
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 13
        Layout.fillWidth: true
        wrapMode: Text.Wrap
    }
}
