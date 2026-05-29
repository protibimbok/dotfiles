pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.utils
import qs.tokens

Singleton {
    id: root

    property var list: []
    property int listVersion: 0
    property string wallpaperDir: PathUtils.home() + "/Pictures/Wallpapers"
    property bool committed: false
    property string pendingPreviewPath: ""

    function transformSearch(search: string): string {
        const prefix = `${LauncherMetrics.actionPrefix}wallpaper `;
        return search.startsWith(prefix) ? search.slice(prefix.length) : search;
    }

    function query(search: string): var {
        const _ = listVersion;
        return Searcher.query(list, search, {
            key: "relativePath",
            transformSearch: transformSearch
        });
    }

    function reload(): void {
        scanProc.running = true;
    }

    function beginSession(): void {
        committed = false;
        reload();
    }

    function preview(path: string): void {
        if (!path || path.length === 0)
            return;
        pendingPreviewPath = path;
        previewTimer.restart();
    }

    function stopPreview(): void {
        previewTimer.stop();
        pendingPreviewPath = "";
        if (committed)
            return;
        Theme.stopPreview();
    }

    function setWallpaper(path: string): void {
        if (!path || path.length === 0)
            return;
        previewTimer.stop();
        pendingPreviewPath = "";
        committed = true;
        Theme.applyWallpaper(path);
    }

    function endSession(): void {
        previewTimer.stop();
        pendingPreviewPath = "";
        if (committed) {
            committed = false;
            return;
        }
        Theme.stopPreview();
    }

    function applyRandom(): void {
        if (list.length === 0)
            reload();
        if (list.length === 0)
            return;
        const pick = list[Math.floor(Math.random() * list.length)];
        Theme.applyWallpaper(pick.path);
    }

    Component.onCompleted: reload()

    Timer {
        id: previewTimer
        interval: 180
        repeat: false
        onTriggered: {
            if (root.committed || root.pendingPreviewPath.length === 0)
                return;
            Theme.previewWallpaper(root.pendingPreviewPath);
        }
    }

    Process {
        id: scanProc
        command: [
            "/usr/bin/find",
            root.wallpaperDir,
            "-maxdepth", "2",
            "-type", "f",
            "(",
            "-iname", "*.jpg",
            "-o", "-iname", "*.jpeg",
            "-o", "-iname", "*.png",
            "-o", "-iname", "*.webp",
            "-o", "-iname", "*.gif",
            ")"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n").filter(l => l.trim().length > 0).sort();
                const base = root.wallpaperDir.endsWith("/") ? root.wallpaperDir : root.wallpaperDir + "/";
                root.list = lines.map(p => ({
                    path: p,
                    relativePath: p.startsWith(base) ? p.slice(base.length) : p.split("/").pop()
                }));
                root.listVersion++;
            }
        }
    }
}
