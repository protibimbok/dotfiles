import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

ColumnLayout {
    Layout.fillWidth: true
    spacing: 16

    Text {
        text: "Performance mode"
        color: Theme.colors.textMuted
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 11
        font.weight: Font.Medium
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Repeater {
            model: ["Powersave", "Balanced", "Performance"]

            Rectangle {
                required property string modelData
                required property int index
                property bool active: SystemStats.perfMode === modelData.toLowerCase()

                Layout.fillWidth: true
                Layout.preferredHeight: 32
                radius: height / 2
                color: active ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.2) : Theme.colors.bg1
                Behavior on color { ColorAnimation { duration: 200 } }

                Text {
                    anchors.centerIn: parent
                    text: modelData
                    color: active ? Theme.colors.accent : Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: SystemStats.setPerfMode(modelData.toLowerCase())
                }
            }
        }
    }
}
