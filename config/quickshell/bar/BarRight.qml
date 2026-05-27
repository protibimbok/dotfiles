import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.bar.components

RowLayout {
    id: root

    required property var shellRoot

    spacing: 10

    SysWidgets {}

    Rectangle {
        Layout.preferredWidth: 1
        Layout.preferredHeight: 18
        Layout.alignment: Qt.AlignVCenter
        color: Theme.colors.border
        opacity: 0.25
    }

    StatusIcons {
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignVCenter
        onHoverEntered: root.shellRoot.qsTriggerHovered = true
        onHoverExited: root.shellRoot.qsTriggerHovered = false
    }
}
