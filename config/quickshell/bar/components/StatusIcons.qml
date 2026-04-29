import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.services.network

Item {
    id: root
    implicitWidth: row.implicitWidth + 16
    implicitHeight: parent ? parent.height : 44

    signal settingsRequested()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 10
        color: Theme.colors.bg1
        opacity: containerHover.hovered ? 0.4 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    HoverHandler { id: containerHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.settingsRequested() }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Item {
            visible: Wifi.enabled
                && (Wifi.connected
                    || Wifi.busyMessage.length > 0
                    || Wifi.nmConnecting)
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: Wifi.strength > 0.75 ? "\u{f0928}" : (Wifi.strength > 0.4 ? "\u{f0925}" : "\u{f0922}")
                color: Wifi.connected ? Theme.colors.text : Theme.colors.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }

            HoverHandler { id: wifiHover }
            StatusTip {
                visible: wifiHover.hovered
                text: {
                    if (Wifi.busyMessage.length > 0)
                        return "Wi-Fi: " + Wifi.busyMessage;
                    if (Wifi.nmConnecting)
                        return "Wi-Fi: Connecting…";
                    if (Wifi.connected) {
                        let s = (Wifi.activeSsid || Wifi.ssid || "Connected").trim();
                        return "Wi-Fi: " + (s.length > 0 ? s : "Connected");
                    }
                    return "Wi-Fi";
                }
            }
        }

        Item {
            visible: Ethernet.connected
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\u{ef44}"
                color: Theme.colors.green
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }
        }

        Item {
            visible: Bluetooth.enabled
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\uf294"
                color: Bluetooth.connected ? Theme.colors.cyan : Theme.colors.textMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            HoverHandler { id: btHover }
            StatusTip {
                visible: btHover.hovered
                text: Bluetooth.connected ? Bluetooth.device : "Bluetooth on (no device)"
            }
        }

        Item {
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: {
                    if (Audio.muted) return "\u{eee8}";
                    if (Audio.volume > 70) return "\uf028";
                    if (Audio.volume > 20) return "\uf027";
                    return "\uf026";
                }
                color: Audio.muted ? Theme.colors.textMuted : Theme.colors.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Item {
            visible: SystemStats.batteryPresent
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: {
                    if (SystemStats.batteryCharging) return "\u{f0084}";
                    if (SystemStats.batteryLevel > 80) return "\u{f0079}";
                    if (SystemStats.batteryLevel > 60) return "\u{f007f}";
                    if (SystemStats.batteryLevel > 40) return "\u{f007e}";
                    if (SystemStats.batteryLevel > 20) return "\u{f007d}";
                    return "\u{f008e}";
                }
                color: {
                    if (SystemStats.batteryLevel < 20 && !SystemStats.batteryCharging) return Theme.colors.red;
                    if (SystemStats.batteryCharging) return Theme.colors.green;
                    return Theme.colors.text;
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    component StatusTip: Rectangle {
        property alias text: tipText.text
        x: (parent.width - width) / 2
        y: parent.height + 6
        width: tipText.implicitWidth + 14
        height: tipText.implicitHeight + 10
        radius: 8
        color: Theme.colors.bg1
        border.color: Theme.colors.border
        border.width: 1
        z: 100
        opacity: visible ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }

        Text {
            id: tipText
            anchors.centerIn: parent
            color: Theme.colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }
    }
}
