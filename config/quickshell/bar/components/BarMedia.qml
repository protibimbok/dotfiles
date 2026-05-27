import QtQuick
import qs.theme
import qs.services
import qs.utils

Item {
    id: root

    implicitWidth: contentRow.implicitWidth
    implicitHeight: 22

    readonly property bool canGoToWorkspace: Mpris.playerWorkspaceId >= 0

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 6

        Item {
            id: appIconHost
            width: 16
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: Icons.forWindowClass(Mpris.playerIconClass)
                sourceSize: Qt.size(16, 16)
                smooth: true
                opacity: appIconHover.hovered ? 1.0 : 0.85
                Behavior on opacity { NumberAnimation { duration: 130 } }
            }

            HoverHandler {
                id: appIconHover
                enabled: root.canGoToWorkspace
                cursorShape: root.canGoToWorkspace ? Qt.PointingHandCursor : Qt.ArrowCursor
            }

            TapHandler {
                enabled: root.canGoToWorkspace
                onTapped: Mpris.goToPlayerWorkspace()
            }
        }

        Item {
            id: mediaControls
            implicitWidth: controlsRow.implicitWidth
            implicitHeight: controlsRow.implicitHeight
            anchors.verticalCenter: parent.verticalCenter

            Row {
                id: controlsRow
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Mpris.status === "Playing" ? "\uf04c" : "\uf04b"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    color: Theme.pillAccentAlt
                }

                Text {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, 140)
                    text: Mpris.displayLine.length > 0 ? Mpris.displayLine : Mpris.status
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    color: Theme.pillText
                }
            }

            HoverHandler {
                id: mediaHover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: Mpris.playPause()
            }
        }
    }
}
