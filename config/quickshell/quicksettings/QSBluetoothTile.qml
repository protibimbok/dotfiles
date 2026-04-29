import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.services.network

Rectangle {
    id: root

    required property var shellRoot

    Layout.fillWidth: true
    Layout.preferredHeight: 64
    radius: 14
    color: Bluetooth.enabled
        ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.15)
        : Theme.colors.bg1
    Behavior on color { ColorAnimation { duration: 180 } }

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
                spacing: 10

                Text {
                    text: "\uf294"
                    color: Bluetooth.enabled ? Theme.colors.accent : Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 18
                    Behavior on color { ColorAnimation { duration: 180 } }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "Bluetooth"
                        color: Theme.colors.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Text {
                        Layout.fillWidth: true
                        text: !Bluetooth.enabled ? "Off"
                            : (Bluetooth.connected
                                ? (Bluetooth.device || "Connected")
                                : "On")
                        color: Theme.colors.textMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }
                }
            }

            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: Bluetooth.setEnabled(!Bluetooth.enabled) }
        }

        Rectangle {
            width: 1
            height: 28
            color: Theme.colors.border
            opacity: 0.4
        }

        Item {
            Layout.preferredWidth: 36
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                text: "\uf054"
                color: btChevHov.hovered ? Theme.colors.text : Theme.colors.textMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
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
