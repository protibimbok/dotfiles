import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.bar
import qs.launcher
import qs.notifications
import qs.quicksettings
import qs.wallpaper
import qs.theme
import qs.services
import qs.osd
import qs.toasts
import qs.session

ShellRoot {
    id: shell

    property bool launcherVisible: false
    property bool notifPanelVisible: false
    property bool quickSettingsVisible: false
    /// quick-settings inner view: main grid vs full-panel wifi / bluetooth
    property string qsSubview: "main"
    property bool wallpaperPickerVisible: false
    property bool sessionVisible: false

    property bool anyPanelOpen: launcherVisible || notifPanelVisible || quickSettingsVisible
        || wallpaperPickerVisible || sessionVisible

    Connections {
        target: shell
        function onQuickSettingsVisibleChanged() {
            if (!shell.quickSettingsVisible)
                shell.qsSubview = "main";
        }
    }

    // Bar — per screen, with auto-hide on hover
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            implicitHeight: 44
            exclusiveZone: 44
            color: "transparent"

            Item {
                id: barContainer
                anchors.fill: parent

                property bool _hoverActive: true
                property bool barShown: _hoverActive || shell.anyPanelOpen

                HoverHandler {
                    id: barHover
                    onHoveredChanged: {
                        if (hovered) {
                            hideTimer.stop();
                            barContainer._hoverActive = true;
                        } else if (!shell.anyPanelOpen) {
                            hideTimer.restart();
                        }
                    }
                }

                Timer {
                    id: hideTimer
                    interval: 800
                    onTriggered: {
                        if (!barHover.hovered && !shell.anyPanelOpen)
                            barContainer._hoverActive = false;
                    }
                }

                Connections {
                    target: shell
                    function onAnyPanelOpenChanged() {
                        if (shell.anyPanelOpen) {
                            hideTimer.stop();
                        } else if (!barHover.hovered) {
                            hideTimer.restart();
                        }
                    }
                }

                Bar {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 44
                    y: barContainer.barShown ? 0 : -44
                    shellRoot: shell

                    Behavior on y {
                        NumberAnimation { duration: 280; easing.type: Easing.OutExpo }
                    }
                }
            }
        }
    }

    // Launcher — real floating toplevel (not layer-shell panel)
    FloatingWindow {
        id: launcherWindow
        screen: Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
        title: "App launcher"
        visible: shell.launcherVisible
        color: "transparent"

        readonly property int _launcherW: screen
            ? Math.min(640, Math.max(400, screen.width - 96))
            : 640
        readonly property int _launcherH: 480

        implicitWidth: _launcherW
        implicitHeight: _launcherH
        // Position: Quickshell FloatingWindow has no writable x/y; use Hyprland `center` on this title.

        onClosed: shell.launcherVisible = false

        AppLauncher {
            anchors.fill: parent
            onClose: shell.launcherVisible = false
        }
    }

    // Notification panel
    PanelWindow {
        id: notifWindow
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true
        visible: shell.notifPanelVisible
        color: "transparent"

        NotificationPanel {
            anchors.fill: parent
            panelOpen: shell.notifPanelVisible
            onClose: shell.notifPanelVisible = false
        }
    }

    // Quick settings
    PanelWindow {
        id: qsWindow
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true
        visible: shell.quickSettingsVisible
        color: "transparent"

        QuickSettings {
            anchors.fill: parent
            shellRoot: shell
            onClose: shell.quickSettingsVisible = false
        }
    }

    // Wallpaper picker
    PanelWindow {
        id: wallpaperWindow
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true
        visible: shell.wallpaperPickerVisible
        color: "transparent"

        WallpaperPicker {
            anchors.fill: parent
            onClose: shell.wallpaperPickerVisible = false
        }
    }

    // Session / power menu
    PanelWindow {
        id: sessionWindow
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true
        visible: shell.sessionVisible
        color: "transparent"

        SessionScreen {
            anchors.fill: parent
            onClose: shell.sessionVisible = false
        }
    }

    // OSD — bottom-center, only present while actively showing
    // Conditional visibility prevents this transparent surface from
    // intercepting pointer events in the bottom 180px when not in use.
    PanelWindow {
        id: osdWindow
        visible: osdItem.windowVisible
        anchors { bottom: true; left: true; right: true }
        implicitHeight: 180
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        OSD { id: osdItem }
    }

    // Toasts — full-width top panel, content anchored to right
    // Only present on the compositor when toasts are active; otherwise the
    // transparent surface would swallow all pointer events over the bar.
    PanelWindow {
        id: toastWindow
        visible: toastMgr.count > 0
        anchors { top: true; left: true; right: true }
        implicitHeight: 400
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        ToastManager { id: toastMgr }
    }

    // Global shortcuts
    // hyprland.conf: bind = SUPER, SPACE, global, quickshell:toggle-launcher
    GlobalShortcut {
        appid: "quickshell"
        name: "toggle-launcher"
        description: "Toggle application launcher"
        onPressed: shell.launcherVisible = !shell.launcherVisible
    }

    // hyprland.conf: bind = SUPER, ESCAPE, global, quickshell:toggle-session
    GlobalShortcut {
        appid: "quickshell"
        name: "toggle-session"
        description: "Toggle session/power menu"
        onPressed: shell.sessionVisible = !shell.sessionVisible
    }
}
