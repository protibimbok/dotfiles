import QtQuick
import qs.theme
import qs.tokens
import qs.services
import qs.bar.components

Item {
    id: root

    required property var shellRoot

    readonly property bool unifiedBar: Hyprland.singleWindowBarMode

    Item {
        id: barContainer
        anchors.fill: parent
        anchors.leftMargin: root.unifiedBar ? 0 : Spacing.barHorizontal
        anchors.rightMargin: root.unifiedBar ? 0 : Spacing.barHorizontal
        anchors.topMargin: root.unifiedBar ? 0 : Spacing.barTopInset
        anchors.bottomMargin: root.unifiedBar ? 0 : Spacing.barBottomInset

        Behavior on anchors.leftMargin { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
        Behavior on anchors.rightMargin { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
        Behavior on anchors.topMargin { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
        Behavior on anchors.bottomMargin { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            visible: root.unifiedBar
            color: Theme.surfaceTint(Theme.colors.surface, Metrics.barUnifiedFillOpacity)
            opacity: root.unifiedBar ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
        }

        BarPill {
            id: leftPill
            backgroundless: root.unifiedBar
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
            backgroundless: root.unifiedBar
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
            backgroundless: root.unifiedBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            shellRoot: root.shellRoot
        }

        BarRight {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            backgroundless: root.unifiedBar
            shellRoot: root.shellRoot
        }
    }
}
