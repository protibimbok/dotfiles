import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.tokens

RowLayout {
    id: root

    Layout.fillWidth: true
    spacing: Spacing.md

    // ── Left: battery + percent (green) + profile hint (muted) ───────────

    RowLayout {
        Layout.fillWidth: true
        spacing: Spacing.md

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
                    return Theme.colors.foregroundMuted;
                if (SystemStats.batteryLevel < 20 && !SystemStats.batteryCharging)
                    return Theme.colors.error;
                if (SystemStats.batteryCharging)
                    return Theme.colors.success;
                return Theme.colors.foreground;
            }
            font.family: Typography.fontFamily
            font.pixelSize: Typography.iconMd
        }

        Text {
            text: SystemStats.batteryPresent
                ? SystemStats.batteryLevel + "%"
                : "AC"
            color: Theme.colors.success
            font.family: Typography.fontFamily
            font.pixelSize: Typography.body
            font.bold: true
        }

    }

    Item {
        Layout.fillWidth: true
    }

    RowLayout {
        spacing: Spacing.xs

        Repeater {
            model: [
                { icon: "\uf06c", mode: "powersave" },    // leaf
                { icon: "\uf24e", mode: "balanced" },     // balance scale
                { icon: "\uf135", mode: "performance" }   // rocket
            ]

            Rectangle {
                required property var modelData
                property bool active: SystemStats.perfMode === modelData.mode

                width: Metrics.iconPerfBtn
                height: Metrics.iconPerfBtn
                radius: Metrics.rowRadiusSm
                color: active
                    ? Theme.primaryTint(0.22)
                    : Theme.colors.surface
                border.width: active ? 1.5 : 1
                border.color: active ? Theme.colors.primary : Theme.colors.outline
                opacity: active ? 1.0 : 0.85
                Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
                Behavior on border.color { ColorAnimation { duration: Durations.hoverMedium } }

                Text {
                    anchors.centerIn: parent
                    text: modelData.icon
                    color: active ? Theme.colors.primary : Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.header
                    Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
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
