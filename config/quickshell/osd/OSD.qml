import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.tokens

Item {
    id: root

    anchors.bottom: parent.bottom
    anchors.bottomMargin: Metrics.osdBottomMargin
    anchors.horizontalCenter: parent.horizontalCenter
    width: Metrics.osdWidth
    height: Metrics.osdHeight

    property string _type: "volume"
    property int _value: 0
    property bool _shown: false
    property bool _ready: false

    Timer {
        id: readyTimer
        interval: Durations.readyDelay
        running: true
        onTriggered: root._ready = true
    }

    Timer {
        id: hideTimer
        interval: Durations.osdHide
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
        NumberAnimation { duration: Durations.fade; easing.type: Easing.OutCubic }
    }
    property bool windowVisible: opacity > 0.01

    Rectangle {
        anchors.fill: parent
        radius: Metrics.panelRadiusLarge
        color: Theme.colors.background
        opacity: 0.92

        layer.enabled: true
    }

    Rectangle {
        anchors.fill: parent
        radius: Metrics.panelRadiusLarge
        color: "transparent"
        border.color: Theme.colors.outline
        border.width: 1
        opacity: 0.3
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Spacing.panelContentMarginLg
        anchors.rightMargin: Spacing.panelContentMarginLg
        spacing: Spacing.lg

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
            color: Theme.colors.primary
            font.family: Typography.fontFamily
            font.pixelSize: Typography.iconLg
        }

        Rectangle {
            Layout.fillWidth: true
            height: Metrics.trackHeight + 1
            radius: Metrics.trackRadius
            color: Theme.colors.surfaceHigh

            Rectangle {
                width: parent.width * Math.max(0, Math.min(100, root._value)) / 100
                height: parent.height
                radius: parent.radius
                color: Theme.colors.primary

                Behavior on width {
                    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            text: root._value + "%"
            color: Theme.colors.foreground
            font.family: Typography.fontFamily
            font.pixelSize: Typography.title
            font.bold: true
            Layout.preferredWidth: 38
            horizontalAlignment: Text.AlignRight
        }
    }
}
