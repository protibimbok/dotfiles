pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import QtCore

Singleton {
    id: root

    readonly property real minTextContrast: 4.5
    readonly property real minMutedContrast: 4.2
    readonly property real minAccentContrast: 3.0
    readonly property real minBorderContrast: 1.5

    // Bar pills — contrast-safe on elevated surfaces (updated in _updatePillTokens)
    property color pillBackground: colors.surface
    property color pillBackgroundHighlight: colors.surfaceHigh
    property color pillBackgroundHover: colors.surfaceHighest
    property color pillBorder: colors.outline
    property color pillText: colors.foreground
    property color pillTextMuted: colors.foregroundMuted
    property color pillAccent: colors.primary
    property color pillAccentAlt: colors.accent
    property color pillGreen: colors.success
    property color pillRed: colors.error
    property color pillCyan: colors.info
    property color pillTrack: colors.surfaceHigh
    property color pillTextOnHighlight: colors.foreground
    property color pillTextMutedOnHighlight: colors.foregroundMuted
    property color pillAccentOnHighlight: colors.primary

    readonly property color surfaceContainer: colors.surface
    readonly property color surfaceContainerHigh: colors.surfaceHigh
    readonly property color surfaceContainerHighest: colors.surfaceHighest
    readonly property color outlineVariant: colors.outline
    readonly property color shadow: "#000000"

    property string currentWallpaper: ""
    property string extractedForWallpaper: ""
    property bool colorExtracting: false

    // Ordered swatches for WallpaperPicker (contrast-safe Theme.colors)
    readonly property var wallpaperPalette: [
        { role: "background", color: colors.background, on: colors.foreground },
        { role: "surface", color: colors.surface, on: colors.foreground },
        { role: "foreground", color: colors.foreground, on: colors.background },
        { role: "primary", color: colors.primary, on: colors.surface },
        { role: "accent", color: colors.accent, on: colors.surface },
        { role: "success", color: colors.success, on: colors.surface },
        { role: "warning", color: colors.warning, on: colors.surface },
        { role: "error", color: colors.error, on: colors.surface },
        { role: "info", color: colors.info, on: colors.surface }
    ]

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
        property color background: "#1a1b26"
        property color surface: "#24283b"
        property color surfaceHigh: "#414868"
        property color surfaceHighest: "#565f89"
        property color foreground: "#c0caf5"
        property color foregroundMuted: "#565f89"
        property color primary: "#7aa2f7"
        property color accent: "#bb9af7"
        property color outline: "#3b4261"
        property color success: "#9ece6a"
        property color warning: "#e0af68"
        property color error: "#f7768e"
        property color info: "#7dcfff"

        readonly property color bg: background
        readonly property color bg1: surface
        readonly property color bg2: surfaceHigh
        readonly property color text: foreground
        readonly property color textMuted: foregroundMuted
        readonly property color accentAlt: accent
        readonly property color border: outline
        readonly property color green: success
        readonly property color yellow: warning
        readonly property color red: error
        readonly property color cyan: info
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
        if (t.length === 0) {
            root.colorExtracting = false;
            return;
        }
        try {
            let data = JSON.parse(t);
            root._applyWalPalette(data);
        } catch (e) {
            console.warn("Theme: failed to parse wal colors:", e);
        }
        root.colorExtracting = false;
    }

    function _applyWalPalette(data: var) {
        const spec = data.special || {};
        const c = data.colors || {};
        if (!c.color0 && !spec.background)
            return;

        const rawBg = spec.background || c.color0;
        const rawFg = spec.foreground || c.color7 || c.color15;
        const rawMuted = c.color8 || c.color7;
        const dark = _luminance(_toColor(rawBg)) < 0.45;

        const background = _toColor(rawBg);
        const surface = _surfaceStep(background, rawMuted, rawFg, dark, 0.22);
        const surfaceHigh = _surfaceStep(background, rawMuted, rawFg, dark, 0.42);
        const surfaceHighest = _surfaceStep(background, rawMuted, rawFg, dark, 0.58);

        const foreground = _textOn(surface, _toColor(rawFg), background);
        const foregroundMuted = _textOnMuted(surface, _toColor(rawMuted), foreground, minMutedContrast);

        const primary = _pickAccent(surface, [
            c.color4, c.color5, c.color6, c.color3, c.color2, c.color1
        ], foreground);
        const accent = _pickAccent(surface, [
            c.color5, c.color6, c.color4, c.color3
        ], primary);

        const outline = _outlineOn(surface, _mix(
            surface,
            _mix(surface, foreground, 0.35),
            dark ? 0.55 : 0.45
        ));

        colors.background = background;
        colors.surface = surface;
        colors.surfaceHigh = surfaceHigh;
        colors.surfaceHighest = surfaceHighest;
        colors.foreground = foreground;
        colors.foregroundMuted = foregroundMuted;
        colors.primary = primary;
        colors.accent = accent;
        colors.outline = outline;
        colors.success = _accentOn(surface, _toColor(c.color2), foreground);
        colors.warning = _accentOn(surface, _toColor(c.color3), foreground);
        colors.error = _accentOn(surface, _toColor(c.color1), foreground);
        colors.info = _accentOn(surface, _toColor(c.color6), foreground);

        const wall = data.wallpaper;
        if (wall && String(wall).length > 0)
            root.extractedForWallpaper = _normalizeLocalPath(String(wall));

        root._updatePillTokens();
    }

    function extractColorsFromWallpaper(path: string) {
        const p = _normalizeLocalPath(path);
        if (!p || p.length === 0)
            return;
        colorExtracting = true;
        walExtractProc.wallPath = p;
        walExtractProc.running = true;
    }

    Component.onCompleted: {
        if (colorFile.text().length > 0)
            _parseColors();
        else
            _updatePillTokens();
    }

    function _updatePillTokens() {
        const bg = colors.background;
        const elevated = colors.surface;
        const raised = colors.surfaceHigh;
        const peak = colors.surfaceHighest;

        pillBackground = elevated;
        pillBackgroundHighlight = raised;
        pillBackgroundHover = _mix(elevated, peak, 0.45);
        pillBorder = colors.outline;
        pillText = _textOn(elevated, colors.foreground, bg);
        pillTextMuted = _textOnMuted(elevated, colors.foregroundMuted, pillText, minMutedContrast);
        pillAccent = _accentOn(elevated, colors.primary, pillText);
        pillAccentAlt = _accentOn(elevated, colors.accent, pillText);
        pillGreen = _accentOn(elevated, colors.success, pillText);
        pillRed = _accentOn(elevated, colors.error, pillText);
        pillCyan = _accentOn(elevated, colors.info, pillText);
        pillTrack = _mix(elevated, pillTextMuted, 0.28);
        pillTextOnHighlight = _textOn(raised, colors.foreground, bg);
        pillTextMutedOnHighlight = _textOnMuted(raised, colors.foregroundMuted, pillTextOnHighlight, minMutedContrast);
        pillAccentOnHighlight = _accentOn(raised, colors.primary, pillTextOnHighlight);
    }

    function _surfaceStep(bg: color, mutedRaw: var, fgRaw: var, dark: bool, t: real): color {
        const muted = _toColor(mutedRaw);
        const fg = _toColor(fgRaw);
        let step = _mix(bg, muted, t);
        if (dark) {
            if (_luminance(step) <= _luminance(bg) + 0.02)
                step = _mix(bg, fg, t * 0.12);
        } else if (_luminance(step) >= _luminance(bg) - 0.02) {
            step = _mix(bg, muted, t * 0.85);
        }
        return step;
    }

    function _pickAccent(bg: color, candidates: var, fallback: color): color {
        for (let i = 0; i < candidates.length; i++) {
            const c = _toColor(candidates[i]);
            if (_contrast(bg, c) >= minAccentContrast)
                return c;
        }
        return fallback;
    }

    function _outlineOn(bg: color, preferred: color): color {
        if (_contrast(bg, preferred) >= minBorderContrast)
            return preferred;
        const fg = colors.foreground;
        const alt = _mix(bg, fg, _luminance(bg) > 0.45 ? 0.22 : 0.35);
        if (_contrast(bg, alt) >= minBorderContrast)
            return alt;
        return _luminance(bg) > 0.45 ? "#888888" : "#555555";
    }

    function _toColor(value: var): color {
        if (value === undefined || value === null)
            return colors.foreground;
        if (typeof value === "string")
            return value;
        return value;
    }

    function _channel(c: real): real {
        return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    }

    function _luminance(c: color): real {
        return 0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);
    }

    function _contrast(a: color, b: color): real {
        const l1 = _luminance(a);
        const l2 = _luminance(b);
        const hi = Math.max(l1, l2);
        const lo = Math.min(l1, l2);
        return (hi + 0.05) / (lo + 0.05);
    }

    function _mix(a: color, b: color, t: real): color {
        return Qt.rgba(
            a.r * (1 - t) + b.r * t,
            a.g * (1 - t) + b.g * t,
            a.b * (1 - t) + b.b * t,
            1.0
        );
    }

    function _textOn(bg: color, preferred: color, fallback: color): color {
        if (_contrast(bg, preferred) >= minTextContrast)
            return preferred;
        if (_contrast(bg, fallback) >= minTextContrast)
            return fallback;
        return _luminance(bg) > 0.45 ? "#111111" : "#f4f4f4";
    }

    function _textOnMuted(bg: color, preferred: color, strong: color, minRatio: real): color {
        if (_contrast(bg, preferred) >= minRatio)
            return preferred;
        if (_contrast(bg, strong) >= minRatio)
            return strong;
        return _textOn(bg, strong, strong);
    }

    function _accentOn(bg: color, accent: color, fallback: color): color {
        if (_contrast(bg, accent) >= minAccentContrast)
            return accent;
        return fallback;
    }

    function primaryTint(opacity: real): color {
        return Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, opacity);
    }

    function errorTint(opacity: real): color {
        return Qt.rgba(colors.error.r, colors.error.g, colors.error.b, opacity);
    }

    function surfaceTint(surface: color, opacity: real): color {
        return Qt.rgba(surface.r, surface.g, surface.b, opacity);
    }

    function outlineTint(opacity: real): color {
        return Qt.rgba(colors.outline.r, colors.outline.g, colors.outline.b, opacity);
    }

    function foregroundMutedTint(opacity: real): color {
        return Qt.rgba(colors.foregroundMuted.r, colors.foregroundMuted.g, colors.foregroundMuted.b, opacity);
    }

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
        onExited: root.extractColorsFromWallpaper(wallPath)
    }

    Process {
        id: walExtractProc
        property string wallPath: ""
        command: ["/usr/bin/wal", "-i", wallPath, "-n", "-q"]
        onExited: {
            colorFile.reload();
            root._parseColors();
        }
    }

    Process { id: mkdirProc; command: ["mkdir", "-p", root._cacheDir] }

    Process {
        id: saveWallProc
        property string content: ""
        command: ["/usr/bin/bash", "-c", "printf '%s' " + JSON.stringify(content) + " > " + JSON.stringify(root._wallpaperCache)]
    }

    function applyWallpaper(path: string) {
        const p = _normalizeLocalPath(path);
        if (!p || p.length === 0)
            return;
        currentWallpaper = p;
        colorExtracting = true;
        mkdirProc.running = true;
        saveWallProc.content = p;
        saveWallProc.running = true;
        wallpaperAwwwProc.wallPath = p;
        awwwDaemonWarmProc.running = true;
    }
}
