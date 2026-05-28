import QtQuick
import Quickshell
import qs.components
import qs.launcher.services
import qs.theme
import qs.tokens

Item {
    id: root

    required property bool active
    signal close()

    readonly property real maxHeight: parent && parent.height > 0
        ? parent.height - Spacing.large * 4
        : 500

    visible: active
    opacity: active ? 1 : 0
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    implicitWidth: content.implicitWidth
    implicitHeight: content.implicitHeight

    Behavior on opacity {
        NumberAnimation { duration: Durations.panelEnter; easing.type: Easing.OutCubic }
    }

    Component.onCompleted: Qt.callLater(() => {
        LauncherApps;
        LauncherActions;
        LauncherWallpapers;
    })

    onActiveChanged: {
        if (active)
            Qt.callLater(() => {
                content.focusSearch();
                content.refreshList();
            });
        else
            content.clearSearch();
    }

    LauncherContent {
        id: content
        maxHeight: root.maxHeight
        availableWidth: root.parent ? root.parent.width : 1920
        requestClose: function() { root.close(); }
    }
}
