import Quickshell
import QtQuick
import qs.bar
import qs.tokens
import qs.services
import qs.notifications
import qs.volume
import qs.wifi
import qs.bluetooth

ShellRoot {
    id: shell

    // Transient notification toasts (top-right, below the bar).
    NotificationToasts {}

    // Hover-triggered per-device volume panel (top-right, below the bar),
    // sharing the toast surface/animation.
    VolumePanel {}

    // Hover-triggered Wi-Fi and Bluetooth panels (top-right, below the bar),
    // sharing the same surface/animation as the volume panel.
    WifiPanel {}
    BluetoothPanel {}

    // The floating-overlay backdrop is now handled compositor-side by the
    // plugins/hyprdesktop plugin (empty-space clicks dismiss the layer), so the old
    // "omarchy-float-scrim" click-catcher window is gone.

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

                property bool barShown: _hoverActive
                property bool _hoverActive: true

                HoverHandler {
                    id: barHover
                    onHoveredChanged: {
                        if (hovered) {
                            hideTimer.stop();
                            barContainer._hoverActive = true;
                        } else {
                            hideTimer.restart();
                        }
                    }
                }

                Timer {
                    id: hideTimer
                    interval: Durations.barHideDelay
                    onTriggered: {
                        if (!barHover.hovered)
                            barContainer._hoverActive = false;
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
}
