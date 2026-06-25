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
        return key.length > 0 && key !== "org.quickshell";
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
