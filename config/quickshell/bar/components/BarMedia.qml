import QtQuick
import qs.theme
import qs.tokens
import qs.services
import qs.utils

Item {
    id: root

    implicitWidth: contentRow.implicitWidth
    implicitHeight: Metrics.barMediaHeight

    readonly property bool canGoToWorkspace: Mpris.playerWorkspaceId >= 0

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Spacing.pillGapSm

        Item {
            id: appIconHost
            width: Metrics.iconApp
            height: Metrics.iconApp
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: Icons.forWindowClass(Mpris.playerIconClass)
                sourceSize: Qt.size(Metrics.iconApp, Metrics.iconApp)
                smooth: true
                opacity: appIconHover.hovered ? 1.0 : 0.85
                Behavior on opacity { NumberAnimation { duration: Durations.press } }
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
                spacing: Spacing.pillGapSm

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Mpris.status === "Playing" ? "\uf04c" : "\uf04b"
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.body
                    color: Theme.pillAccentAlt
                }

                Text {
                    id: titleText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, Metrics.mediaTitleMaxWidth)
                    text: Mpris.displayLine.length > 0 ? Mpris.displayLine : Mpris.status
                    elide: Text.ElideRight
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.label
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
