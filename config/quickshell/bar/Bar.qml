import QtQuick
import qs.theme
import qs.tokens
import qs.services
import qs.bar.components

Item {
    id: root

    required property var shellRoot

    Item {
        id: barContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Spacing.barHorizontal
        anchors.rightMargin: Spacing.barHorizontal
        anchors.topMargin: Spacing.barTop
        height: parent.height - Spacing.barVerticalInset

        BarPill {
            id: leftPill
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: leftHost.implicitWidth + horizontalPadding * 2

            Item {
                id: leftHost
                anchors.centerIn: parent
                implicitWidth: barLeft.implicitWidth
                implicitHeight: Metrics.barPillHeight

                BarLeft {
                    id: barLeft
                    anchors.verticalCenter: parent.verticalCenter
                    shellRoot: root.shellRoot
                }
            }
        }

        BarPill {
            id: mediaPill
            anchors.left: leftPill.right
            anchors.leftMargin: Mpris.isActive ? Spacing.pillGap : 0
            anchors.verticalCenter: parent.verticalCenter
            visible: Mpris.isActive
            width: Mpris.isActive
                ? Math.max(Metrics.barMediaMinWidth, mediaHost.implicitWidth + horizontalPadding * 2)
                : 0

            BarMedia {
                id: mediaHost
                anchors.centerIn: parent
            }

            Behavior on width { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
            Behavior on anchors.leftMargin { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
        }

        BarCenter {
            id: barCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            shellRoot: root.shellRoot
        }

        BarRight {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            shellRoot: root.shellRoot
        }
    }
}
