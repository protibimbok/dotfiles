import QtQuick
import QtQuick.Layouts
import qs.theme

Item {
    id: root

    property string iconText: ""
    property int value: 0
    property int minimum: 0
    property int maximum: 100
    property color trackColor: Theme.colors.accent

    signal moved(int value)
    signal iconTapped()

    implicitHeight: 32

    RowLayout {
        anchors.fill: parent
        spacing: 10

        Item {
            Layout.preferredWidth: 24
            Layout.preferredHeight: 24

            Text {
                anchors.centerIn: parent
                text: root.iconText
                color: Theme.colors.accent
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 15
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.iconTapped() }
        }

        Item {
            id: track
            Layout.fillWidth: true
            Layout.preferredHeight: 8

            Rectangle {
                anchors.fill: parent
                radius: 4
                color: Theme.colors.bg1
            }

            Rectangle {
                height: parent.height
                width: parent.width * Math.max(0, Math.min(1, (root.value - root.minimum) / Math.max(1, root.maximum - root.minimum)))
                radius: 4
                color: root.trackColor
            }

            TapHandler {
                onTapped: ev => {
                    let pct = Math.max(0, Math.min(1, ev.position.x / track.width));
                    let v = Math.round(root.minimum + pct * (root.maximum - root.minimum));
                    root.moved(v);
                }
            }
        }

        Text {
            Layout.preferredWidth: 32
            horizontalAlignment: Text.AlignRight
            text: root.value + "%"
            color: Theme.colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 11
        }
    }
}
