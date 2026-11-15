import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ix1Onboarding

Item {
    id: readyPage
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // The done moment — the badge pops and the check draws itself when
    // this page lands. Mirrors the deploy stage's completion beat.
    readonly property bool landed: StackLayout.isCurrentItem
    property real appear: 0
    onLandedChanged: if (landed) appearAnim.restart()
    NumberAnimation {
        id: appearAnim
        target: readyPage
        property: "appear"
        to: 1
        duration: 600
        easing.type: Easing.OutCubic
    }

    Flickable {
        id: fl
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: col.implicitHeight + col.y

        ColumnLayout {
            id: col
            x: Math.max(0, (fl.width - width) / 2)
            y: Math.max(24, fl.height * 0.14)
            width: 620
            spacing: 0

            Text {
                text: "step 03 — ready"
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 2.2
            }
            RowLayout {
                Layout.topMargin: 14
                spacing: 18
                GradientText {
                    text: "You're in."
                    pixelSize: 92
                    sweep: readyPage.landed
                }
                // Completion badge — an emerald disc that pops in,
                // then the white check draws itself inside it.
                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    Layout.alignment: Qt.AlignBottom
                    Layout.bottomMargin: 13
                    radius: 21
                    color: Theme.success
                    scale: 0.4 + readyPage.appear * 0.6
                    opacity: readyPage.appear
                    CheckMark {
                        anchors.centerIn: parent
                        width: 22; height: 22
                        strokeWidth: 2.4
                        checkColor: "#fafafa"
                        progress: Math.max(0, (readyPage.appear - 0.45) * 2.2)
                    }
                }
            }
            Text {
                text: backend.connectedSsid !== ""
                    ? "ix1 is ready — connected to " + backend.connectedSsid + "."
                    : "ix1 is ready — you can connect to wi-fi anytime from the desktop."
                color: Theme.textSecondary
                font.family: Theme.fontSans
                font.pixelSize: 15
                lineHeight: 1.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.topMargin: 16
            }

            // Where things live — one quiet orientation card.
            Rectangle {
                Layout.topMargin: 34
                Layout.fillWidth: true
                height: 2 * 62
                radius: 14
                color: Theme.card
                border.width: 1
                border.color: Theme.border

                Column {
                    width: parent.width
                    Repeater {
                        model: [
                            { n: "apps",     t: "The dock",
                              d: "installed apps live in the launcher and the dock" },
                            { n: "settings", t: "System settings",
                              d: "network, updates and devices — one gear away" },
                        ]
                        delegate: Item {
                            width: parent.width
                            height: 62
                            Rectangle {
                                visible: index > 0
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
                                Text {
                                    text: modelData.n
                                    color: Theme.textDim
                                    font.family: Theme.fontMono
                                    font.pixelSize: 11
                                    font.letterSpacing: 1.6
                                }
                                Column {
                                    spacing: 3
                                    Text {
                                        text: modelData.t
                                        color: Theme.textPrimary
                                        font.family: Theme.fontSans
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        text: modelData.d
                                        color: Theme.textMuted
                                        font.family: Theme.fontSans
                                        font.pixelSize: 12
                                    }
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }
        }
    }
}
