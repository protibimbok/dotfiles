import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.services.network
import qs.tokens

RowLayout {
    id: root

    Layout.fillWidth: true
    spacing: Spacing.md

    property int rowHeight: 44

    // ── Ethernet: icon toggle — connected / disconnected ─────────────────

    Rectangle {
        Layout.fillWidth: true
        Layout.preferredHeight: root.rowHeight
        radius: Metrics.tileRadius
        color: Ethernet.connected
            ? Theme.primaryTint(0.22)
            : ethHover.hovered
                ? Theme.primaryTint(0.08)
                : Theme.colors.surface
        border.width: Ethernet.connected ? 1.5 : 1
        border.color: Ethernet.connected ? Theme.colors.primary : Theme.colors.outline
        opacity: 0.95
        Behavior on color { ColorAnimation { duration: 120 } }

        RowLayout {
            anchors.centerIn: parent
            spacing: Spacing.sm

            Text {
                text: "\uef44"
                color: Ethernet.connected ? Theme.colors.primary : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: 20
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                text: "Ethernet"
                color: Ethernet.connected ? Theme.colors.primary : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
                font.bold: Ethernet.connected
                Behavior on color { ColorAnimation { duration: 120 } }
            }
        }

        HoverHandler { id: ethHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { onTapped: Ethernet.toggle() }
    }

    // ── DND: pill with 3 icon buttons + inner dividers ────────────────────

    Rectangle {
        id: dndPill
        Layout.fillWidth: true
        Layout.preferredHeight: root.rowHeight
        radius: height / 2
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.outline
        opacity: 0.95

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 3
            anchors.bottomMargin: 3
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: (dndPill.height - 6) / 2
                color: Notifications.dndMode === 0
                    ? Theme.primaryTint(0.22)
                    : d0.hovered
                        ? Theme.primaryTint(0.08)
                        : "transparent"
                border.width: Notifications.dndMode === 0 ? 1.5 : 0
                border.color: Theme.colors.primary
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf1f6"
                    color: Notifications.dndMode === 0 ? Theme.colors.primary : Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.iconSm
                }
                HoverHandler { id: d0; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Notifications.dndMode = 0 }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.colors.outline
                opacity: 0.55
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: (dndPill.height - 6) / 2
                color: Notifications.dndMode === 1
                    ? Theme.primaryTint(0.22)
                    : d1.hovered
                        ? Theme.primaryTint(0.08)
                        : "transparent"
                border.width: Notifications.dndMode === 1 ? 1.5 : 0
                border.color: Theme.colors.primary
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "\uf0f3"
                    color: Notifications.dndMode === 1 ? Theme.colors.primary : Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.iconSm
                }
                HoverHandler { id: d1; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Notifications.dndMode = 1 }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.colors.outline
                opacity: 0.55
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: (dndPill.height - 6) / 2
                color: Notifications.dndMode === 2
                    ? Theme.primaryTint(0.22)
                    : d2.hovered
                        ? Theme.primaryTint(0.08)
                        : "transparent"
                border.width: Notifications.dndMode === 2 ? 1.5 : 0
                border.color: Theme.colors.primary
                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    // codicon bell-dot in Nerd Fonts: priority / urgent alerts
                    text: "\uea20"
                    color: Notifications.dndMode === 2 ? Theme.colors.primary : Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.iconSm
                }
                HoverHandler { id: d2; cursorShape: Qt.PointingHandCursor }
                TapHandler { onTapped: Notifications.dndMode = 2 }
            }
        }
    }
}
