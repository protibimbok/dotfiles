import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.tokens
import qs.services.network

// One saved Bluetooth device in the BluetoothPanel list: a device glyph + name and a
// "Connected"/"Connecting" tag. Tapping connects (or disconnects the active one).
// modelData is a Bluetooth.devices entry ({ address, name }).
Item {
    id: root

    required property var modelData

    implicitHeight: Metrics.listRowHeight

    readonly property string _status: Bluetooth.connectionStatusFor(root.modelData.address)
    readonly property bool _connected: _status === "Connected"
    readonly property string _name: Bluetooth.displayName(root.modelData.name, root.modelData.address)

    readonly property string _glyph: {
        if (/head|bud|airpod/.test(root._name.toLowerCase()))
            return "\u{f02cb}"; // 󰋋 headphones
        return "\u{f00af}";     // 󰂯 bluetooth
    }

    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        onTapped: {
            if (root._connected)
                Bluetooth.disconnectFrom(root.modelData.address);
            else
                Bluetooth.connectTo(root.modelData.address);
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Metrics.rowRadius
        color: hov.hovered ? Theme.colors.surfaceHigh : "transparent"
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Spacing.sm
        anchors.rightMargin: Spacing.sm
        spacing: Spacing.md

        Text {
            text: root._glyph
            color: root._connected ? Theme.pillAccent : Theme.pillText
            font.family: Typography.fontFamily
            font.pixelSize: Typography.iconMd
        }

        Text {
            Layout.fillWidth: true
            text: root._name
            color: Theme.pillText
            font.family: Typography.fontFamily
            font.pixelSize: Typography.body
            font.bold: root._connected
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            visible: root._status.length > 0
            text: root._status
            color: Theme.pillTextMuted
            font.family: Typography.fontFamily
            font.pixelSize: Typography.bodySm
        }
    }
}
