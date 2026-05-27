import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.services

Item {
    id: root
    implicitWidth: row.implicitWidth + 20
    // Fixed height: parent RowLayout (BarCenter) has no other row children to break a
    // circular implicitHeight dependency; parent.height here can resolve to 0, which
    // removes the pointer hit target (no hover cursor, no tap → panel never toggles).
    implicitHeight: 44

    signal hoverEntered()
    signal hoverExited()

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 10
        color: Theme.colors.bg1
        opacity: hoverArea.hovered ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
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

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: Qt.formatDateTime(clock.date, "ddd, dd MMM")
            color: Theme.colors.textMuted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: 14
            color: Theme.colors.border
            opacity: 0.2
        }

        Text {
            text: Qt.formatDateTime(clock.date, "h:mm AP")
            color: Theme.colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
        }

        Item {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter
            visible: Notifications.unreadCount > 0

            Text {
                anchors.centerIn: parent
                text: "\uf0f3"
                color: Notifications.unreadCount > 0 ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.8) : Theme.colors.textMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: 1
                anchors.rightMargin: 1
                width: 7; height: 7; radius: 3.5
                color: Theme.colors.accent
            }
        }
    }
}
