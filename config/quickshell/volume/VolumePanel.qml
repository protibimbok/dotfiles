import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.tokens
import qs.services

// Flush-right, under-the-bar volume panel — same surface + entrance animation as
// the notification toasts, but holding one slider per output device. Shown while
// the bar's audio icon (via VolumePanelState) or the panel itself is hovered; a
// short grace timer bridges the cursor gap between the two windows. The card is
// (re)created by a Loader on each open so its slide/fade entrance replays.
PanelWindow {
    id: root

    // Dedicated namespace so the compositor blurs only this (like the toasts).
    WlrLayershell.namespace: "quickshell-volume"

    readonly property int _edgeRoom: Metrics.toastRadius
    readonly property bool open: VolumePanelState.iconHovered || root.panelHovered || hideTimer.running
    property bool panelHovered: false

    anchors {
        top: true
        right: true
    }
    margins {
        // The bar's exclusive zone already offsets top-anchored layers by its
        // height, so this is just the small gap under the bar. The card's top-left
        // concave fillet then reaches up to meet the bar.
        top: 0
        right: 0
    }

    exclusiveZone: 0
    color: "transparent"
    // Stay mapped through the slide-out so the card can retract behind the bar
    // (and brief hover toggles don't destroy/recreate the card).
    visible: root.open || slideTimer.running

    // Extra room on the left and bottom for the card's coves, which bow past its
    // body (top-left flares left, bottom-right drips down). The card itself stays
    // flush against the top (the bar) and the right (the screen edge).
    implicitWidth: Metrics.toastColumnWidth + root._edgeRoom
    implicitHeight: Math.max(1, loader.implicitHeight + root._edgeRoom)

    Timer {
        id: hideTimer
        interval: Durations.panelHoverHide
    }

    // Keeps the window mapped while the card slides back up on close.
    Timer {
        id: slideTimer
        interval: Durations.toastSlide
    }
    onOpenChanged: if (!open) slideTimer.restart()

    function _refreshHide() {
        if (VolumePanelState.iconHovered || root.panelHovered)
            hideTimer.stop();
        else
            hideTimer.restart();
    }

    Connections {
        target: VolumePanelState
        function onIconHoveredChanged() { root._refreshHide(); }
    }

    Loader {
        id: loader
        anchors.right: parent.right
        anchors.top: parent.top
        width: Metrics.toastColumnWidth
        active: root.open || slideTimer.running

        HoverHandler {
            onHoveredChanged: {
                root.panelHovered = hovered;
                root._refreshHide();
            }
        }

        sourceComponent: FloatingCard {
            width: loader.width
            shown: root.open

            Repeater {
                // Only the current (default) output device.
                model: Audio.sinks.filter(s => s.isDefault)

                // modelData is injected into VolumeDeviceRow's required
                // `modelData` property by the Repeater.
                VolumeDeviceRow {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                }
            }
        }
    }
}
