pragma Singleton
import Quickshell
import Quickshell.Hyprland as HL
import QtQuick

Singleton {
    id: root

    readonly property var workspaces: HL.Hyprland.workspaces
    readonly property var toplevels: HL.Hyprland.toplevels
    readonly property var focusedWorkspace: HL.Hyprland.focusedWorkspace
    readonly property var focusedMonitor: HL.Hyprland.focusedMonitor
    readonly property var activeToplevel: HL.Hyprland.activeToplevel

    function isBarToplevel(c) {
        if (!c || !c.workspace)
            return false;

        const appId = c.wayland && c.wayland.appId;
        const rawClass = appId
            || (c.lastIpcObject ? c.lastIpcObject["class"] : "")
            || c["class"]
            || c.initialClass
            || "";
        const key = String(rawClass).trim();
        if (key === "org.quickshell" || key === "quickshell")
            return false;
        return key.length > 0;
    }

    function toplevelClassKey(c) {
        if (!c)
            return "";
        const appId = c.wayland && c.wayland.appId;
        const ipc = c.lastIpcObject ? c.lastIpcObject["class"] : "";
        return String(appId || ipc || c["class"] || c.initialClass || "").trim();
    }

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

    function _notificationMatchKeys(notifObj) {
        if (!notifObj)
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
        add(notifObj.desktopEntry);
        add(notifObj.appName);
        add(notifObj.appIcon);
        return keys;
    }

    function findToplevelForNotification(notifObj) {
        const vals = root.toplevels.values;
        if (!vals || !notifObj)
            return null;

        const keys = root._notificationMatchKeys(notifObj);
        if (!keys.length)
            return null;

        for (let i = 0; i < vals.length; i++) {
            const c = vals[i];
            if (!c || !c.workspace || !root.isBarToplevel(c))
                continue;

            const tk = root._norm(root.toplevelClassKey(c));
            for (let j = 0; j < keys.length; j++) {
                if (root._classMatch(tk, keys[j]))
                    return c;
            }

            const entry = DesktopEntries.heuristicLookup(root.toplevelClassKey(c));
            if (entry) {
                const entryId = root._norm(entry.id || "");
                for (let k = 0; k < keys.length; k++) {
                    if (entryId && root._classMatch(entryId, keys[k]))
                        return c;
                }
            }

            for (let k = 0; k < keys.length; k++) {
                const notifEntry = DesktopEntries.heuristicLookup(keys[k]);
                if (!notifEntry)
                    continue;
                const wm = root._norm(notifEntry.startupClass || notifEntry.id || "");
                if (wm && root._classMatch(tk, wm))
                    return c;
            }
        }
        return null;
    }

    function focusNotificationSender(notifObj) {
        const t = root.findToplevelForNotification(notifObj);
        if (!t || !t.address)
            return false;
        if (t.workspace)
            root.dispatch("workspace " + t.workspace.id);
        root.dispatch("focuswindow address:" + t.address);
        return true;
    }

    readonly property bool plainBarMode: {
        void toplevels;
        void focusedWorkspace;
        if (!focusedWorkspace)
            return false;

        const vals = toplevels.values;
        if (!vals)
            return false;

        for (let i = 0; i < vals.length; i++) {
            const c = vals[i];
            if (!c.workspace || c.workspace.id !== focusedWorkspace.id)
                continue;
            if (!isBarToplevel(c))
                continue;

            return true
        }
        return false;
    }

    // Under a NATIVE LUA Hyprland config, the IPC `dispatch` argument is no longer
    // a conf-style dispatcher string — it is evaluated as Lua (`hl.dispatch(<arg>)`).
    // So "workspace 3" / "focuswindow address:0x.." are Lua syntax errors and do
    // nothing. Translate the dispatchers this shell uses into hl.dsp.* expressions.
    // (Args already starting with "hl." are passed through untouched; an unrecognized
    // dispatcher is sent as-is.) Verified forms:
    //   workspace N            -> hl.dsp.focus({workspace="N"})
    //   focuswindow address:X  -> hl.dsp.focus({window="address:X"})
    function _toLua(cmd: string): string {
        if (cmd.startsWith("hl."))
            return cmd;
        let m = cmd.match(/^workspace\s+(.+)$/);
        if (m)
            return 'hl.dsp.focus({workspace="' + m[1].trim() + '"})';
        m = cmd.match(/^focuswindow\s+address:(.+)$/);
        if (m)
            return 'hl.dsp.focus({window="address:' + m[1].trim() + '"})';
        return cmd;
    }

    function dispatch(cmd: string) {
        HL.Hyprland.dispatch(root._toLua(cmd));
    }

    function switchWorkspace(id: int) {
        root.dispatch("workspace " + id);
    }
}
