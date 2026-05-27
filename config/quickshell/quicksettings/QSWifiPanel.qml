import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import qs.theme
import qs.services
import qs.services.network
import "components" as Qsc
import qs.tokens

ColumnLayout {
    id: root

    required property var shellRoot

    spacing: 0

    onVisibleChanged: if (visible)
        Wifi.scan()

    function goBack() {
        shellRoot.qsSubview = "main";
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.bottomMargin: 10

        Item {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 32

            Text {
                anchors.centerIn: parent
                text: "\uf053"
                color: wifiBackHov.hovered ? Theme.colors.text : Theme.colors.textMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.header
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            HoverHandler { id: wifiBackHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.goBack() }
        }

        Text {
            text: "Wifi"
            color: Theme.colors.text
            font.family: Typography.fontFamily
            font.pixelSize: Typography.title
            font.bold: true
        }

        Item { Layout.fillWidth: true }

        RowLayout {
            spacing: Spacing.xs

            Qsc.QSHeaderIconButton {
                iconGlyph: "\uf021"
                spinning: Wifi.scanning
                active: Wifi.enabled && !Wifi.scanning
                onActivated: Wifi.scan()
            }

            Qsc.QSHeaderIconButton {
                iconGlyph: "\uf08e"
                spinning: false
                active: true
                onActivated: {
                    Wifi.openSettings();
                    root.goBack();
                }
            }

            QSAccentToggle {
                checked: Wifi.enabled
                onTriggered: Wifi.setEnabled(!Wifi.enabled)
            }
        }
    }

    Text {
        Layout.bottomMargin: 4
        text: "Tap a network to connect or disconnect; use the menu for Forget and settings"
        color: Theme.colors.textMuted
        font.family: Typography.fontFamily
        font.pixelSize: Typography.caption
        wrapMode: Text.WordWrap
        Layout.fillWidth: true
    }

    Connections {
        target: Wifi
        function onConnectFinished(ssid, success, canPromptPassword, rowKey) {
            if (!canPromptPassword)
                return;
            if (success) {
                wifiNetCol.expandedWifiKey = "";
                wifiNetCol.wifiPwdErrorKey = "";
            } else {
                wifiNetCol.expandedWifiKey = rowKey;
                wifiNetCol.wifiPwdErrorKey = rowKey;
            }
        }
    }

    Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        radius: Metrics.listRadius
        color: Theme.colors.bg1
        clip: true

        Flickable {
            id: wifiFlick
            anchors.fill: parent
            anchors.margins: 6
            contentWidth: width
            contentHeight: wifiNetCol.height
            clip: true

            Column {
                id: wifiNetCol
                width: wifiFlick.width
                spacing: Spacing.rowGap

                property string expandedWifiKey: ""
                property string wifiPwdErrorKey: ""

                Repeater {
                    model: Wifi.networks

                    delegate: Column {
                        id: wifiNetRow
                        required property var modelData
                        width: wifiNetCol.width
                        spacing: 0

                        property bool isThisActive: Wifi.connected
                            && modelData.ssid.length > 0
                            && Wifi.activeSsid === modelData.ssid
                        property bool isRowConnecting: Wifi.connectPendingRowKey.length > 0
                            && Wifi.connectPendingRowKey === modelData.rowKey
                        property bool isSaved: {
                            let s = modelData.ssid;
                            let list = Wifi.savedSsids;
                            if (!s || !list || !list.length)
                                return false;
                            for (let i = 0; i < list.length; i++) {
                                if (list[i] === s)
                                    return true;
                            }
                            return false;
                        }
                        property bool isExpanded: wifiNetCol.expandedWifiKey.length > 0
                            && wifiNetCol.expandedWifiKey === modelData.rowKey
                        property bool isSecured: {
                            let sec = (modelData.security || "").toLowerCase();
                            return !(sec === "--" || sec === "" || sec === "none");
                        }

                        Rectangle {
                            width: parent.width
                            height: Metrics.listRowHeight
                            radius: Metrics.rowRadius
                            color: {
                                let h = netDelHov.hovered;
                                let base = h
                                    ? Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.12)
                                    : "transparent";
                                if (wifiNetRow.isThisActive || wifiNetRow.isRowConnecting)
                                    return Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, h ? 0.18 : 0.08);
                                return base;
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 4
                                spacing: Spacing.xs

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: Spacing.md

                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.ssid || "(hidden)"
                                            color: Theme.colors.text
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.bodySm
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            Layout.preferredWidth: 88
                                            horizontalAlignment: Text.AlignRight
                                            text: {
                                                if (wifiNetRow.isRowConnecting)
                                                    return "Connecting…";
                                                if (wifiNetRow.isThisActive)
                                                    return "Connected";
                                                return modelData.signal + "%";
                                            }
                                            color: (wifiNetRow.isRowConnecting || wifiNetRow.isThisActive)
                                                ? Theme.colors.accent
                                                : Theme.colors.textMuted
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.label
                                        }
                                    }

                                    HoverHandler { id: netDelHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            let ssid = modelData.ssid || "";
                                            let rk = modelData.rowKey || ssid;
                                            let sec = (modelData.security || "").toLowerCase();
                                            let open = sec === "--" || sec === "" || sec === "none";
                                            if (Wifi.connected && ssid.length > 0
                                                && Wifi.activeSsid === ssid) {
                                                Wifi.disconnect();
                                                return;
                                            }
                                            if (open) {
                                                Wifi.connectOpen(ssid, rk);
                                                wifiNetCol.expandedWifiKey = "";
                                                wifiNetCol.wifiPwdErrorKey = "";
                                                return;
                                            }
                                            if (!wifiNetRow.isSaved) {
                                                wifiNetCol.expandedWifiKey = rk;
                                                wifiNetCol.wifiPwdErrorKey = "";
                                                return;
                                            }
                                            if (wifiNetRow.isExpanded) {
                                                Wifi.tryConnect(ssid, "", rk);
                                                return;
                                            }
                                            wifiNetCol.wifiPwdErrorKey = "";
                                            Wifi.tryConnect(ssid, "", rk);
                                        }
                                    }
                                }

                                Rectangle {
                                    id: netMenuBtn
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: Metrics.rowRadiusSm
                                    color: netMenuHov.hovered ? Theme.colors.bg2 : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf142"
                                        color: netMenuHov.hovered ? Theme.colors.text : Theme.colors.textMuted
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.body
                                    }

                                    HoverHandler { id: netMenuHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: wifiCtxMenu.popup(netMenuBtn)
                                    }

                                    QQC2.Menu {
                                        id: wifiCtxMenu
                                        parent: netMenuBtn

                                        QQC2.MenuItem {
                                            text: "Disconnect"
                                            visible: wifiNetRow.isThisActive
                                            onTriggered: Wifi.disconnect()
                                        }
                                        QQC2.MenuItem {
                                            text: "Forget network"
                                            visible: wifiNetRow.isSaved
                                            onTriggered: {
                                                Wifi.forget(modelData.ssid);
                                                if (wifiNetCol.expandedWifiKey === modelData.rowKey) {
                                                    wifiNetCol.expandedWifiKey = "";
                                                    wifiNetCol.wifiPwdErrorKey = "";
                                                }
                                            }
                                        }
                                        QQC2.MenuItem {
                                            text: "Open network settings"
                                            onTriggered: {
                                                Wifi.openSettings();
                                                root.goBack();
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            visible: parent.isExpanded && parent.isSecured
                            height: visible ? pwdBlock.implicitHeight + 8 : 0

                            ColumnLayout {
                                id: pwdBlock
                                width: parent.width
                                spacing: Spacing.sm

                                Text {
                                    visible: wifiNetCol.wifiPwdErrorKey === modelData.rowKey
                                    Layout.fillWidth: true
                                    text: "Incorrect password"
                                    color: Theme.colors.red
                                    font.family: Typography.fontFamily
                                    font.pixelSize: Typography.label
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Spacing.md

                                    QQC2.TextField {
                                        id: wifiPwdField
                                        Layout.fillWidth: true
                                        implicitHeight: 30
                                        placeholderText: "Password"
                                        echoMode: TextInput.Password
                                        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData
                                        color: Theme.colors.text
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.bodySm
                                        selectionColor: Theme.colors.accent
                                        background: Rectangle {
                                            radius: Metrics.rowRadius
                                            color: Theme.colors.bg2
                                            border.color: Theme.colors.border
                                            border.width: 1
                                        }
                                        onTextChanged: {
                                            if (wifiNetCol.wifiPwdErrorKey === modelData.rowKey)
                                                wifiNetCol.wifiPwdErrorKey = "";
                                        }
                                        Keys.onReturnPressed: Wifi.tryConnect(modelData.ssid, wifiPwdField.text, modelData.rowKey)
                                    }

                                    Rectangle {
                                        Layout.preferredWidth: 72
                                        Layout.preferredHeight: 30
                                        radius: Metrics.rowRadius
                                        color: wifiConnBtnHov.hovered ? Theme.colors.bg2 : Theme.colors.bg1
                                        border.color: Theme.colors.border
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Connect"
                                            color: Theme.colors.text
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.label
                                        }
                                        HoverHandler { id: wifiConnBtnHov; cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: Wifi.tryConnect(modelData.ssid, wifiPwdField.text, modelData.rowKey)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Text {
        Layout.fillWidth: true
        Layout.topMargin: 8
        visible: text.length > 0
        height: visible ? contentHeight : 0
        wrapMode: Text.WordWrap
        text: {
            if (Wifi.busyMessage.length > 0)
                return Wifi.busyMessage;
            if (Wifi.nmConnecting)
                return "Connecting…";
            return "";
        }
        color: Theme.colors.accent
        font.family: Typography.fontFamily
        font.pixelSize: Typography.label
    }
}
