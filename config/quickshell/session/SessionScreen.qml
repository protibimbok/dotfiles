import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Io
import qs.theme
import qs.tokens

Item {
    id: root

    required property var shellRoot
    signal close()

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.55
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        anchors.centerIn: parent
        width: Metrics.sessionPanelWidth
        height: Metrics.sessionPanelHeight

        MouseArea { anchors.fill: parent }

        GridLayout {
            anchors.fill: parent
            columns: 2
            rows: 2
            columnSpacing: Spacing.xxl
            rowSpacing: Spacing.xxl

            Repeater {
                model: [
                    { label: "Lock",     icon: "\uf023", color: "accent",    action: "lock" },
                    { label: "Logout",   icon: "\uf2f5", color: "yellow",    cmd: ["loginctl", "terminate-user", ""] },
                    { label: "Reboot",   icon: "\uf021", color: "cyan",      cmd: ["systemctl", "reboot"] },
                    { label: "Shutdown", icon: "\uf011", color: "red",       cmd: ["systemctl", "poweroff"] }
                ]

                Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Metrics.sessionTileRadius
                    color: btnHover.hovered
                        ? Qt.rgba(accentColor.r, accentColor.g, accentColor.b, 0.18)
                        : Theme.surfaceTint(Theme.colors.surface, 0.85)

                    Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }

                    property color accentColor: {
                        if (modelData.color === "accent") return Theme.colors.primary;
                        if (modelData.color === "yellow") return Theme.colors.warning;
                        if (modelData.color === "cyan") return Theme.colors.info;
                        return Theme.colors.error;
                    }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        autoPaddingEnabled: true
                        shadowEnabled: true
                        shadowBlur: 0.8
                        shadowColor: "#40000000"
                        shadowVerticalOffset: 4
                    }

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Spacing.md

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.icon
                            color: parent.parent.accentColor
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.display
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: Theme.colors.foreground
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.title
                            font.bold: true
                        }
                    }

                    HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            if (modelData.action === "lock") {
                                root.shellRoot.lockSession();
                                root.close();
                                return;
                            }
                            cmdProc.command = modelData.cmd;
                            cmdProc.running = true;
                            root.close();
                        }
                    }
                }
            }
        }
    }

    Keys.onEscapePressed: root.close()

    Process { id: cmdProc }
}
