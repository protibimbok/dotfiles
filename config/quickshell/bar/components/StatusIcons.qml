import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.services.network

Item {
    id: root
    implicitWidth: row.implicitWidth + 16
    // Fixed height: RowLayout parent height can resolve to 0 and shrink the hit target.
    implicitHeight: 44

    signal hoverEntered()
    signal hoverExited()

    Rectangle {
        anchors.fill: parent
        anchors.margins: 4
        radius: 10
        color: Theme.colors.bg1
        opacity: containerHover.hovered ? 0.4 : 0
        z: 0
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 4
        z: 1

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

    // Full-bar hit target above icons so child items do not steal hover.
    Item {
        anchors.fill: parent
        z: 2

        HoverHandler {
            id: containerHover
            cursorShape: Qt.PointingHandCursor
            onHoveredChanged: {
                if (hovered)
                    root.hoverEntered()
                else
                    root.hoverExited()
            }
        }
    }
}
