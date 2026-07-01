import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.theme
import qs.tokens
import qs.services
import qs.services.network

// Flush-right, under-the-bar Wi-Fi panel — same surface + entrance animation as the
// VolumePanel, but listing the saved & currently-available networks (one row each).
// Shown while the bar's network icon (via WifiPanelState) or the panel itself is
// hovered; a short grace timer bridges the cursor gap between the two windows. Opening
// the panel kicks a rescan, which is then refreshed periodically while it stays open.
PanelWindow {
    id: root

    // Dedicated namespace so the compositor blurs only this (like the toasts).
    WlrLayershell.namespace: "quickshell-wifi"

    readonly property int _edgeRoom: Metrics.toastRadius
    readonly property bool open: WifiPanelState.iconHovered || root.panelHovered || hideTimer.running
    property bool panelHovered: false

    anchors {
        top: true
        right: true
    }
    margins {
        top: 0
        right: 0
    }

    exclusiveZone: 0
    color: "transparent"
    // Stay mapped through the slide-out so the card can retract behind the bar
    // (and brief hover toggles don't destroy/recreate the card).
    visible: root.open || slideTimer.running

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

    function _refreshHide() {
        if (WifiPanelState.iconHovered || root.panelHovered)
            hideTimer.stop();
        else
            hideTimer.restart();
    }

    Connections {
        target: WifiPanelState
        function onIconHoveredChanged() { root._refreshHide(); }
    }

    // Scan on open, then keep the list fresh while the panel is visible; on close,
    // keep mapped while the card slides back up.
    onOpenChanged: {
        if (open) Wifi.scan();
        else slideTimer.restart();
    }
    Timer {
        interval: 10000
        running: root.open
        repeat: true
        onTriggered: Wifi.scan()
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

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Spacing.sm

                Text {
                    width: parent.width
                    text: Wifi.enabled
                        ? (Wifi.scanning ? "Wi-Fi — scanning…" : "Wi-Fi")
                        : "Wi-Fi off"
                    color: Theme.pillTextMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.label
                    font.bold: true
                    bottomPadding: Spacing.xs
                }

                Repeater {
                    model: Wifi.networks

                    // modelData (a Wifi.networks entry) is injected into the row's
                    // required `modelData` property by the Repeater.
                    WifiNetworkRow {
                        width: column.width
                    }
                }

                Text {
                    width: parent.width
                    visible: Wifi.networks.length === 0
                    text: Wifi.enabled ? "No networks found" : "Wi-Fi is disabled"
                    color: Theme.pillTextMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                }
            }
        }
    }
}
