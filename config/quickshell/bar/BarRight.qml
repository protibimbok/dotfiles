import QtQuick
import qs.theme
import qs.bar.components

Row {
    id: root

    required property var shellRoot

    spacing: 6

    BarPill {
        id: statsPill
        width: sysWidgets.implicitWidth + horizontalPadding * 2

        SysWidgets {
            id: sysWidgets
            anchors.centerIn: parent
        }
    }

    BarPill {
        id: connectivityPill
        width: connectivityIcons.implicitWidth + horizontalPadding * 2

        StatusIcons {
            id: connectivityIcons
            anchors.centerIn: parent
            section: "connectivity"
        }
    }

    BarPill {
        id: systemPill
        width: systemIcons.implicitWidth + horizontalPadding * 2

        StatusIcons {
            id: systemIcons
            anchors.centerIn: parent
            section: "system"
            onHoverEntered: root.shellRoot.qsTriggerHovered = true
            onHoverExited: root.shellRoot.qsTriggerHovered = false
        }
    }
}
