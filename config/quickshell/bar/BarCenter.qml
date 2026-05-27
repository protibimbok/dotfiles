import QtQuick
import QtQuick.Layouts
import qs.bar.components

RowLayout {
    id: root

    required property var shellRoot

    spacing: 0

    ClockNotifWidget {
        Layout.fillHeight: true
        Layout.preferredHeight: 44
        onHoverEntered: root.shellRoot.notifTriggerHovered = true
        onHoverExited: root.shellRoot.notifTriggerHovered = false
    }
}
