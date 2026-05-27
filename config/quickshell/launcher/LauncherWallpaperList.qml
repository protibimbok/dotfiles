import "items"
import QtQuick
import Quickshell
import qs.launcher.services
import qs.theme
import qs.tokens

ListView {
    id: root

    required property var search
    required property var requestClose
    required property real availableWidth

    readonly property int itemWidth: LauncherMetrics.wallpaperWidth * 0.8 + Spacing.larger * 2

    model: ScriptModel {
        id: scriptModel
        objectProp: "path"
        readonly property string filterText: LauncherWallpapers.transformSearch(root.search.text)
        values: {
            const _listVersion = LauncherWallpapers.listVersion;
            const _listLength = LauncherWallpapers.list.length;
            void _listVersion;
            void _listLength;
            return LauncherWallpapers.query(filterText);
        }
        onValuesChanged: {
            const idx = values.findIndex(w => w.path === Theme.currentWallpaper);
            root.currentIndex = filterText.length > 0 ? 0 : Math.max(0, idx);
            root._focusCurrentIndex();
        }
    }

    Component.onCompleted: {
        const idx = LauncherWallpapers.list.findIndex(w => w.path === Theme.currentWallpaper);
        currentIndex = Math.max(0, idx);
    }

    Component.onDestruction: LauncherWallpapers.stopPreview()

    onCurrentItemChanged: {
        const path = currentItem?.path ?? currentItem?.modelData?.path;
        if (path)
            LauncherWallpapers.preview(path);
    }

    orientation: ListView.Horizontal
    spacing: Spacing.sm
    clip: true
    boundsBehavior: Flickable.StopAtBounds
    highlightMoveDuration: 300
    maximumFlickVelocity: 8000
    implicitWidth: Math.min(count, LauncherMetrics.maxWallpapers) * itemWidth
    implicitHeight: LauncherMetrics.wallpaperHeight

    preferredHighlightBegin: width / 2 - itemWidth / 2
    preferredHighlightEnd: width / 2 + itemWidth / 2
    highlightRangeMode: ListView.StrictlyEnforceRange

    function _focusCurrentIndex() {
        if (count <= 0 || currentIndex < 0)
            return;
        positionViewAtIndex(currentIndex, ListView.Center);
    }

    delegate: LauncherWallpaperItem {
        requestClose: root.requestClose
    }

    function decrementCurrentIndex() {
        currentIndex = Math.max(0, currentIndex - 1);
    }

    function incrementCurrentIndex() {
        currentIndex = Math.min(count - 1, currentIndex + 1);
    }
}
