import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root

    property bool active: false
    property string title: ""
    property string subtitle: ""
    property string iconText: ""

    signal toggled()

    implicitWidth: 140
    implicitHeight: 52

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: root.active ? Theme.colors.accent : Theme.colors.bg1
        opacity: root.active ? 0.85 : 0.6
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Text {
            text: root.iconText
            color: root.active ? Theme.colors.bg : Theme.colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }

        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true

            Text {
                text: root.title
                color: root.active ? Theme.colors.bg : Theme.colors.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: root.subtitle
                visible: root.subtitle.length > 0
                color: root.active ? Theme.colors.bg : Theme.colors.textMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
    TapHandler { onTapped: root.toggled() }
}
