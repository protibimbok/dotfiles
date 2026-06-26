import Quickshell
import QtQuick
import qs.bar
import qs.tokens
import qs.services

ShellRoot {
    id: shell

    // Click-catching backdrop for the floating overlay: a transparent fullscreen
    // window that sits above the tiles and below the floating windows (Hyprland's
    // lua/floating.lua sizes, positions and z-orders it). Moving the cursor onto it
    // can't focus a tile, so a focused float keeps focus; clicking it dismisses the
    // whole floating layer. Shown only while a real float is visible.
    FloatingWindow {
        id: floatScrim
        title: "omarchy-float-scrim"
        color: "transparent"
        // Always mapped; Hyprland (lua/floating.lua) parks it off-screen when there
        // is nothing to dismiss and stretches it over the monitor when floats appear.
        visible: true
        implicitWidth: 1920
        implicitHeight: 1080

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: Hyprland.dispatch("omarchy_float_dismiss()")
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
