import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services

Item {
    id: root

    anchors.bottom: parent.bottom
    anchors.bottomMargin: 80
    anchors.horizontalCenter: parent.horizontalCenter
    width: 280
    height: 64

    property string _type: "volume"
    property int _value: 0
    property bool _shown: false
    property bool _ready: false

    Timer {
        id: readyTimer
        interval: 3000
        running: true
        onTriggered: root._ready = true
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: root._shown = false
    }

    Connections {
        target: Audio
        function onVolumeChanged() {
            if (!root._ready) return;
            root._type = "volume";
            root._value = Audio.volume;
            root._shown = true;
            hideTimer.restart();
        }
    }

    Connections {
        target: SystemStats
        function onBrightnessChanged() {
            if (!root._ready) return;
            root._type = "brightness";
            root._value = SystemStats.brightness;
            root._shown = true;
            hideTimer.restart();
        }
    }

    opacity: _shown ? 1.0 : 0.0
    Behavior on opacity {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }
    property bool windowVisible: opacity > 0.01

    Rectangle {
        anchors.fill: parent
        radius: 32
        color: Theme.colors.bg
        opacity: 0.92

        layer.enabled: true
    }

    Rectangle {
        anchors.fill: parent
        radius: 32
        color: "transparent"
        border.color: Theme.colors.border
        border.width: 1
        opacity: 0.3
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 12

        Text {
            text: {
                if (root._type === "volume") {
                    if (Audio.muted) return "\uf026";
                    if (root._value >= 70) return "\uf028";
                    if (root._value >= 30) return "\uf027";
                    return "\uf026";
                }
                if (root._value >= 70) return "\uf185";
                if (root._value >= 30) return "\uf0eb";
                return "\uf186";
            }
            color: Theme.colors.accent
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Theme.colors.bg2

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root._value)) / 100
                height: parent.height
                radius: parent.radius
                color: Theme.colors.accent

                Behavior on width {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            text: root._value + "%"
            color: Theme.colors.text
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13
            font.bold: true
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }
}
