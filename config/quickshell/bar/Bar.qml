import QtQuick
import qs.tokens
import qs.services
import qs.bar.components

Item {
    id: root

    required property var shellRoot

    // Plain solid bar: one full-width translucent strip, the same fill as the
    // drop-down panels so they melt straight out of its bottom edge with no seam.
    // The pill content (workspaces, clock, status icons) sits directly on top.
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, Metrics.barUnifiedFillOpacity)
    }

    Item {
        id: barContainer
        anchors.fill: parent
        anchors.leftMargin: Spacing.barHorizontal
        anchors.rightMargin: Spacing.barHorizontal
        anchors.topMargin: Spacing.barTopInset
        anchors.bottomMargin: Spacing.barBottomInset

        BarPill {
            id: leftPill
            backgroundless: true
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
            backgroundless: true
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
            backgroundless: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            shellRoot: root.shellRoot
        }

        BarRight {
            id: barRight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            backgroundless: true
            shellRoot: root.shellRoot
        }
    }
}
