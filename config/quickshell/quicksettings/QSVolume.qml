import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.tokens

ColumnLayout {
    Layout.fillWidth: true
    spacing: Spacing.xs

    // ── Shared slider component (inline) ─────────────────────────────────
    // Volume row
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: Spacing.lg

        Item {
            width: Metrics.iconMuteBtn
            height: Metrics.iconMuteBtn

            Rectangle {
                anchors.fill: parent
                radius: Metrics.rowRadius
                color: volIconHov.hovered
                    ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.15)
                    : "transparent"
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            Text {
                anchors.centerIn: parent
                text: Audio.muted ? "\u{eee8}"
                    : Audio.volume >= 70 ? "\uf028"
                    : Audio.volume >= 30 ? "\uf027"
                    : "\uf026"
                color: Audio.muted ? Theme.colors.textMuted : Theme.colors.accent
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconMd
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            HoverHandler { id: volIconHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Audio.muted = !Audio.muted }
        }

        // Slider track
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.iconSys

            // Track background
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 5
                radius: 3
                color: Theme.colors.bg2
            }

            // Track fill
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * Math.max(0, Math.min(100, Audio.volume)) / 100
                height: 5
                radius: 3
                color: Audio.muted ? Theme.colors.textMuted : Theme.colors.accent
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
            }

            // Thumb
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * Math.max(0, Math.min(100, Audio.volume)) / 100 - width / 2
                width: Metrics.iconApp
                height: Metrics.iconApp
                radius: Metrics.rowRadius
                color: Theme.colors.accent
                border.color: Theme.colors.bg
                border.width: 2
                Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: mouse => _setVol(mouse.x)
                onPositionChanged: mouse => { if (pressed) _setVol(mouse.x) }
                function _setVol(mx: real) {
                    Audio.setVolume(Math.round(Math.max(0, Math.min(100, mx / width * 100))));
                }
            }
        }

        Text {
            Layout.preferredWidth: 32
            text: Audio.volume + "%"
            color: Theme.colors.textMuted
            font.family: Typography.fontFamily
            font.pixelSize: Typography.bodySm
            horizontalAlignment: Text.AlignRight
        }
    }

    // Brightness row (only visible when brightnessctl is available)
    RowLayout {
        Layout.fillWidth: true
        Layout.preferredHeight: 36
        spacing: Spacing.lg
        visible: SystemStats.brightness >= 0

        Item {
            width: Metrics.iconMuteBtn
            height: Metrics.iconMuteBtn

            Text {
                anchors.centerIn: parent
                text: SystemStats.brightness >= 70 ? "\uf185"
                    : SystemStats.brightness >= 30 ? "\uf0eb"
                    : "\uf186"
                color: Theme.colors.accent
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconMd
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Metrics.iconSys

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 5
                radius: 3
                color: Theme.colors.bg2
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width * Math.max(0, Math.min(100, SystemStats.brightness)) / 100
                height: 5
                radius: 3
                color: Theme.colors.accent
                Behavior on width { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                x: parent.width * Math.max(0, Math.min(100, SystemStats.brightness)) / 100 - width / 2
                width: Metrics.iconApp
                height: Metrics.iconApp
                radius: Metrics.rowRadius
                color: Theme.colors.accent
                border.color: Theme.colors.bg
                border.width: 2
                Behavior on x { NumberAnimation { duration: 80; easing.type: Easing.OutCubic } }
            }

            MouseArea {
                anchors.fill: parent
                onPressed: mouse => _setBright(mouse.x)
                onPositionChanged: mouse => { if (pressed) _setBright(mouse.x) }
                function _setBright(mx: real) {
                    SystemStats.setBrightness(Math.round(Math.max(0, Math.min(100, mx / width * 100))));
                }
            }
        }

        Text {
            Layout.preferredWidth: 32
            text: SystemStats.brightness + "%"
            color: Theme.colors.textMuted
            font.family: Typography.fontFamily
            font.pixelSize: Typography.bodySm
            horizontalAlignment: Text.AlignRight
        }
    }
}
