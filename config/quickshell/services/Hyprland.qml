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

    readonly property bool singleWindowBarMode: {
        void toplevels;
        void focusedWorkspace;
        if (!focusedWorkspace)
            return false;

        const vals = toplevels.values;
        if (!vals)
            return false;

        let count = 0;
        for (let i = 0; i < vals.length; i++) {
            const c = vals[i];
            if (!c.workspace || c.workspace.id !== focusedWorkspace.id)
                continue;
            if (!isBarToplevel(c))
                continue;

            count++;
            if (count > 1)
                return false;
        }
        return count === 1;
    }

    function dispatch(cmd: string) {
        HL.Hyprland.dispatch(cmd);
    }

    function switchWorkspace(id: int) {
        HL.Hyprland.dispatch("workspace " + id);
    }
}
