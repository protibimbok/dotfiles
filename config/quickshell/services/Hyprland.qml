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

    function dispatch(cmd: string) {
        HL.Hyprland.dispatch(cmd);
    }

    function switchWorkspace(id: int) {
        HL.Hyprland.dispatch("workspace " + id);
    }
}
