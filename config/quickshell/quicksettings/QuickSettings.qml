import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.theme
import qs.services

Item {
    id: root
    signal close()

    required property var shellRoot

    focus: visible

    onVisibleChanged: if (visible) Audio.refresh()

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.15
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: panel
        width: 380
        height: Math.min(400, root.height - 64)
        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.top: parent.top
        anchors.topMargin: 54

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowBlur: 1.0
            shadowColor: "#30000000"
            shadowVerticalOffset: 6
        }

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Theme.colors.bg
            opacity: 0.92
        }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "transparent"
            border.color: Theme.colors.border
            border.width: 1
            opacity: 0.25
        }

        Item {
            anchors.fill: parent
            anchors.margins: 18
            visible: shellRoot.qsSubview === "main"

            ColumnLayout {
                anchors.fill: parent
                spacing: 14

                QSHeader {}

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.colors.border
                    opacity: 0.2
                }

                QSConnectivity {
                    shellRoot: root.shellRoot
                }

                QSEthernetDndRow {}

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.colors.border
                    opacity: 0.2
                }

                QSVolume {}

                Item { Layout.fillHeight: true }

                QSFooter {
                    shellRoot: root.shellRoot
                    onRequestClose: root.close()
                }
            }
        }

        QSWifiPanel {
            anchors.fill: parent
            anchors.margins: 18
            visible: shellRoot.qsSubview === "wifi"
            shellRoot: root.shellRoot
        }

        QSBluetoothPanel {
            anchors.fill: parent
            anchors.margins: 18
            visible: shellRoot.qsSubview === "bluetooth"
            shellRoot: root.shellRoot
        }
    }

    Keys.onEscapePressed: {
        if (shellRoot.qsSubview !== "main")
            shellRoot.qsSubview = "main";
        else
            root.close();
    }
}
