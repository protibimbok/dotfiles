import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.tokens
import qs.services
import qs.services.network

// Right-side status glyphs mirroring the Waybar modules:
//   bluetooth · input language · network · pulseaudio · cpu · battery
// Click actions and tooltips reuse the same helpers/format Waybar uses.
Item {
    id: root

    implicitWidth: row.implicitWidth
    implicitHeight: Metrics.barWidgetHeight

    function _run(cmd: string) {
        Quickshell.execDetached(["bash", "-c", cmd]);
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Spacing.sm

        // input language (fcitx5) — on-click: toggle IME
        Item {
            id: langItem
            visible: SystemStats.inputMethodRunning
            Layout.preferredWidth: langLabel.implicitWidth
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                id: langLabel
                anchors.centerIn: parent
                text: SystemStats.inputLocale
                color: SystemStats.inputMethodActive ? Theme.pillCyan : Theme.pillTextMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.label
                font.weight: SystemStats.inputMethodActive ? Font.DemiBold : Font.Normal
                Behavior on color { ColorAnimation { duration: Durations.fade } }
            }

            HoverHandler { id: langHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: SystemStats.toggleInputMethod() }

            BarTooltip {
                target: langItem
                shown: langHover.hovered
                text: SystemStats.inputMethodLabel
                    + (SystemStats.inputMethodActive ? "" : "\n(inactive)")
            }
        }

        // bluetooth — on-click: omarchy-launch-bluetooth
        Item {
            id: btItem
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: {
                    if (!Bluetooth.enabled) return "\u{f00b2}";   // 󰂲 off
                    if (Bluetooth.connected) return "\u{f00b1}";   // 󰂱 connected
                    return "\u{f00af}";                            // 󰂯 on
                }
                color: Bluetooth.connected ? Theme.pillCyan : Theme.pillTextMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm - 2
                Behavior on color { ColorAnimation { duration: Durations.fade } }
            }

            // Enlarged hover target (full bar height) so moving down into the
            // BluetoothPanel below leaves no dead strip that would flicker it shut.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Metrics.barHeight

                HoverHandler {
                    id: btHover
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: BluetoothPanelState.iconHovered = hovered
                }
                TapHandler { onTapped: root._run("omarchy-launch-bluetooth") }
            }
        }


        // network — on-click: omarchy-launch-wifi
        Item {
            id: netItem
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: {
                    if (Ethernet.connected) return "\u{f0002}";            // 󰀂 ethernet
                    if (!Wifi.enabled) return "\u{f092e}";                 // 󰤮 disconnected
                    if (!Wifi.connected) return "\u{f092f}";               // 󰤯 no signal
                    if (Wifi.strength > 0.75) return "\u{f0928}";          // 󰤨
                    if (Wifi.strength > 0.5) return "\u{f0925}";           // 󰤥
                    if (Wifi.strength > 0.25) return "\u{f0922}";          // 󰤢
                    if (Wifi.strength > 0) return "\u{f091f}";             // 󰤟
                    return "\u{f092f}";                                    // 󰤯
                }
                color: (Ethernet.connected || Wifi.connected) ? Theme.pillText : Theme.pillTextMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm - 3
                Behavior on color { ColorAnimation { duration: Durations.fade } }
            }

            // Enlarged hover target (full bar height) so moving down into the
            // WifiPanel below leaves no dead strip that would flicker it shut.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Metrics.barHeight

                HoverHandler {
                    id: netHover
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: WifiPanelState.iconHovered = hovered
                }
                TapHandler { onTapped: root._run("omarchy-launch-wifi") }
            }
        }

        // pulseaudio — on-click: omarchy-launch-audio, right: mute, scroll: volume
        Item {
            id: audioItem
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: {
                    if (Audio.muted) return "\u{f0581}";        // 󰖁 volume-off
                    if (Audio.volume > 70) return "\u{f057e}";   // 󰕾 volume-high
                    if (Audio.volume > 20) return "\u{f0580}";   // 󰖀 volume-medium
                    return "\u{f057f}";                          // 󰕿 volume-low
                }
                color: Audio.muted ? Theme.pillTextMuted : Theme.pillText
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
                Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
            }

            // Enlarged hover/click target spanning the full bar height. The icon
            // itself is only iconSys tall, leaving a dead strip between it and the
            // bottom of the bar window; the cursor crossing that strip on its way to
            // the flush-right VolumePanel (a separate window directly below) would
            // drop the hover and flicker the panel shut. Reaching to the window edge
            // hands the hover straight to the panel with no gap.
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Metrics.barHeight

                HoverHandler {
                    id: audioHover
                    cursorShape: Qt.PointingHandCursor
                    // Publish hover so the VolumePanel can open while the cursor is here.
                    onHoveredChanged: VolumePanelState.iconHovered = hovered
                }
                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onTapped: (point, button) => {
                        if (button === Qt.RightButton)
                            Audio.muted = !Audio.muted;
                        else
                            root._run("omarchy-launch-audio");
                    }
                }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    onWheel: (event) => {
                        Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 5 : -5));
                    }
                }
            }
        }

        // cpu — on-click: btop, right: terminal
        Item {
            id: cpuItem
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\u{f035b}"   // 󰍛
                color: SystemStats.cpuAverage > 0.8 ? Theme.pillRed : Theme.pillText
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
                Behavior on color { ColorAnimation { duration: Durations.fade } }
            }

            HoverHandler { id: cpuHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: (point, button) => {
                    if (button === Qt.RightButton)
                        root._run("alacritty");
                    else
                        root._run("omarchy-launch-or-focus-tui btop");
                }
            }

            BarTooltip {
                target: cpuItem
                shown: cpuHover.hovered
                text: Math.round(SystemStats.cpuAverage * 100) + "%"
            }
        }

        // battery — on-click: omarchy-menu power
        Item {
            id: battItem
            visible: SystemStats.batteryPresent
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            readonly property bool battPlugged: SystemStats.batteryStatus === "Charging"
                || SystemStats.batteryStatus === "Full"
                || SystemStats.batteryStatus === "Not charging"

            Text {
                id: battGlyph
                anchors.centerIn: parent
                text: {
                    if (SystemStats.batteryLevel > 80) return "\u{f0079}";
                    if (SystemStats.batteryLevel > 60) return "\u{f007f}";
                    if (SystemStats.batteryLevel > 40) return "\u{f007e}";
                    if (SystemStats.batteryLevel > 20) return "\u{f007d}";
                    return "\u{f008e}";
                }
                color: {
                    if (SystemStats.batteryLevel < 20 && !SystemStats.batteryCharging) return Theme.pillRed;
                    if (SystemStats.batteryCharging) return Theme.pillGreen;
                    return Theme.pillText;
                }
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
                Behavior on color { ColorAnimation { duration: Durations.fade } }
            }

            // charging / plugged indicator (fa-bolt, reliably present)
            Text {
                visible: battItem.battPlugged
                anchors.centerIn: parent
                text: "\uf0e7"   // fa-bolt
                color: SystemStats.batteryCharging ? Theme.pillGreen : Theme.pillTextMuted
                style: Text.Outline
                styleColor: Theme.pillBackground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.caption
            }

            HoverHandler { id: battHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root._run("omarchy-menu power") }

            BarTooltip {
                target: battItem
                shown: battHover.hovered
                text: root._batteryTooltip()
            }
        }
    }

    function _batteryTooltip(): string {
        let w = Math.round(SystemStats.batteryPower);
        let arrow = SystemStats.batteryCharging ? "↑" : "↓";
        let power = w > 0 ? (w + "W" + arrow + " ") : "";
        return power + SystemStats.batteryLevel + "%";
    }
}
