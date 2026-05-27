import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.tokens
import qs.launcher.services

Item {
    id: root

    required property var modelData
    required property var requestClose
    property bool isSelected: false

    implicitHeight: LauncherMetrics.itemHeight
    width: parent ? parent.width : LauncherMetrics.itemWidth

    property bool hovered: rowHover.hovered

    Rectangle {
        anchors.fill: parent
        anchors.margins: 2
        radius: Metrics.listRadius
        color: root.isSelected
            ? Theme.primaryTint(0.15)
            : (root.hovered ? Theme.surfaceTint(Theme.colors.surface, 0.5) : "transparent")
        border.color: root.isSelected ? Theme.primaryTint(0.3) : "transparent"
        border.width: root.isSelected ? 1 : 0
        z: 0
        Behavior on color { ColorAnimation { duration: Durations.colorTransition } }
        Behavior on border.color { ColorAnimation { duration: Durations.colorTransition } }
    }

    RowLayout {
        id: row
        anchors.fill: parent
        anchors.leftMargin: Spacing.larger
        anchors.rightMargin: Spacing.larger
        spacing: Spacing.normal
        z: 1

        Image {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            source: Quickshell.iconPath(root.modelData?.icon ?? "", "application-x-executable")
            sourceSize: Qt.size(32, 32)
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.modelData?.name ?? ""
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                Layout.fillWidth: true
                text: root.modelData?.comment ?? ""
                color: Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.bodySm
                elide: Text.ElideRight
                maximumLineCount: 1
                visible: text.length > 0
            }
        }
    }

    HoverHandler { id: rowHover }
    TapHandler {
        onTapped: {
            if (root.modelData)
                LauncherApps.launch(root.modelData);
            root.requestClose();
        }
    }
}
