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
    color: Wifi.enabled
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
                    text: "\uf1eb"
                    color: Wifi.enabled ? Theme.colors.primary : Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.iconLg
                    Behavior on color { ColorAnimation { duration: Durations.colorTransition } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Wi-Fi"
                        color: Theme.colors.foreground
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.body
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            if (!Wifi.enabled)
                                return "Off";
                            if (Wifi.busyMessage.length > 0)
                                return Wifi.busyMessage;
                            if (Wifi.nmConnecting)
                                return "Connecting…";
                            if (Wifi.connected) {
                                let s = (Wifi.activeSsid || Wifi.ssid || "Connected").trim();
                                return s.length > 0 ? s : "Connected";
                            }
                            return "Not connected";
                        }
                        color: Theme.colors.foregroundMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.label
                        elide: Text.ElideRight
                    }
                }
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Wifi.setEnabled(!Wifi.enabled) }
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
                color: wifiChevHov.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.label
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            HoverHandler { id: wifiChevHov; cursorShape: Qt.PointingHandCursor }
            TapHandler {
                onTapped: {
                    shellRoot.qsSubview = "wifi";
                    Wifi.scan();
                }
            }
        }
    }
}
