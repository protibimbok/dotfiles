import QtQuick
import qs.theme
import qs.tokens
import qs.bar.components

BarPill {
    id: root

    required property var shellRoot

    highlighted: true
    elevation: Metrics.barElevationCenter
    width: clockWidget.implicitWidth + horizontalPadding * 2

    ClockNotifWidget {
        id: clockWidget
        anchors.centerIn: parent
        onHoverEntered: root.shellRoot.notifTriggerHovered = true
        onHoverExited: root.shellRoot.notifTriggerHovered = false
    }
}
