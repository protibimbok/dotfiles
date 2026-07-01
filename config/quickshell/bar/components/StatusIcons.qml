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

            HoverHandler { id: btHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root._run("omarchy-launch-bluetooth") }

            BarTooltip {
                target: btItem
                shown: btHover.hovered
                text: root._bluetoothTooltip()
            }
        }

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

            HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root._run("omarchy-launch-wifi") }

            BarTooltip {
                target: netItem
                shown: netHover.hovered
                text: root._networkTooltip()
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

            HoverHandler {
                id: audioHover
                cursorShape: Qt.PointingHandCursor
                // Publish hover so the flush-right VolumePanel (a separate window)
                // can open while the cursor is over this icon.
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

    function _bluetoothTooltip(): string {
        if (!Bluetooth.enabled)
            return "Bluetooth off";
        if (!Bluetooth.connected)
            return "No devices connected";
        let names = Bluetooth.connectedNames;
        if (names.length === 1)
            return Bluetooth.displayName(names[0], Bluetooth.connectedAddresses[0]);
        let head = "Devices connected: " + Bluetooth.connectedAddresses.length;
        let labeled = [];
        for (let i = 0; i < names.length; ++i)
            labeled.push(Bluetooth.displayName(names[i], Bluetooth.connectedAddresses[i]));
        return head + "\n" + labeled.join("\n");
    }

    function _networkTooltip(): string {
        if (Ethernet.connected)
            return "⇣ " + SystemStats.netDown + "  ⇡ " + SystemStats.netUp;
        if (Wifi.connected) {
            let head = (Wifi.ssid.length ? Wifi.ssid : "Wi-Fi")
                + (Wifi.frequency > 0 ? " (" + Wifi.frequency + " GHz)" : "");
            return head + "\n⇣ " + SystemStats.netDown + "  ⇡ " + SystemStats.netUp;
        }
        return "Disconnected";
    }

    function _batteryTooltip(): string {
        let w = Math.round(SystemStats.batteryPower);
        let arrow = SystemStats.batteryCharging ? "↑" : "↓";
        let power = w > 0 ? (w + "W" + arrow + " ") : "";
        return power + SystemStats.batteryLevel + "%";
    }
}
