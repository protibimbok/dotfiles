import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.services
import qs.tokens

Item {
    id: root

    anchors.top: parent.top
    anchors.topMargin: Spacing.panelTopMargin
    anchors.right: parent.right
    anchors.rightMargin: Spacing.panelSideMargin
    width: Metrics.toastColumnWidth

    property int count: toastModel.count

    implicitHeight: toastColumn.implicitHeight

    property bool _ready: false
    property string _prevSinkName: ""
    property string _prevSourceName: ""
    property bool _prevCharging: false
    property bool _prevCapsLock: false

    Timer {
        id: readyTimer
        interval: Durations.readyDelay
        running: true
        onTriggered: {
            root._ready = true;
            root._prevSinkName = Audio.defaultSinkName;
            root._prevSourceName = Audio.defaultSourceName;
            root._prevCharging = SystemStats.batteryCharging;
            root._prevCapsLock = SystemStats.capsLock;
        }
    }

    Connections {
        target: Audio
        function onDefaultSinkNameChanged() {
            if (!root._ready) return;
            let name = Audio.defaultSinkName;
            if (!name || name === root._prevSinkName) return;
            root._prevSinkName = name;
            let sinks = Audio.sinks;
            let label = name;
            for (let s of sinks) {
                if (s.name === name) { label = s.description; break; }
            }
            root.addToast("\uf028", "Output", label);
        }
        function onDefaultSourceNameChanged() {
            if (!root._ready) return;
            let name = Audio.defaultSourceName;
            if (!name || name === root._prevSourceName) return;
            root._prevSourceName = name;
            let sources = Audio.sources;
            let label = name;
            for (let s of sources) {
                if (s.name === name) { label = s.description; break; }
            }
            root.addToast("\uf130", "Input", label);
        }
    }

    Connections {
        target: SystemStats
        function onBatteryChargingChanged() {
            if (!root._ready) return;
            if (SystemStats.batteryCharging === root._prevCharging) return;
            root._prevCharging = SystemStats.batteryCharging;
            if (SystemStats.batteryCharging) {
                root.addToast("\uf1e6", "Power", "Plugged in");
            } else {
                root.addToast("\uf071", "Power", "Unplugged");
            }
        }
        function onCapsLockChanged() {
            if (!root._ready) return;
            if (SystemStats.capsLock === root._prevCapsLock) return;
            root._prevCapsLock = SystemStats.capsLock;
            root.addToast(SystemStats.capsLock ? "\uf023" : "\uf09c", "Caps Lock",
                          SystemStats.capsLock ? "On" : "Off");
        }
        function onBatteryWarning(level) {
            let icon = level <= 5 ? "\uf244" : level <= 10 ? "\uf243" : "\uf242";
            root.addToast(icon, "Battery", "Low battery (" + level + "%)");
        }
    }

    ListModel { id: toastModel }

    function addToast(icon: string, title: string, message: string) {
        while (toastModel.count >= 4) toastModel.remove(0);
        toastModel.append({ toastIcon: icon, toastTitle: title, toastMsg: message });
    }

    ColumnLayout {
        id: toastColumn
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: Spacing.sm

        Repeater {
            model: toastModel

            Rectangle {
                id: toastItem
                required property var model
                required property int index
                Layout.fillWidth: true
                implicitHeight: Metrics.toastHeight
                radius: Metrics.listRadius
                color: Theme.colors.background
                opacity: 0.0
                clip: true

                layer.enabled: true

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Theme.colors.outline
                    border.width: 1
                    opacity: 0.25
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: Spacing.lg

                    Text {
                        text: model.toastIcon
                        color: Theme.colors.primary
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.iconLg
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: model.toastTitle
                            color: Theme.colors.foreground
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.body
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            text: model.toastMsg
                            color: Theme.colors.foregroundMuted
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.bodySm
                            elide: Text.ElideRight
                        }
                    }
                }

                NumberAnimation on opacity {
                    id: fadeIn
                    from: 0; to: 0.92
                    duration: Durations.fade
                    easing.type: Easing.OutCubic
                    running: true
                }

                Timer {
                    id: lifeTimer
                    interval: Durations.toastLife
                    running: true
                    onTriggered: fadeOut.start()
                }

                NumberAnimation on opacity {
                    id: fadeOut
                    from: 0.92; to: 0
                    duration: Durations.fade
                    easing.type: Easing.InCubic
                    onFinished: {
                        let idx = toastItem.index;
                        if (idx >= 0 && idx < toastModel.count) toastModel.remove(idx);
                    }
                }
            }
        }
    }
}
