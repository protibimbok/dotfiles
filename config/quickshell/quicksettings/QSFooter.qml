import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import qs.theme
import qs.tokens

RowLayout {
    id: root

    required property var shellRoot
    signal requestClose()

    Layout.fillWidth: true
    Layout.topMargin: 2
    spacing: Spacing.tileInnerTop

    Item { Layout.fillWidth: true }

    // ── Lock | Power pill (right) ─────────────────────────────────────────

    Rectangle {
        id: actionPill
        Layout.preferredHeight: Metrics.footerBtnHeight
        Layout.preferredWidth: 153
        radius: height / 2
        color: Theme.colors.surface
        border.width: 1
        border.color: Theme.colors.outline
        opacity: 0.95

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.topMargin: 4
            anchors.bottomMargin: 4
            spacing: Spacing.rowGap

            Item {
                id: lockBtn
                Layout.fillHeight: true
                Layout.preferredWidth: Metrics.footerActionSize

                Rectangle {
                    anchors.fill: parent
                    radius: (actionPill.height - 8) / 2
                    color: lockHov.hovered
                        ? Theme.primaryTint(0.12)
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf023"
                        color: lockHov.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.iconMd
                    }
                    HoverHandler { id: lockHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            root.shellRoot.lockSession();
                            root.requestClose();
                        }
                    }
                }
            }

            Rectangle {
                id: divBar
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.colors.outline
                opacity: 0.55
            }

            Item {
                id: rebootBtn
                Layout.fillHeight: true
                Layout.preferredWidth: Metrics.footerActionSize

                Rectangle {
                    anchors.fill: parent
                    radius: (actionPill.height - 8) / 2
                    color: rebootHov.hovered
                        ? Theme.primaryTint(0.12)
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf021"
                        color: rebootHov.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.iconMd
                    }
                    HoverHandler { id: rebootHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            rebootProc.running = true;
                            root.requestClose();
                        }
                    }
                }
            }

            Rectangle {
                id: div2Bar
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.colors.outline
                opacity: 0.55
            }

            Item {
                id: pwrBtn
                Layout.fillHeight: true
                Layout.preferredWidth: Metrics.footerActionSize

                Rectangle {
                    anchors.fill: parent
                    radius: (actionPill.height - 8) / 2
                    color: pwrHov.hovered
                        ? Theme.errorTint(0.18)
                        : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "\uf011"
                        color: pwrHov.hovered ? Theme.colors.error : Theme.colors.foregroundMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.iconMd
                    }
                    HoverHandler { id: pwrHov; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            powerProc.running = true;
                            root.requestClose();
                        }
                    }
                }
            }
        }
    }

    Process {
        id: powerProc
        command: ["systemctl", "poweroff"]
    }

    Process {
        id: rebootProc
        command: ["systemctl", "reboot"]
    }
}
