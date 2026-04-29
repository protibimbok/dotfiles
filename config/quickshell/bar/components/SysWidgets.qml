import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.theme
import qs.services

RowLayout {
    id: root
    spacing: 10

    // --- CPU arc indicator ---
    Item {
        id: cpuWidget
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter

        property real usage: SystemStats.cpuAverage

        Canvas {
            id: cpuCanvas
            anchors.fill: parent
            property real usage: parent.usage
            Behavior on usage { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            onUsageChanged: requestPaint()
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                let cx = width / 2, cy = height / 2, r = (width - 3) / 2;
                let startAngle = -Math.PI / 2;

                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.lineWidth = 2.5;
                ctx.strokeStyle = Qt.rgba(Theme.colors.bg2.r, Theme.colors.bg2.g, Theme.colors.bg2.b, 0.4);
                ctx.stroke();

                if (usage > 0.01) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, startAngle + 2 * Math.PI * usage);
                    ctx.lineWidth = 2.5;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Theme.colors.accent;
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
            anchor.rect.y: cpuWidget.height + 4   // below the widget

            implicitWidth: cpuTipText.implicitWidth + 14
            implicitHeight: cpuTipText.implicitHeight + 10
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.colors.bg1
                border.color: Theme.colors.border
                border.width: 1

                Text {
                    id: cpuTipText
                    anchors.centerIn: parent
                    text: "CPU: " + Math.round(SystemStats.cpuAverage * 100) + "% (" + SystemStats.cpuCores.length + " cores)"
                    color: Theme.colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }
    }

    // --- Memory arc indicator ---
    Item {
        id: memWidget
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter

        property real usage: SystemStats.memUsage

        Canvas {
            id: memCanvas
            anchors.fill: parent
            property real usage: parent.usage
            Behavior on usage { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
            onUsageChanged: requestPaint()
            onPaint: {
                let ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                let cx = width / 2, cy = height / 2, r = (width - 3) / 2;
                let startAngle = -Math.PI / 2;

                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, 2 * Math.PI);
                ctx.lineWidth = 2.5;
                ctx.strokeStyle = Qt.rgba(Theme.colors.bg2.r, Theme.colors.bg2.g, Theme.colors.bg2.b, 0.4);
                ctx.stroke();

                if (usage > 0.01) {
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, startAngle, startAngle + 2 * Math.PI * usage);
                    ctx.lineWidth = 2.5;
                    ctx.lineCap = "round";
                    ctx.strokeStyle = Theme.colors.accentAlt;
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
            anchor.rect.y: memWidget.height + 4

            implicitWidth: memTipText.implicitWidth + 14
            implicitHeight: memTipText.implicitHeight + 10
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.colors.bg1
                border.color: Theme.colors.border
                border.width: 1

                Text {
                    id: memTipText
                    anchors.centerIn: parent
                    text: "RAM: " + SystemStats.memUsedGb.toFixed(1) + " / " + SystemStats.memTotalGb.toFixed(1) + " GB (" + Math.round(SystemStats.memUsage * 100) + "%)"
                    color: Theme.colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }
    }

    // --- Network icon ---
    Item {
        id: netWidget
        Layout.preferredWidth: 20
        Layout.preferredHeight: 20
        Layout.alignment: Qt.AlignVCenter

        Text {
            anchors.centerIn: parent
            text: "\uf0ac"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 15
            color: (SystemStats.netDownBytes > 1024 || SystemStats.netUpBytes > 1024) ? Theme.colors.accent : Theme.colors.textMuted
            Behavior on color { ColorAnimation { duration: 300 } }
        }

        HoverHandler { id: netHover; cursorShape: Qt.PointingHandCursor }

        PopupWindow {
            id: netTip
            visible: netHover.hovered

            anchor.item: netWidget
            anchor.rect.x: (netWidget.width - width) / 2
            anchor.rect.y: netWidget.height + 4

            implicitWidth: netTipText.implicitWidth + 14
            implicitHeight: netTipText.implicitHeight + 10
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: Theme.colors.bg1
                border.color: Theme.colors.border
                border.width: 1

                Text {
                    id: netTipText
                    anchors.centerIn: parent
                    text: "\u2193 " + SystemStats.netDown + "  \u2191 " + SystemStats.netUp
                    color: Theme.colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }
    }

    // --- Language indicator ---
    Item {
        Layout.preferredWidth: langText.implicitWidth + 4
        Layout.preferredHeight: 16
        Layout.alignment: Qt.AlignVCenter

        Rectangle {
            anchors.fill: parent
            anchors.margins: -4
            radius: 6
            color: Theme.colors.bg1
            opacity: langHover.hovered ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 150 } }
        }

        Text {
            id: langText
            anchors.centerIn: parent
            text: SystemStats.inputLocale
            color: Theme.colors.textMuted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
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
