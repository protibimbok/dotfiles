pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    readonly property var active: {
        const list = Mpris.players.values;
        if (!list || list.length === 0)
            return null;
        for (let i = 0; i < list.length; i++) {
            if (list[i] && list[i].isPlaying)
                return list[i];
        }
        for (let i = 0; i < list.length; i++) {
            const p = list[i];
            if (p && p.playbackState === MprisPlaybackState.Paused)
                return p;
        }
        return list[0];
    }

    readonly property bool isActive: active !== null
        && (active.isPlaying || active.playbackState === MprisPlaybackState.Paused)

    readonly property string status: {
        if (!active)
            return "Stopped";
        if (active.isPlaying)
            return "Playing";
        if (active.playbackState === MprisPlaybackState.Paused)
            return "Paused";
        return "Stopped";
    }

    readonly property string title: active ? (active.trackTitle || "") : ""
    readonly property string artist: active ? (active.trackArtist || "") : ""
    readonly property string artUrl: active ? (active.trackArtUrl || "") : ""
    readonly property string playerName: active ? (active.identity || "") : ""

    function _norm(s) {
        return String(s || "").trim().toLowerCase();
    }

    function _classMatch(a, b) {
        const x = root._norm(a);
        const y = root._norm(b);
        if (!x || !y)
            return false;
        if (x === y)
            return true;
        return x.includes(y) || y.includes(x);
    }

    function _toplevelClassKey(c) {
        if (!c)
            return "";
        const appId = c.wayland && c.wayland.appId;
        const ipc = c.lastIpcObject ? c.lastIpcObject["class"] : "";
        return String(appId || ipc || c["class"] || c.initialClass || "").trim();
    }

    function _playerMatchKeys(player) {
        if (!player)
            return [];
        const keys = [];
        const seen = {};
        function add(v) {
            const n = root._norm(v);
            if (!n || seen[n])
                return;
            seen[n] = true;
            keys.push(n);
        }
        add(player.desktopEntry);
        add(player.identity);
        const dbus = player.dbusName || "";
        const parts = dbus.split(".");
        for (let i = parts.length - 1; i >= 0; i--)
            add(parts[i]);
        return keys;
    }

    function _toplevelMatchesPlayer(c, player) {
        const tk = root._norm(root._toplevelClassKey(c));
        if (!tk)
            return false;
        const keys = root._playerMatchKeys(player);
        for (let i = 0; i < keys.length; i++) {
            if (root._classMatch(tk, keys[i]))
                return true;
        }
        const entry = DesktopEntries.heuristicLookup(root._toplevelClassKey(c));
        if (entry) {
            const entryId = root._norm(entry.id || "");
            for (let j = 0; j < keys.length; j++) {
                if (entryId && root._classMatch(entryId, keys[j]))
                    return true;
            }
        }
        for (let k = 0; k < keys.length; k++) {
            const playerEntry = DesktopEntries.heuristicLookup(keys[k]);
            if (!playerEntry)
                continue;
            const wm = root._norm(playerEntry.startupClass || playerEntry.id || "");
            if (wm && root._classMatch(tk, wm))
                return true;
        }
        return false;
    }

    function findPlayerToplevel() {
        if (!active)
            return null;
        const vals = Hyprland.toplevels.values;
        if (!vals)
            return null;
        for (let i = 0; i < vals.length; i++) {
            const c = vals[i];
            if (c && root._toplevelMatchesPlayer(c, active))
                return c;
        }
        return null;
    }

    readonly property var playerToplevel: {
        void Hyprland.toplevels;
        return root.findPlayerToplevel();
    }

    readonly property int playerWorkspaceId: {
        const t = root.playerToplevel;
        return t && t.workspace ? t.workspace.id : -1;
    }

    readonly property string playerIconClass: {
        const t = root.playerToplevel;
        if (t) {
            const ipc = t.lastIpcObject ? (t.lastIpcObject.class || "") : "";
            const key = root._toplevelClassKey(t);
            return String(ipc || key || "").trim();
        }
        if (!active)
            return "";
        if (active.desktopEntry && active.desktopEntry.length > 0)
            return active.desktopEntry;
        const dbus = active.dbusName || "";
        const parts = dbus.split(".");
        const last = parts.length > 0 ? parts[parts.length - 1] : "";
        if (last && last !== "MediaPlayer2")
            return last;
        return active.identity || "";
    }

    function goToPlayerWorkspace() {
        if (root.playerWorkspaceId < 0)
            return;
        Hyprland.switchWorkspace(root.playerWorkspaceId);
    }

    readonly property string displayLine: {
        if (title.length > 0)
            return title;
        if (artist.length > 0)
            return artist;
        if (playerName.length > 0)
            return playerName;
        return "";
    }

    function playPause() {
        if (!active || !active.canTogglePlaying)
            return;
        active.togglePlaying();
    }

    function next() {
        if (active && active.canGoNext)
            active.next();
    }

    function previous() {
        if (active && active.canGoPrevious)
            active.previous();
    }
}
