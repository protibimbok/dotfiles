import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.tokens
import qs.services

RowLayout {
    id: root

    Layout.fillWidth: true
    Layout.preferredHeight: Metrics.listRowHeight

    readonly property int percentColWidth: 36
    readonly property int arrowColWidth: 10

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height

        RowLayout {
            anchors.centerIn: parent
            spacing: Spacing.sm

            Text {
                text: "\u{f0199}"
                color: Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconMd
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: Typography.iconMd
            }

            Text {
                Layout.preferredWidth: root.percentColWidth
                text: Math.round(SystemStats.memUsage * 100) + "%"
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.bodySm
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height

        RowLayout {
            anchors.centerIn: parent
            spacing: Spacing.sm

            Text {
                text: "\uf2db"
                color: Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconMd
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: Typography.iconMd
            }

            Text {
                Layout.preferredWidth: root.percentColWidth
                text: Math.round(SystemStats.cpuAverage * 100) + "%"
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.bodySm
                horizontalAlignment: Text.AlignRight
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height

        RowLayout {
            anchors.centerIn: parent
            spacing: Spacing.xs

            Text {
                Layout.fillWidth: true
                text: SystemStats.netUp
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.bodySm
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
            }

            Text {
                Layout.preferredWidth: root.arrowColWidth
                text: "\u2191"
                color: (SystemStats.netUpBytes > 1024) ? Theme.colors.primary : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.bodySm
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: Durations.fadeSlow } }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: parent.height

        RowLayout {
            anchors.centerIn: parent
            spacing: Spacing.xs

            Text {
                Layout.fillWidth: true
                text: SystemStats.netDown
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.bodySm
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
            }

            Text {
                Layout.preferredWidth: root.arrowColWidth
                text: "\u2193"
                color: (SystemStats.netDownBytes > 1024) ? Theme.colors.primary : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.bodySm
                horizontalAlignment: Text.AlignHCenter
                Behavior on color { ColorAnimation { duration: Durations.fadeSlow } }
            }
        }
    }
}
