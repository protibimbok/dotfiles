import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root

    Layout.fillWidth: true
    implicitHeight: visible ? content.implicitHeight : 0
    visible: Mpris.isActive

    Behavior on implicitHeight {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 52
                height: 52
                radius: 8
                color: Theme.colors.bg2
                clip: true

                Image {
                    anchors.fill: parent
                    source: Mpris.artUrl
                    fillMode: Image.PreserveAspectCrop
                    visible: Mpris.artUrl !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "\uf001"
                    color: Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 20
                    visible: Mpris.artUrl === ""
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: Mpris.title || "Unknown"
                    color: Theme.colors.text
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                    font.bold: true
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: Mpris.artist || Mpris.playerName
                    color: Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            Repeater {
                model: [
                    { icon: "\uf04a", action: "prev" },
                    { icon: Mpris.status === "Playing" ? "\uf04c" : "\uf04b", action: "playpause" },
                    { icon: "\uf04e", action: "next" }
                ]

                Item {
                    required property var modelData
                    width: 36
                    height: 36

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: btnHover.hovered ? Theme.colors.bg2 : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        color: btnHover.hovered ? Theme.colors.text : Theme.colors.textMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 16
                        Behavior on color { ColorAnimation { duration: 120 } }
                    }

                    HoverHandler { id: btnHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: {
                            if (modelData.action === "prev") Mpris.previous();
                            else if (modelData.action === "playpause") Mpris.playPause();
                            else if (modelData.action === "next") Mpris.next();
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.colors.border
            opacity: 0.2
        }
    }
}
