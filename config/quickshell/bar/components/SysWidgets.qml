import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.theme
import qs.tokens
import qs.services

RowLayout {
    id: root
    spacing: Spacing.pillGapSm
    implicitHeight: Metrics.barWidgetHeight

    // --- CPU arc indicator ---
    Item {
        id: cpuWidget
        Layout.preferredWidth: Metrics.iconSys
        Layout.preferredHeight: Metrics.iconSys
        Layout.alignment: Qt.AlignVCenter

        property real usage: SystemStats.cpuAverage

        Canvas {
            id: cpuCanvas
            anchors.fill: parent
            property real usage: parent.usage
            Behavior on usage { NumberAnimation { duration: Durations.spin / 2; easing.type: Easing.OutCubic } }
            onUsageChanged: requestPaint()
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                let cx = width / 2, cy = height / 2, r = (width - 3) / 2;
                let startAngle = -Math.PI / 2;

                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.lineWidth = 2.5;
                ctx.strokeStyle = Theme.pillTrack;
                ctx.stroke();

                if (usage > 0.01) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, startAngle + 2 * Math.PI * usage);
                    ctx.lineWidth = 2.5;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Theme.pillAccent;
                    ctx.stroke();
                }
            }
        }

        HoverHandler {
            id: cpuHover
            cursorShape: Qt.PointingHandCursor
        }

        // Get the screen position of the widget
        property point globalPos: Qt.point(0, 0)
        onVisibleChanged: {
            var mapped = mapToGlobal(0, 0)
            globalPos = mapped
        }

        PopupWindow {
            id: cpuTip
            visible: cpuHover.hovered

            // anchor.item positions relative to the widget item itself
            anchor.item: cpuWidget
            anchor.rect.x: (cpuWidget.width - width) / 2
            anchor.rect.y: cpuWidget.height + Spacing.xs

            implicitWidth: cpuTipText.implicitWidth + Spacing.xl
            implicitHeight: cpuTipText.implicitHeight + Spacing.sm
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: Metrics.rowRadius
                color: Theme.colors.surface
                border.color: Theme.colors.outline
                border.width: 1

                Text {
                    id: cpuTipText
                    anchors.centerIn: parent
                    text: "CPU: " + Math.round(SystemStats.cpuAverage * 100) + "% (" + SystemStats.cpuCores.length + " cores)"
                    color: Theme.colors.foreground
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                }
            }
        }
    }

    // --- Memory arc indicator ---
    Item {
        id: memWidget
        Layout.preferredWidth: Metrics.iconSys
        Layout.preferredHeight: Metrics.iconSys
        Layout.alignment: Qt.AlignVCenter

        property real usage: SystemStats.memUsage

        Canvas {
            id: memCanvas
            anchors.fill: parent
            property real usage: parent.usage
            Behavior on usage { NumberAnimation { duration: Durations.spin / 2; easing.type: Easing.OutCubic } }
            onUsageChanged: requestPaint()
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                let cx = width / 2, cy = height / 2, r = (width - 3) / 2;
                let startAngle = -Math.PI / 2;

                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.lineWidth = 2.5;
                ctx.strokeStyle = Theme.pillTrack;
                ctx.stroke();

                if (usage > 0.01) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, startAngle + 2 * Math.PI * usage);
                    ctx.lineWidth = 2.5;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Theme.pillAccentAlt;
                    ctx.stroke();
                }
            }
        }

        HoverHandler { id: memHover; cursorShape: Qt.PointingHandCursor }

        PopupWindow {
            id: memTip
            visible: memHover.hovered

            anchor.item: memWidget
            anchor.rect.x: (memWidget.width - width) / 2
            anchor.rect.y: memWidget.height + Spacing.xs

            implicitWidth: memTipText.implicitWidth + Spacing.xl
            implicitHeight: memTipText.implicitHeight + Spacing.sm
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: Metrics.rowRadius
                color: Theme.colors.surface
                border.color: Theme.colors.outline
                border.width: 1

                Text {
                    id: memTipText
                    anchors.centerIn: parent
                    text: "RAM: " + SystemStats.memUsedGb.toFixed(1) + " / " + SystemStats.memTotalGb.toFixed(1) + " GB (" + Math.round(SystemStats.memUsage * 100) + "%)"
                    color: Theme.colors.foreground
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                }
            }
        }
    }

    // --- Network icon ---
    Item {
        id: netWidget
        Layout.preferredWidth: Metrics.iconSys
        Layout.preferredHeight: Metrics.iconSys
        Layout.alignment: Qt.AlignVCenter

        Text {
            anchors.centerIn: parent
            text: "\uf0ac"
            font.family: Typography.fontFamily
            font.pixelSize: Typography.iconSm
            color: (SystemStats.netDownBytes > 1024 || SystemStats.netUpBytes > 1024) ? Theme.pillAccent : Theme.pillTextMuted
            Behavior on color { ColorAnimation { duration: Durations.fadeSlow } }
        }

        HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }

        PopupWindow {
            id: netTip
            visible: netHover.hovered

            anchor.item: netWidget
            anchor.rect.x: (netWidget.width - width) / 2
            anchor.rect.y: netWidget.height + Spacing.xs

            implicitWidth: netTipText.implicitWidth + Spacing.xl
            implicitHeight: netTipText.implicitHeight + Spacing.sm
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: Metrics.rowRadius
                color: Theme.colors.surface
                border.color: Theme.colors.outline
                border.width: 1

                Text {
                    id: netTipText
                    anchors.centerIn: parent
                    text: "\u2193 " + SystemStats.netDown + "  \u2191 " + SystemStats.netUp
                    color: Theme.colors.foreground
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                }
            }
        }
    }

    // --- Language indicator ---
    Item {
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
        }
    }
}
