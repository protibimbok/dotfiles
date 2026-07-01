import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.tokens
import qs.services.network

// One Wi-Fi network in the WifiPanel list: signal glyph + SSID, a lock for secured
// networks, and a "Connected"/"Saved" tag. Tapping connects (or disconnects the
// active one); a new secured network hands off to the Impala TUI for the passphrase.
// modelData is a Wifi.networks entry.
Item {
    id: root

    required property var modelData

    implicitHeight: Metrics.listRowHeight

    readonly property string _status: {
        let transient = Wifi.connectionStatusFor(root.modelData.ssid);
        if (transient.length)
            return transient;
        if (root.modelData.connected)
            return "Connected";
        if (root.modelData.known)
            return "Saved";
        return "";
    }

    readonly property string _signalGlyph: {
        if (modelData.strength > 0.75) return "\u{f0928}"; // 󰤨
        if (modelData.strength > 0.5) return "\u{f0925}";  // 󰤥
        if (modelData.strength > 0.25) return "\u{f0922}"; // 󰤢
        return "\u{f091f}";                                // 󰤟
    }

    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        onTapped: {
            if (root.modelData.connected)
                Wifi.disconnect(root.modelData.ssid);
            else
                Wifi.connectNetwork(root.modelData.ssid);
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
            text: root._signalGlyph
            color: root.modelData.connected ? Theme.pillAccent : Theme.pillText
            font.family: Typography.fontFamily
            font.pixelSize: Typography.iconMd
        }

        Text {
            Layout.fillWidth: true
            text: root.modelData.ssid
            color: Theme.pillText
            font.family: Typography.fontFamily
            font.pixelSize: Typography.body
            font.bold: root.modelData.connected
            elide: Text.ElideRight
            maximumLineCount: 1
        }

        Text {
            visible: !root.modelData.open
            text: "\u{f033e}" // 󰌾 lock
            color: Theme.pillTextMuted
            font.family: Typography.fontFamily
            font.pixelSize: Typography.bodySm
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
