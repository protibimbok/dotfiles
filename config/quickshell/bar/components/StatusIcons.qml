import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.services.network

Item {
    id: root

    /// "all" | "connectivity" (wifi, ethernet, bluetooth) | "system" (volume, battery)
    property string section: "all"

    implicitWidth: row.implicitWidth
    implicitHeight: 28

    signal hoverEntered()
    signal hoverExited()

    function _showConnectivity(): bool {
        return section === "all" || section === "connectivity"
    }

    function _showSystem(): bool {
        return section === "all" || section === "system"
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4

        Item {
            visible: _showConnectivity() && Wifi.enabled
                && (Wifi.connected
                    || Wifi.busyMessage.length > 0
                    || Wifi.nmConnecting)
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: Wifi.strength > 0.75 ? "\u{f0928}" : (Wifi.strength > 0.4 ? "\u{f0925}" : "\u{f0922}")
                color: Wifi.connected ? Theme.pillText : Theme.pillAccent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }

        }

        Item {
            visible: _showConnectivity() && Ethernet.connected
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\u{ef44}"
                color: Theme.pillGreen
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }
        }

        Item {
            visible: _showConnectivity() && Bluetooth.enabled
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\uf294"
                color: Bluetooth.connected ? Theme.pillCyan : Theme.pillTextMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Item {
            visible: _showSystem()
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
                color: Audio.muted ? Theme.pillTextMuted : Theme.pillText
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        Item {
            visible: _showSystem() && SystemStats.batteryPresent
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
                    if (SystemStats.batteryLevel < 20 && !SystemStats.batteryCharging) return Theme.pillRed;
                    if (SystemStats.batteryCharging) return Theme.pillGreen;
                    return Theme.pillText;
                }
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    HoverHandler {
        id: containerHover
        enabled: section === "all" || section === "system"
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (!enabled)
                return
            if (hovered)
                root.hoverEntered()
            else
                root.hoverExited()
        }
    }
}
