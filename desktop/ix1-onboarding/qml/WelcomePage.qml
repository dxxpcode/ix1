import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ix1Onboarding

Item {
    id: welcomePage
    opacity: StackLayout.isCurrentItem ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    // Staggered entrance — emblem, kicker, headline, support, card each
    // rise in turn when the page lands. `enter` runs once per landing.
    readonly property bool landed: StackLayout.isCurrentItem
    property real enter: 0
    onLandedChanged: if (landed) enterAnim.restart()
    Component.onCompleted: if (landed) enterAnim.restart()
    NumberAnimation {
        id: enterAnim
        target: welcomePage
        property: "enter"
        from: 0
        to: 1
        duration: 900
        easing.type: Easing.OutCubic
    }
    // Elements stage in ~90ms apart across the first 60% of `enter`.
    function staged(i) { return Math.min(1, Math.max(0, (enter - i * 0.15) / 0.4)) }

    // The name line only earns its row when it fits the 54px column —
    // unusually long names fall back to the brand-only greeting.
    readonly property bool hasName:
        backend.firstName !== "" && backend.firstName.length <= 16

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
            y: Math.max(24, fl.height * 0.12)
            width: 620
            spacing: 0

            // The brand moment — the mark arrives first.
            Image {
                source: "qrc:/Ix1Onboarding/assets/logo-white.png"
                Layout.preferredHeight: 52
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                opacity: welcomePage.staged(0)
                transform: Translate { y: (1 - welcomePage.staged(0)) * 10 }
            }
            Text {
                text: "step 01 — welcome"
                color: Theme.textMuted
                font.family: Theme.fontMono
                font.pixelSize: 11
                font.letterSpacing: 2.2
                Layout.topMargin: 26
                opacity: welcomePage.staged(1)
                transform: Translate { y: (1 - welcomePage.staged(1)) * 8 }
            }
            GradientText {
                // A name turns the greeting two-line — the brand line
                // keeps its period only when it stands alone.
                text: "Welcome to ix1" + (welcomePage.hasName ? "," : ".")
                pixelSize: 54
                Layout.topMargin: 16
                opacity: welcomePage.staged(2)
                transform: Translate { y: (1 - welcomePage.staged(2)) * 8 }
            }
            GradientText {
                visible: welcomePage.hasName
                text: backend.firstName + "."
                pixelSize: 54
                opacity: welcomePage.staged(2)
                transform: Translate { y: (1 - welcomePage.staged(2)) * 8 }
            }
            Text {
                text: "Two quiet steps and the desktop is yours — get online, then go."
                color: Theme.textSecondary
                font.family: Theme.fontSans
                font.pixelSize: 15
                lineHeight: 1.6
                wrapMode: Text.Wrap
                Layout.fillWidth: true
                Layout.topMargin: 14
                opacity: welcomePage.staged(3)
                transform: Translate { y: (1 - welcomePage.staged(3)) * 8 }
            }

            // The road ahead — the same row language as the disk list.
            Rectangle {
                Layout.topMargin: 34
                Layout.fillWidth: true
                height: 2 * 62
                radius: 14
                color: Theme.card
                border.width: 1
                border.color: Theme.border
                opacity: welcomePage.staged(4)
                transform: Translate { y: (1 - welcomePage.staged(4)) * 8 }

                Column {
                    width: parent.width
                    Repeater {
                        model: [
                            { n: "02", t: "Connect to wi-fi",
                              d: "pick a network, or skip — it takes seconds" },
                            { n: "03", t: "You're in",
                              d: "the desktop, ready — start exploring" },
                        ]
                        delegate: Item {
                            width: parent.width
                            height: 62
                            // Hairline divider between rows.
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
