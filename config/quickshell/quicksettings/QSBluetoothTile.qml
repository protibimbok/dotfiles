import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.services.network
import qs.tokens

Rectangle {
    id: root

    required property var shellRoot

    Layout.fillWidth: true
    Layout.preferredHeight: 64
    radius: Metrics.tileRadius
    color: Bluetooth.enabled
        ? Theme.primaryTint(0.15)
        : Theme.colors.surface
    Behavior on color { ColorAnimation { duration: Durations.colorTransition } }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: Spacing.tileInnerTop

                Text {
                    text: "\uf294"
                    color: Bluetooth.enabled ? Theme.colors.primary : Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.iconLg
                    Behavior on color { ColorAnimation { duration: Durations.colorTransition } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Bluetooth"
                        color: Theme.colors.foreground
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.body
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: !Bluetooth.enabled ? "Off"
                            : (Bluetooth.connected
                                ? (Bluetooth.device || "Connected")
                                : "On")
                        color: Theme.colors.foregroundMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.label
                        elide: Text.ElideRight
                    }
                }
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Bluetooth.setEnabled(!Bluetooth.enabled) }
        }

        Rectangle {
            width: 1
            height: Metrics.iconMuteBtn
            color: Theme.colors.outline
            opacity: 0.4
        }

        Item {
            Layout.preferredWidth: 36
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "\uf054"
                color: btChevHov.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.label
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            HoverHandler { id: btChevHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    shellRoot.qsSubview = "bluetooth";
                    Bluetooth.refresh();
                }
            }
        }
    }
}
