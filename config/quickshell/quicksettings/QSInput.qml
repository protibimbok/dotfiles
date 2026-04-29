import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

ColumnLayout {
    Layout.fillWidth: true
    spacing: 16

    Text {
        text: "Audio input"
        color: Theme.colors.textMuted
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.weight: Font.Medium
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            visible: Audio.sources.length === 0
            text: "No input devices"
            color: Theme.colors.textMuted
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignHCenter
            topPadding: 4
            bottomPadding: 4
        }

        Repeater {
            model: Audio.sources.length

            Rectangle {
                required property int index
                readonly property var row: index >= 0 && index < Audio.sources.length ? Audio.sources[index] : null

                visible: row !== null
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                radius: 10
                color: srcHover.hovered ? Qt.rgba(Theme.colors.bg1.r, Theme.colors.bg1.g, Theme.colors.bg1.b, 0.4) : "transparent"
                Behavior on color { ColorAnimation { duration: 150 } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Item {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        Text {
                            anchors.centerIn: parent
                            text: "\uf130"
                            color: Theme.colors.textMuted
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: row ? row.description : ""
                        color: Theme.colors.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }

                    Item {
                        visible: row && row.isDefault
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20

                        Text {
                            anchors.centerIn: parent
                            text: "\uf00c"
                            color: Theme.colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }
                    }
                }

                HoverHandler { id: srcHover }
                TapHandler {
                    onTapped: {
                        if (row) Audio.setDefaultSource(row.name);
                    }
                }
            }
        }
    }
}
