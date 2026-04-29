import QtQuick
import qs.theme

/// Compact toolbar icon (Nerd Font glyph); optional continuous rotation while `spinning` is true.
Item {
    id: root

    property string iconGlyph: ""
    property bool spinning: false
    property bool active: true

    signal activated()

    implicitWidth: 32
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: hov.hovered && root.active ? Theme.colors.bg2 : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    Text {
        id: glyph
        anchors.centerIn: parent
        text: root.iconGlyph
        color: root.active ? (hov.hovered ? Theme.colors.text : Theme.colors.textMuted) : Theme.colors.textMuted
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 13
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        transformOrigin: Item.Center
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RotationAnimator {
        target: glyph
        running: root.spinning
        from: 0
        to: 360
        duration: 900
        loops: Animation.Infinite
        easing.type: Easing.Linear
    }

    HoverHandler {
        id: hov
        cursorShape: root.active ? Qt.PointingHandCursor : Qt.ForbiddenCursor
    }
    TapHandler {
        onTapped: {
            if (root.active)
                root.activated();
        }
    }
}
