import QtQuick
import qs.launcher.services
import qs.theme
import qs.tokens

Item {
    id: root

    required property real maxHeight
    required property var search
    required property var requestClose
    required property real availableWidth

    readonly property bool showWallpapers: search.text.startsWith(`${LauncherMetrics.actionPrefix}wallpaper `)
    readonly property var currentList: showWallpapers ? wallpaperList : appList

    implicitWidth: showWallpapers
        ? Math.max(LauncherMetrics.itemWidth, wallpaperList.implicitWidth)
        : LauncherMetrics.itemWidth
    implicitHeight: showWallpapers
        ? LauncherMetrics.wallpaperHeight
        : Math.min(maxHeight, Math.max(appList.implicitHeight, 48))

    onShowWallpapersChanged: {
        if (showWallpapers)
            LauncherWallpapers.beginSession();
    }

    LauncherAppList {
        id: appList
        anchors.fill: parent
        visible: !root.showWallpapers
        search: root.search
        requestClose: root.requestClose
    }

    LauncherWallpaperList {
        id: wallpaperList
        anchors.fill: parent
        visible: root.showWallpapers
        search: root.search
        requestClose: root.requestClose
        availableWidth: root.availableWidth
    }

    Row {
        id: empty
        visible: root.currentList && root.currentList.count === 0
        spacing: Spacing.normal
        padding: Spacing.large
        anchors.centerIn: parent

        Text {
            text: root.showWallpapers ? "\uf03e" : "\uf002"
            color: Theme.colors.foregroundMuted
            font.family: Typography.fontFamily
            font.pixelSize: Typography.extraLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Spacing.xs

            Text {
                text: root.showWallpapers ? "No wallpapers found" : "No results"
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.title
                font.bold: true
            }

            Text {
                text: root.showWallpapers
                    ? "Add images to ~/Pictures/Wallpapers"
                    : "Try a different search term"
                color: Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
            }
        }
    }
}
