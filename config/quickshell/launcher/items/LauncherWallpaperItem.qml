import QtQuick
import Quickshell
import qs.components
import qs.launcher.services
import qs.theme
import qs.tokens

Item {
    id: root

    required property var modelData
    required property int index
    required property var requestClose

    readonly property string path: modelData?.path ?? ""
    readonly property real thumbWidth: LauncherMetrics.wallpaperWidth * 0.8

    function _normalizeLocalPath(p) {
        if (!p || p.length === 0)
            return p;
        let s = String(p).replace(/\\/g, "/").trim();
        if (!s.startsWith("file://"))
            return s;
        s = s.substring("file://".length);
        if (s.startsWith("localhost/"))
            s = "/" + s.substring("localhost/".length);
        else if (!s.startsWith("/") && !/^[A-Za-z]:/.test(s))
            s = "/" + s;
        return s;
    }

    function _fileUrl(path) {
        if (!path || path.length === 0)
            return "";
        const norm = _normalizeLocalPath(path).replace(/\\/g, "/");
        const enc = norm.split("/").map(s => encodeURIComponent(s)).join("/");
        return "file://" + enc;
    }

    width: thumbWidth + Spacing.larger * 2
    height: ListView.view ? ListView.view.height : LauncherMetrics.wallpaperHeight
    scale: ListView.isCurrentItem ? 1.12 : 0.88
    z: ListView.isCurrentItem ? 1 : 0
    transformOrigin: Item.Center

    Behavior on scale {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    HoverHandler {
        onHoveredChanged: {
            if (hovered && root.ListView.view)
                root.ListView.view.currentIndex = root.index;
        }
    }

    TapHandler {
        onTapped: {
            if (root.path.length > 0)
                LauncherWallpapers.setWallpaper(root.path);
            root.requestClose();
        }
    }

    Elevation {
        anchors.fill: thumb
        radius: thumb.radius
        opacity: root.ListView.isCurrentItem ? 1 : 0
        level: 4
        Behavior on opacity {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        id: thumb
        anchors.centerIn: parent
        width: thumbWidth
        height: width / 16 * 9
        radius: Rounding.normal
        clip: true
        color: Theme.colors.surface
        border.color: root.ListView.isCurrentItem ? Theme.primaryTint(0.5) : Theme.colors.outline
        border.width: root.ListView.isCurrentItem ? 2 : 1
        Behavior on border.color {
            NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
        }

        MaterialIcon {
            anchors.centerIn: parent
            icon: "image"
            font.pixelSize: Typography.extraLarge
            visible: wallpaperImage.status !== Image.Ready
        }

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.path ? root._fileUrl(root.path) : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: !root.ListView.view?.moving
        }
    }
}
