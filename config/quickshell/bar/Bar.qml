import QtQuick
import qs.theme
import qs.services
import qs.bar.components

Item {
    id: root

    required property var shellRoot

    // Transparent strip — visual weight lives in floating pills (reference layout).
    Item {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 11
        anchors.rightMargin: 11
        anchors.topMargin: 1
        height: parent.height - 2

        // Left — workspaces (BarLeft.qml unchanged)
        BarPill {
            id: leftPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: leftHost.implicitWidth + horizontalPadding * 2

            Item {
                id: leftHost
                anchors.centerIn: parent
                implicitWidth: barLeft.implicitWidth
                implicitHeight: Theme.barPillHeight

                BarLeft {
                    id: barLeft
                    anchors.verticalCenter: parent.verticalCenter
                    shellRoot: root.shellRoot
                }
            }
        }

        // Media — between workspaces and clock (hidden when idle)
        BarPill {
            id: mediaPill
            anchors.left: leftPill.right
            anchors.leftMargin: Mpris.isActive ? 8 : 0
            anchors.verticalCenter: parent.verticalCenter
            visible: Mpris.isActive
            width: Mpris.isActive
                ? Math.max(88, mediaHost.implicitWidth + horizontalPadding * 2)
                : 0

            BarMedia {
                id: mediaHost
                anchors.centerIn: parent
            }

            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            Behavior on anchors.leftMargin { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
        }

        // Center — clock + notifications
        BarCenter {
            id: barCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            shellRoot: root.shellRoot
        }

        // Right — stats, connectivity, system / quick settings
        BarRight {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            shellRoot: root.shellRoot
        }
    }
}
