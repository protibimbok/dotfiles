import QtQuick
import Quickshell
import qs.theme
import qs.tokens

// Lightweight hover tooltip shown below its `target`. The anchor item is fixed
// for the lifetime of the popup (only `shown` toggles) — reassigning a
// PopupWindow's anchor.item to null crashes quickshell.
PopupWindow {
    id: root

    required property Item target
    property string text: ""
    property bool shown: false

    visible: root.shown && root.text.length > 0
    color: "transparent"

    implicitWidth: Math.max(48, label.implicitWidth + 20)
    implicitHeight: label.implicitHeight + 12

    anchor.item: root.target
    anchor.rect.x: 0
    anchor.rect.y: 0
    anchor.rect.width: root.target ? root.target.width : 0
    anchor.rect.height: root.target ? root.target.height : 0
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom

    Rectangle {
        anchors.fill: parent
        radius: Metrics.rowRadius
        color: Theme.colors.surfaceHigh
        border.width: 1
        border.color: Theme.pillBorder

        Text {
            id: label
            anchors.centerIn: parent
            text: root.text
            color: Theme.pillText
            font.family: Typography.fontFamily
            font.pixelSize: Typography.bodySm
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
