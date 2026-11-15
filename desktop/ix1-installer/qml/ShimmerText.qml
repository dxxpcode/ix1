import QtQuick

// Live text shimmer — a soft highlight band that sweeps across the
// glyphs. Two nested clip windows (wide dim pass + narrow bright core)
// give the band a falloff without needing opacity-mask effects.
// `running` loops the sweep; `sweep` plays a single pass.
Item {
    id: root

    property alias text: base.text
    property alias fontFamily: base.font.family
    property alias fontPixelSize: base.font.pixelSize
    property alias fontWeight: base.font.weight
    property alias fontLetterSpacing: base.font.letterSpacing
    property color color: "#fafafa"
    property color shineColor: "#ffffff"
    property real shineOpacity: 0.85
    property bool running: false
    property bool sweep: false
    property real _sx: 1.5

    implicitWidth: base.implicitWidth
    implicitHeight: base.implicitHeight
    width: implicitWidth
    height: implicitHeight

    Text {
        id: base
        color: root.color
        renderType: Text.NativeRendering
    }

    NumberAnimation {
        id: loopAnim
        target: root
        property: "_sx"
        from: -0.4; to: 1.4; duration: 1500
        loops: Animation.Infinite
        running: root.running
    }
    NumberAnimation {
        id: onceAnim
        target: root
        property: "_sx"
        from: -0.4; to: 1.4; duration: 1400
        easing.type: Easing.InOutSine
        running: root.sweep
    }

    Item {
        anchors.fill: parent
        clip: true
        visible: loopAnim.running || onceAnim.running

        // Wide soft pass.
        Item {
            clip: true
            height: parent.height
            width: parent.width * 0.55
            x: root._sx * root.width - width / 2
            Text {
                text: base.text
                font.family: base.font.family
                font.pixelSize: base.font.pixelSize
                font.weight: base.font.weight
                font.letterSpacing: base.font.letterSpacing
                renderType: Text.NativeRendering
                color: root.shineColor
                opacity: 0.30
                x: -parent.x
            }
        }
        // Bright core.
        Item {
            clip: true
            height: parent.height
            width: parent.width * 0.18
            x: root._sx * root.width - width / 2
            Text {
                text: base.text
                font.family: base.font.family
                font.pixelSize: base.font.pixelSize
                font.weight: base.font.weight
                font.letterSpacing: base.font.letterSpacing
                renderType: Text.NativeRendering
                color: root.shineColor
                opacity: root.shineOpacity
                x: -parent.x
            }
        }
    }
}
