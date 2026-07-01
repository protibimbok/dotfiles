import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.theme
import qs.tokens
import qs.services

// Centered, under-the-bar unread-notifications dropdown — same surface and entrance
// animation as the toasts, but centered beneath the bar's clock badge and holding
// the full unread list with a "Clear all" action. It is its own layer-shell window
// (not embedded in the bar) so opening it never resizes the bar surface — which is
// what made the whole bar flicker. Shown while the clock badge (via
// NotificationsPanelState) or the panel itself is hovered; a short grace timer
// bridges the cursor gap between the bar window and this one. The card is
// (re)created by a Loader on each open so its slide/fade entrance replays.
PanelWindow {
    id: root

    // Dedicated namespace so the compositor blurs only this (like the toasts).
    WlrLayershell.namespace: "quickshell-notifications-panel"

    readonly property int _edgeRoom: Metrics.toastRadius

    readonly property var unreadNotifications: {
        let out = [];
        for (let i = 0; i < Notifications.notifications.length; i++) {
            if (!Notifications.notifications[i].read)
                out.push(Notifications.notifications[i]);
        }
        return out;
    }

    readonly property bool open: Notifications.unreadCount > 0
        && (NotificationsPanelState.iconHovered || root.panelHovered || hideTimer.running)
    property bool panelHovered: false

    // Anchored to the top edge only, so the compositor centers the surface
    // horizontally — lining it up with the bar's centered clock badge.
    anchors.top: true
    // Bar's exclusive zone already offsets top-anchored layers by its height, so the
    // card sits flush under the bar and its top coves reach up to meet it.
    margins.top: 0

    exclusiveZone: 0
    color: "transparent"
    // Stay mapped through the fade-out so hiding is a smooth dissolve, not a hard
    // vanish (and brief hover toggles don't destroy/recreate the card).
    visible: root.open || loader.opacity > 0.01

    // Extra room on both sides for the card's top coves, which bow past its body.
    implicitWidth: Metrics.toastColumnWidth + root._edgeRoom * 2
    implicitHeight: Math.max(1, loader.implicitHeight)

    // Let the toasts fall silent while the panel is already showing the unread list.
    onOpenChanged: NotificationsPanelState.panelOpen = root.open

    Timer {
        id: hideTimer
        interval: Durations.panelHoverHide
    }

    function _refreshHide() {
        if (NotificationsPanelState.iconHovered || root.panelHovered)
            hideTimer.stop();
        else
            hideTimer.restart();
    }

    Connections {
        target: NotificationsPanelState
        function onIconHoveredChanged() { root._refreshHide(); }
    }

    Loader {
        id: loader
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        width: Metrics.toastColumnWidth
        active: root.open || opacity > 0.01
        opacity: root.open ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Durations.fade; easing.type: Easing.OutCubic } }

        // Pause the hide timer while the cursor is over the panel.
        HoverHandler {
            onHoveredChanged: {
                root.panelHovered = hovered;
                root._refreshHide();
            }
        }

        sourceComponent: FloatingCardCenter {
            width: loader.width

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Spacing.md

                RowLayout {
                    width: parent.width
                    spacing: Spacing.sm

                    Text {
                        Layout.fillWidth: true
                        text: "Notifications"
                        color: Theme.pillTextMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.label
                        font.bold: true
                    }

                    Text {
                        visible: root.unreadNotifications.length > 0
                        text: "Clear all"
                        color: clearHover.hovered ? Theme.pillText : Theme.pillTextMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.bodySm
                        font.weight: Font.Medium

                        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Notifications.clearAll() }

                        Behavior on color { ColorAnimation { duration: Durations.colorTransition } }
                    }
                }

                Flickable {
                    width: parent.width
                    height: Math.min(contentHeight, Metrics.notificationPanelMaxHeight)
                    contentHeight: notifColumn.height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    Column {
                        id: notifColumn
                        width: parent.width
                        spacing: Spacing.md

                        Repeater {
                            model: root.unreadNotifications

                            NotificationPanelItem {
                                width: notifColumn.width
                            }
                        }
                    }
                }
            }
        }
    }
}
