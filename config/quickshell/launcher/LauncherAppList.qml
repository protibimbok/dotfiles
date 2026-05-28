import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.launcher.services
import qs.theme
import qs.tokens

ListView {
    id: root

    required property var search
    required property var requestClose

    property string mode: "apps"
    property var items: []

    onItemsChanged: currentIndex = 0

    model: items

    spacing: 2
    orientation: Qt.Vertical
    width: LauncherMetrics.itemWidth
    height: implicitHeight
    implicitWidth: LauncherMetrics.itemWidth
    implicitHeight: (LauncherMetrics.itemHeight + spacing) * Math.min(LauncherMetrics.maxShown, Math.max(count, 1)) - spacing
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    preferredHighlightBegin: 0
    preferredHighlightEnd: height
    highlightRangeMode: ListView.ApplyRange

    function _updateModel() {
        const text = search.text;
        const prefix = LauncherMetrics.actionPrefix;
        if (text.startsWith(prefix)) {
            if (text.startsWith(`${prefix}wallpaper `)) {
                mode = "wallpaper";
                items = [];
                return;
            }
            mode = "actions";
            LauncherActions.ensureLoaded();
            items = LauncherActions.query(text);
            return;
        }
        mode = "apps";
        const results = LauncherApps.search(text);
        items = text.length === 0 ? results.slice(0, LauncherMetrics.maxShown) : results;
    }

    function refresh() {
        _updateModel();
    }

    Connections {
        target: search
        function onTextChanged() { root._updateModel(); }
    }

    Connections {
        target: LauncherApps
        function onAllAppsChanged() { root._updateModel(); }
    }

    Connections {
        target: LauncherActions
        function onActionsChanged() { root._updateModel(); }
    }

    Component.onCompleted: _updateModel()

    delegate: Item {
        id: appDelegate
        required property var modelData
        required property int index

        width: ListView.view.width
        height: LauncherMetrics.itemHeight
        visible: root.mode === "apps" || root.mode === "actions"

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: Metrics.listRadius
            color: appDelegate.ListView.isCurrentItem
                ? Theme.primaryTint(0.15)
                : (itemHover.hovered ? Theme.surfaceTint(Theme.colors.surface, 0.5) : "transparent")
            border.color: appDelegate.ListView.isCurrentItem ? Theme.primaryTint(0.3) : "transparent"
            border.width: appDelegate.ListView.isCurrentItem ? 1 : 0
            Behavior on color { ColorAnimation { duration: Durations.colorTransition } }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 10

            Image {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                source: root.mode === "actions"
                    ? ""
                    : Quickshell.iconPath(modelData?.icon ?? "application-x-executable", "application-x-executable")
                sourceSize: Qt.size(32, 32)
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
                visible: root.mode !== "actions"
            }

            Text {
                Layout.preferredWidth: 32
                Layout.preferredHeight: 32
                Layout.alignment: Qt.AlignVCenter
                visible: root.mode === "actions"
                text: "\uf059"
                color: Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconMd
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.mode === "actions" ? (modelData?.name ?? "") : (modelData?.name ?? "")
                    color: Theme.colors.foreground
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.body
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    Layout.fillWidth: true
                    text: root.mode === "actions"
                        ? (modelData?.description ?? "")
                        : (modelData?.comment ?? "")
                    color: Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    visible: text.length > 0
                }
            }
        }

        HoverHandler {
            id: itemHover
            onHoveredChanged: {
                if (hovered)
                    root.currentIndex = appDelegate.index;
            }
        }

        TapHandler {
            onTapped: {
                if (root.mode === "actions")
                    LauncherActions.runAction(modelData, root.search, root.requestClose);
                else {
                    LauncherApps.launch(modelData);
                    root.requestClose();
                }
            }
        }
    }

    function decrementCurrentIndex() {
        currentIndex = Math.max(0, currentIndex - 1);
    }

    function incrementCurrentIndex() {
        currentIndex = Math.min(count - 1, currentIndex + 1);
    }
}
