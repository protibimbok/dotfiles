import QtQuick
import qs.theme
import qs.tokens
import qs.bar.components

BarPill {
    id: root

    required property var shellRoot

    elevation: Metrics.barElevationCenter
    width: clockWidget.implicitWidth + horizontalPadding * 2

    ClockNotifWidget {
        id: clockWidget
        anchors.centerIn: parent
    }
}
