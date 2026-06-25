import Quickshell
import QtQuick
import qs.bar
import qs.tokens

ShellRoot {
    id: shell

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
