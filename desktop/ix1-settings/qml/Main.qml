import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import Ix1Settings 1.0

Window {
    id: root
    width: 960
    height: 720
    visible: true
    title: "ix1 Settings"
    color: Theme.bgBase

    Component.onCompleted: Theme.mode = backend.theme
    Connections {
        target: backend
        function onThemeChanged() { Theme.mode = backend.theme }
    }

    property int currentPage: demoPage

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Sidebar {
            Layout.preferredWidth: 228
            Layout.fillHeight: true
            currentPage: root.currentPage
            onNavigate: (page) => root.currentPage = page
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.bgBase

            StackLayout {
                anchors.fill: parent
                anchors.margins: 28
                currentIndex: root.currentPage

                PersonalizationPage {}
                DisplayPage {}
                PowerPage {}
                SoundPage {}
                NetworkPage {}
                UpdatesPage {}
                AboutPage {}
            }
        }
    }
}
