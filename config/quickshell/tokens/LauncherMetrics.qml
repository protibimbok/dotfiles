pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property int itemWidth: 600
    readonly property int itemHeight: 57
    readonly property int wallpaperWidth: 280
    readonly property int wallpaperHeight: 200
    readonly property int maxShown: 7
    readonly property int maxWallpapers: 9
    readonly property string actionPrefix: ">"
}
