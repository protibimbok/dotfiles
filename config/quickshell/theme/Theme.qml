pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtCore

Singleton {
    id: root

    readonly property real barOpacity: 0.90

    property string currentWallpaper: ""

    function _normalizeLocalPath(p: string): string {
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

    function _homeLocal(): string {
        let h = StandardPaths.writableLocation(StandardPaths.HomeLocation);
        let s = (typeof h === "string") ? h : (h && h.toString ? h.toString() : String(h));
        return _normalizeLocalPath(s);
    }

    readonly property string _cacheDir: _homeLocal() + "/.cache/quickshell"
    readonly property string _wallpaperCache: _cacheDir + "/wallpaper.txt"

    FileView {
        id: savedWallFile
        path: root._wallpaperCache
        preload: true
        onFileChanged: {
            let p = text().trim();
            if (p.length > 0) root.currentWallpaper = p;
        }
    }

    property var colors: QtObject {
        property color bg: "#1a1b26"
        property color bg1: "#24283b"
        property color bg2: "#414868"
        property color surface: "#292e42"
        property color border: "#3b4261"
        property color text: "#c0caf5"
        property color textMuted: "#565f89"
        property color accent: "#7aa2f7"
        property color accentAlt: "#bb9af7"
        property color green: "#9ece6a"
        property color yellow: "#e0af68"
        property color red: "#f7768e"
        property color cyan: "#7dcfff"
    }

    FileView {
        id: colorFile
        path: root._homeLocal() + "/.cache/wal/colors.json"
        preload: true
        watchChanges: true
        onFileChanged: root._parseColors()
    }

    function _parseColors() {
        let t = colorFile.text();
        if (t.length === 0) return;
        try {
            let data = JSON.parse(t);
            let c = data.colors;
            if (!c) return;
            let bg0 = c.color0 || colors.bg;
            let col8 = c.color8 || colors.bg1;
            colors.bg = bg0;
            colors.bg1 = _blend(bg0, col8, 0.5);
            colors.bg2 = _blend(bg0, col8, 0.75);
            colors.surface = _blend(bg0, col8, 0.3);
            colors.border = _blend(col8, c.color7 || colors.text, 0.3);
            colors.text = c.color7 || colors.text;
            colors.textMuted = c.color8 || colors.textMuted;
            colors.accent = c.color4 || colors.accent;
            colors.accentAlt = c.color5 || colors.accentAlt;
            colors.green = c.color2 || colors.green;
            colors.yellow = c.color3 || colors.yellow;
            colors.red = c.color1 || colors.red;
            colors.cyan = c.color6 || colors.cyan;
        } catch (e) {
            console.warn("Theme: failed to parse wal colors:", e);
        }
    }

    function _blend(a: string, b: string, t: real): string {
        let ca = _hexToRgb(a), cb = _hexToRgb(b);
        if (!ca || !cb) return a;
        let r = Math.round(ca.r * (1 - t) + cb.r * t);
        let g = Math.round(ca.g * (1 - t) + cb.g * t);
        let bl = Math.round(ca.b * (1 - t) + cb.b * t);
        return "#" + ((1 << 24) + (r << 16) + (g << 8) + bl).toString(16).slice(1);
    }

    function _hexToRgb(hex: string): var {
        let h = hex.replace("#", "");
        if (h.length === 3) h = h[0]+h[0]+h[1]+h[1]+h[2]+h[2];
        if (h.length !== 6) return null;
        return {
            r: parseInt(h.substring(0, 2), 16),
            g: parseInt(h.substring(2, 4), 16),
            b: parseInt(h.substring(4, 6), 16)
        };
    }

    // Minimal env breaks `bash -c` (awww/wal not in PATH). Use argv + absolute tools.
    Process {
        id: awwwDaemonWarmProc
        command: ["/usr/bin/bash", "-c",
            "export PATH=/usr/bin:/bin:/usr/local/bin; " +
            "awww-daemon 2>/dev/null & sleep 0.2"]
        onExited: wallpaperAwwwProc.running = true
    }

    Process {
        id: wallpaperAwwwProc
        property string wallPath: ""
        command: [
            "/usr/bin/awww", "img", wallPath,
            "--transition-type", "grow",
            "--transition-duration", "1.5",
            "--transition-fps", "60"
        ]
        onExited: {
            walAfterWallProc.wallPath = wallPath;
            walAfterWallProc.running = true;
        }
    }

    Process {
        id: walAfterWallProc
        property string wallPath: ""
        command: ["/usr/bin/wal", "-i", wallPath, "-n", "-q"]
        onExited: colorFile.reload()
    }

    Process { id: mkdirProc; command: ["mkdir", "-p", root._cacheDir] }

    Process {
        id: saveWallProc
        property string content: ""
        command: ["/usr/bin/bash", "-c", "printf '%s' " + JSON.stringify(content) + " > " + JSON.stringify(root._wallpaperCache)]
    }

    function applyWallpaper(path: string) {
        const p = _normalizeLocalPath(path);
        currentWallpaper = p;
        mkdirProc.running = true;
        saveWallProc.content = p;
        saveWallProc.running = true;
        wallpaperAwwwProc.wallPath = p;
        awwwDaemonWarmProc.running = true;
    }
}
