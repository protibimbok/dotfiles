import QtQuick
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

    BarLeft {
        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        shellRoot: root.shellRoot
    }

    BarCenter {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        shellRoot: root.shellRoot
    }

    BarRight {
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        shellRoot: root.shellRoot
    }
}
