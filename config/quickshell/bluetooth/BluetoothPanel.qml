import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.theme
import qs.tokens
import qs.services
import qs.services.network

// Flush-right, under-the-bar Bluetooth panel — same surface + entrance animation as
// the VolumePanel, listing the saved (paired) devices, one row each, so a known
// device can be reconnected with a click. Shown while the bar's bluetooth icon (via
// BluetoothPanelState) or the panel itself is hovered; a short grace timer bridges the
// cursor gap between the two windows. Pairing new devices stays in the bluetui TUI
// (the icon's click action).
PanelWindow {
    id: root

    // Dedicated namespace so the compositor blurs only this (like the toasts).
    WlrLayershell.namespace: "quickshell-bluetooth"

    readonly property int _edgeRoom: Metrics.toastRadius
    readonly property bool open: BluetoothPanelState.iconHovered || root.panelHovered || hideTimer.running
    property bool panelHovered: false

    // Saved (paired) devices, plus anything currently connected.
    readonly property var savedDevices: Bluetooth.devices.filter(d =>
        Bluetooth.pairedAddresses.indexOf(d.address) >= 0
        || Bluetooth.connectedAddresses.indexOf(d.address) >= 0)

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
    onOpenChanged: if (!open) slideTimer.restart()

    function _refreshHide() {
        if (BluetoothPanelState.iconHovered || root.panelHovered)
            hideTimer.stop();
        else
            hideTimer.restart();
    }

    Connections {
        target: BluetoothPanelState
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

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Spacing.sm

                Text {
                    width: parent.width
                    text: Bluetooth.enabled ? "Bluetooth" : "Bluetooth off"
                    color: Theme.pillTextMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.label
                    font.bold: true
                    bottomPadding: Spacing.xs
                }

                Repeater {
                    model: root.savedDevices

                    // modelData (a Bluetooth.devices entry) is injected into the
                    // row's required `modelData` property by the Repeater.
                    BluetoothDeviceRow {
                        width: column.width
                    }
                }

                Text {
                    width: parent.width
                    visible: root.savedDevices.length === 0
                    text: Bluetooth.enabled ? "No saved devices" : "Bluetooth is disabled"
                    color: Theme.pillTextMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                }
            }
        }
    }
}
