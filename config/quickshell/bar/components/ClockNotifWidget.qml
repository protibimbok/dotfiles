import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.services

Item {
    id: root

    implicitWidth: clockRow.implicitWidth + (notifBadge.visible ? 28 : 0)
    implicitHeight: 28

    signal hoverEntered()
    signal hoverExited()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
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
        spacing: 8

        Row {
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: Qt.formatDateTime(clock.date, "hh")
                color: Theme.pillTextOnHighlight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 0.3
            }

            Text {
                text: ":"
                color: Theme.pillAccentOnHighlight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true

                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.4; duration: 800; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0; duration: 800; easing.type: Easing.InOutSine }
                }
            }

            Text {
                text: Qt.formatDateTime(clock.date, "mm")
                color: Theme.pillTextOnHighlight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 0.3
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "ddd d")
            color: Theme.pillTextMutedOnHighlight
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 10
            font.weight: Font.Medium
        }

        Item {
            id: notifBadge
            width: 20
            height: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifications.unreadCount > 0

            Text {
                anchors.centerIn: parent
                text: "\uf0f3"
                color: Theme.pillAccentOnHighlight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                width: 7
                height: 7
                radius: 3.5
                color: Theme.pillAccentOnHighlight
            }
        }
    }
}
