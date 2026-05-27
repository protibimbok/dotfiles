import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.theme
import qs.tokens
import qs.services
import qs.services.network

Item {
    id: root

    property string section: "all"

    implicitWidth: row.implicitWidth
    implicitHeight: Metrics.barWidgetHeight

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
        spacing: Spacing.xs

        Item {
            visible: _showConnectivity() && Wifi.enabled
                && (Wifi.connected
                    || Wifi.busyMessage.length > 0
                    || Wifi.nmConnecting)
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: Wifi.strength > 0.75 ? "\u{f0928}" : (Wifi.strength > 0.4 ? "\u{f0925}" : "\u{f0922}")
                color: Wifi.connected ? Theme.pillText : Theme.pillAccent
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
            }
        }

        Item {
            visible: _showConnectivity() && Ethernet.connected
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\u{ef44}"
                color: Theme.pillGreen
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
            }
        }

        Item {
            visible: _showConnectivity() && Bluetooth.enabled
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "\uf294"
                color: Bluetooth.connected ? Theme.pillCyan : Theme.pillTextMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
                Behavior on color { ColorAnimation { duration: Durations.fade } }
            }
        }

        Item {
            visible: _showSystem()
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
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
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
                Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
            }
        }

        Item {
            visible: _showSystem() && SystemStats.batteryPresent
            Layout.preferredWidth: Metrics.iconSys
            Layout.preferredHeight: Metrics.iconSys
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
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconSm
                Behavior on color { ColorAnimation { duration: Durations.fade } }
            }
        }

        Item {
            visible: _showSystem()
            Layout.preferredWidth: langText.implicitWidth + 4
            Layout.preferredHeight: Metrics.langIndicatorHeight
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: Metrics.rowRadiusSm
                color: Theme.colors.surface
                opacity: langHover.hovered ? 0.5 : 0
                Behavior on opacity { NumberAnimation { duration: Durations.hoverMedium } }
            }

            Text {
                id: langText
                anchors.centerIn: parent
                text: SystemStats.inputLocale
                color: Theme.pillTextMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
            }

            HoverHandler { id: langHover; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: langToggle.running = true
            }

            Process {
                id: langToggle
                command: ["bash", "-c", "command -v fcitx5-remote >/dev/null 2>&1 && fcitx5-remote -t"]
                onExited: SystemStats.refreshInputLocale()
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
