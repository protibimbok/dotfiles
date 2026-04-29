import QtQuick
import Quickshell
import qs.theme

Item {
    id: root

    property string format: "ddd MMM d  hh:mm"

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, root.format)
        color: Theme.colors.text
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    implicitWidth: 160
    implicitHeight: 24
}
