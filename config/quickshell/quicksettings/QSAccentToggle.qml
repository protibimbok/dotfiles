import QtQuick
import qs.theme
import qs.tokens

Item {
    id: root

    property bool checked: false
    signal triggered()

    implicitWidth: 48
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked
            ? Theme.primaryTint(0.35)
            : Theme.colors.surface
        border.color: Theme.colors.outline
        border.width: 1
        Behavior on color { ColorAnimation { duration: 160 } }

        Rectangle {
            width: parent.height - 5
            height: parent.height - 5
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: root.checked ? parent.width - width - 3 : 3
            color: Theme.colors.background
            Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        }

        HoverHandler { cursorShape: Qt.PointingHandCursor }
        TapHandler {
            onTapped: root.triggered()
        }
    }
}
