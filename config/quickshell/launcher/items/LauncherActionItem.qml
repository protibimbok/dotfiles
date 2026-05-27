import QtQuick
import qs.components
import qs.theme
import qs.tokens
import qs.launcher.services

Item {
    id: root

    required property var modelData
    required property var list
    required property var requestClose

    implicitHeight: LauncherMetrics.itemHeight
    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Rounding.normal
        onClicked: LauncherActions.runAction(root.modelData, root.list.search, root.requestClose)
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Spacing.larger
        anchors.rightMargin: Spacing.larger
        anchors.margins: Spacing.sm

        MaterialIcon {
            id: icon
            icon: root.modelData?.icon ?? "help_outline"
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Spacing.normal
            anchors.verticalCenter: icon.verticalCenter
            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name
                text: root.modelData?.name ?? ""
                font.pixelSize: Typography.normal
            }

            StyledText {
                id: desc
                text: root.modelData?.description ?? ""
                font.pixelSize: Typography.bodySm
                color: Theme.colors.foregroundMuted
                elide: Text.ElideRight
                width: parent.width - icon.width - Spacing.normal * 2
                anchors.top: name.bottom
            }
        }
    }
}
