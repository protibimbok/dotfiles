import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.services.network
import "components" as Qsc

ColumnLayout {
    id: root

    required property var shellRoot

    spacing: 0

    onVisibleChanged: if (visible) {
        Bluetooth.refresh();
        if (Bluetooth.enabled)
            Bluetooth.startScan();
    }

    function goBack() {
        shellRoot.qsSubview = "main";
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 10

        Item {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 32

            Text {
                anchors.centerIn: parent
                text: "\uf053"
                color: btBackHov.hovered ? Theme.colors.text : Theme.colors.textMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 14
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            HoverHandler { id: btBackHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.goBack() }
        }

        Text {
            text: "Bluetooth"
            color: Theme.colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: 4

            Qsc.QSHeaderIconButton {
                iconGlyph: "\uf021"
                spinning: Bluetooth.scanning
                active: Bluetooth.enabled && !Bluetooth.scanning
                onActivated: Bluetooth.startScan()
            }

            Qsc.QSHeaderIconButton {
                iconGlyph: "\uf08e"
                spinning: false
                active: true
                onActivated: {
                    Bluetooth.openSettings();
                    root.goBack();
                }
            }

            QSAccentToggle {
                checked: Bluetooth.enabled
                onTriggered: Bluetooth.setEnabled(!Bluetooth.enabled)
            }
        }
    }

    Text {
        Layout.bottomMargin: 4
        text: "Devices"
        color: Theme.colors.textMuted
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 9
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        radius: 12
        color: Theme.colors.bg1
        clip: true

        Flickable {
            id: btFlick
            anchors.fill: parent
            anchors.margins: 6
            contentWidth: width
            contentHeight: btDevCol.height
            clip: true

            Column {
                id: btDevCol
                width: btFlick.width
                spacing: 2

                Repeater {
                    model: Bluetooth.devices

                    delegate: Rectangle {
                        required property var modelData
                        width: btDevCol.width
                        height: 36
                        radius: 8
                        color: btDelHov.hovered
                            ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.12)
                            : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8

                            Text {
                                Layout.fillWidth: true
                                text: Bluetooth.displayName(modelData.name, modelData.address)
                                color: Theme.colors.text
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                            Text {
                                text: {
                                    Bluetooth.connectingAddress;
                                    Bluetooth.connectedAddresses;
                                    return Bluetooth.connectionStatusFor(modelData.address);
                                }
                                color: Theme.colors.textMuted
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                            }
                        }
                        HoverHandler { id: btDelHov; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Bluetooth.connectTo(modelData.address) }
                    }
                }
            }
        }
    }
}
