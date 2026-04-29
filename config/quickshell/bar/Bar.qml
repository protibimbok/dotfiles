import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root

    required property var shellRoot

    Rectangle {
        anchors.fill: parent
        color: Theme.colors.bg
        opacity: Theme.barOpacity
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.colors.border
        opacity: 0.3
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 0

        BarLeft {
            Layout.fillWidth: false
            shellRoot: root.shellRoot
        }

        Item { Layout.fillWidth: true }

        BarCenter {
            Layout.fillWidth: false
            shellRoot: root.shellRoot
        }

        Item { Layout.fillWidth: true }

        BarRight {
            Layout.fillWidth: false
            shellRoot: root.shellRoot
        }
    }
}
