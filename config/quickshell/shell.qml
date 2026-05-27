import Quickshell
import Quickshell.Hyprland
import QtQuick
import qs.bar
import qs.launcher
import qs.notifications
import qs.quicksettings
import qs.theme
import qs.services
import qs.osd
import qs.toasts
import qs.session
import qs.tokens

ShellRoot {
    id: shell

    property bool launcherVisible: false
    property bool notifPanelVisible: false
    property bool notifTriggerHovered: false
    property bool notifPanelHovered: false
    property bool quickSettingsVisible: false
    property bool qsTriggerHovered: false
    property bool qsPanelHovered: false
    /// quick-settings inner view: main grid vs full-panel wifi / bluetooth
    property string qsSubview: "main"
    property bool sessionVisible: false

    property bool anyPanelOpen: launcherVisible || notifPanelVisible || quickSettingsVisible
        || sessionVisible

    Connections {
        target: shell
        function onQuickSettingsVisibleChanged() {
            if (!shell.quickSettingsVisible) {
                shell.qsSubview = "main"
                shell.qsPanelHovered = false
            }
        }
    }

    Connections {
        target: shell
        function onNotifPanelVisibleChanged() {
            if (!shell.notifPanelVisible)
                shell.notifPanelHovered = false
        }
    }

    Timer {
        id: qsHideTimer
        interval: Durations.panelHoverHide
        onTriggered: {
            if (!shell.qsTriggerHovered && !shell.qsPanelHovered)
                shell.quickSettingsVisible = false
        }
    }

    Timer {
        id: notifHideTimer
        interval: Durations.panelHoverHide
        onTriggered: {
            if (!shell.notifTriggerHovered && !shell.notifPanelHovered)
                shell.notifPanelVisible = false
        }
    }

    function updateQuickSettingsHover() {
        if (qsTriggerHovered || qsPanelHovered) {
            qsHideTimer.stop()
            quickSettingsVisible = true
        } else {
            qsHideTimer.restart()
        }
    }

    function updateNotifHover() {
        if (notifTriggerHovered || notifPanelHovered) {
            notifHideTimer.stop()
            notifPanelVisible = true
        } else {
            notifHideTimer.restart()
        }
    }

    Connections {
        target: shell
        function onQsTriggerHoveredChanged() { shell.updateQuickSettingsHover() }
        function onQsPanelHoveredChanged() { shell.updateQuickSettingsHover() }
    }

    Connections {
        target: shell
        function onNotifTriggerHoveredChanged() { shell.updateNotifHover() }
        function onNotifPanelHoveredChanged() { shell.updateNotifHover() }
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
            implicitHeight: Metrics.barHeight
            exclusiveZone: Metrics.barHeight
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
                    interval: Durations.barHideDelay
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
                    height: Metrics.barHeight
                    y: barContainer.barShown ? 0 : Metrics.barHideOffset
                    shellRoot: shell

                    Behavior on y {
                        NumberAnimation { duration: Durations.barSlide; easing.type: Easing.OutExpo }
                    }
                }
            }
        }
    }

    // Launcher — bottom drawer overlay
    PanelWindow {
        id: launcherWindow
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        aboveWindows: true
        focusable: true
        visible: shell.launcherVisible
        color: "transparent"

        MouseArea {
            anchors.fill: parent
            enabled: shell.launcherVisible
            onClicked: shell.launcherVisible = false
        }

        Item {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48

            LauncherWrapper {
                id: launcherRoot
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                active: shell.launcherVisible
                onClose: shell.launcherVisible = false
            }
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
        // Bar strip passes pointer events so hover isn't stolen on open.
        mask: Region { item: notifClickMask }

        Item {
            id: notifClickMask
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.topMargin: Spacing.panelTopMargin
        }

        NotificationPanel {
            anchors.fill: parent
            shellRoot: shell
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
        // Bar strip passes pointer events so status-icon hover is not stolen on open.
        mask: Region { item: qsClickMask }

        Item {
            id: qsClickMask
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.top: parent.top
            anchors.topMargin: Spacing.panelTopMargin
        }

        QuickSettings {
            anchors.fill: parent
            shellRoot: shell
            onClose: shell.quickSettingsVisible = false
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
        implicitHeight: Metrics.osdWindowHeight
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
        implicitHeight: Metrics.toastWindowHeight
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
