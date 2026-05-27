import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.tokens
import qs.services

Item {
    id: root

    implicitWidth: clockRow.implicitWidth + (notifBadge.visible ? Metrics.notifBadgeExtraWidth : 0)
    implicitHeight: Metrics.barWidgetHeight

    signal hoverEntered()
    signal hoverExited()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    function clockHour12() {
        const formatted = Qt.formatDateTime(clock.date, "hh ap")
        const space = formatted.lastIndexOf(" ")
        return space >= 0 ? formatted.slice(0, space) : formatted
    }

    HoverHandler {
        id: hoverArea
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hovered)
                root.hoverEntered()
            else
                root.hoverExited()
        }
    }

    Row {
        id: clockRow
        anchors.centerIn: parent
        spacing: Spacing.pillGap

        Row {
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: root.clockHour12()
                color: Theme.pillTextOnHighlight
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
                font.bold: true
                font.letterSpacing: 0.3
            }

            Text {
                text: ":"
                color: Theme.pillAccentOnHighlight
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
                font.bold: true

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: Durations.barHideDelay; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: Durations.barHideDelay; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: Qt.formatDateTime(clock.date, "mm")
                color: Theme.pillTextOnHighlight
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
                font.bold: true
                font.letterSpacing: 0.3
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "ddd d")
            color: Theme.pillTextMutedOnHighlight
            font.family: Typography.fontFamily
            font.pixelSize: Typography.label
            font.weight: Font.Medium
        }

        Item {
            id: notifBadge
            width: Metrics.iconNotif
            height: Metrics.iconNotif
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifications.unreadCount > 0

            Text {
                anchors.centerIn: parent
                text: "\uf0f3"
                color: Theme.pillAccentOnHighlight
                font.family: Typography.fontFamily
                font.pixelSize: Typography.title
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                width: Metrics.iconNotifBadge
                height: Metrics.iconNotifBadge
                radius: Metrics.iconNotifBadge / 2
                color: Theme.pillAccentOnHighlight
            }
        }
    }
}
