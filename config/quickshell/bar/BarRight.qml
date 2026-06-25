import QtQuick
import qs.theme
import qs.tokens
import qs.bar.components

// Mirrors the Waybar `modules-right` status group, left-to-right:
//   bluetooth, network, pulseaudio, cpu, battery
Row {
    id: root

    required property var shellRoot
    property bool backgroundless: false

    spacing: Spacing.pillGapSm

    // bluetooth · network · pulseaudio · cpu · battery
    BarPill {
        id: statusPill
        backgroundless: root.backgroundless
        width: statusIcons.implicitWidth + horizontalPadding * 2

        StatusIcons {
            id: statusIcons
            anchors.centerIn: parent
        }
    }
}
