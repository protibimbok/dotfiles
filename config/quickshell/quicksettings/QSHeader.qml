import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

RowLayout {
    id: root

    Layout.fillWidth: true
    spacing: 8

    // ── Left: battery + percent (green) + profile hint (muted) ───────────

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        Text {
            text: {
                if (!SystemStats.batteryPresent)
                    return "\uf1e6";
                if (SystemStats.batteryCharging)
                    return "\u{f0084}";
                if (SystemStats.batteryLevel > 80)
                    return "\u{f0079}";
                if (SystemStats.batteryLevel > 60)
                    return "\u{f007f}";
                if (SystemStats.batteryLevel > 40)
                    return "\u{f007e}";
                if (SystemStats.batteryLevel > 20)
                    return "\u{f007d}";
                return "\u{f008e}";
            }
            color: {
                if (!SystemStats.batteryPresent)
                    return Theme.colors.textMuted;
                if (SystemStats.batteryLevel < 20 && !SystemStats.batteryCharging)
                    return Theme.colors.red;
                if (SystemStats.batteryCharging)
                    return Theme.colors.green;
                return Theme.colors.text;
            }
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }

        Text {
            text: SystemStats.batteryPresent
                ? SystemStats.batteryLevel + "%"
                : "AC"
            color: Theme.colors.green
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            font.bold: true
        }

    }

    Item {
        Layout.fillWidth: true
    }

    RowLayout {
        spacing: 4

        Repeater {
            model: [
                { icon: "\uf06c", mode: "powersave" },    // leaf
                { icon: "\uf24e", mode: "balanced" },     // balance scale
                { icon: "\uf135", mode: "performance" }   // rocket
            ]

            Rectangle {
                required property var modelData
                property bool active: SystemStats.perfMode === modelData.mode

                width: 30
                height: 30
                radius: 6
                color: active
                    ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.22)
                    : Theme.colors.bg1
                border.width: active ? 1.5 : 1
                border.color: active ? Theme.colors.accent : Theme.colors.border
                opacity: active ? 1.0 : 0.85
                Behavior on color { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: active ? Theme.colors.accent : Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: SystemStats.setPerfMode(modelData.mode)
                }
            }
        }
    }
}
