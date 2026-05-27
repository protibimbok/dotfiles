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
    else if (wifiNetCol)
        wifiNetCol.openWifiMenuKey = ""

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
                color: wifiBackHov.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.header
                Behavior on color { ColorAnimation { duration: 120 } }
            }

            HoverHandler { id: wifiBackHov; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: root.goBack() }
        }

        Text {
            text: "Wifi"
            color: Theme.colors.foreground
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
        text: "Tap a network to connect; use the menu on saved networks to disconnect or forget"
        color: Theme.colors.foregroundMuted
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
                wifiNetCol.openWifiMenuKey = "";
            } else {
                wifiNetCol.expandedWifiKey = rowKey;
                wifiNetCol.wifiPwdErrorKey = rowKey;
            }
        }
    }

    Rectangle {
        id: listBox
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        radius: Metrics.listRadius
        color: Theme.colors.surface

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
                property string openWifiMenuKey: ""
                property string openWifiMenuSsid: ""
                property real menuPopupX: 0
                property real menuPopupY: 0
                readonly property real menuPopupWidth: Math.min(width * 0.62, 220)
                readonly property bool openWifiMenuActive: openWifiMenuSsid.length > 0
                    && Wifi.connected
                    && Wifi.activeSsid === openWifiMenuSsid

                function openMenu(anchor, rowKey, ssid) {
                    let menuH = Metrics.listRowHeight * 2;
                    let pt = anchor.mapToItem(listBox, 0, anchor.height);
                    menuPopupX = Math.max(4, pt.x + anchor.width - menuPopupWidth);
                    menuPopupY = pt.y + 2;
                    if (menuPopupY + menuH > listBox.height - 4)
                        menuPopupY = Math.max(4, pt.y - anchor.height - menuH - 2);
                    openWifiMenuSsid = ssid || "";
                    Qt.callLater(() => { openWifiMenuKey = rowKey; });
                }

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
                                    ? Theme.primaryTint(0.12)
                                    : "transparent";
                                if (wifiNetRow.isThisActive || wifiNetRow.isRowConnecting)
                                    return Theme.primaryTint(h ? 0.18 : 0.08);
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
                                            color: Theme.colors.foreground
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
                                                ? Theme.colors.primary
                                                : Theme.colors.foregroundMuted
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
                                            wifiNetCol.openWifiMenuKey = "";
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
                                    visible: wifiNetRow.isSaved
                                    Layout.preferredWidth: visible ? 28 : 0
                                    Layout.preferredHeight: 28
                                    radius: Metrics.rowRadiusSm
                                    color: (netMenuHov.hovered || netMenuBtn.isMenuOpen)
                                        ? Theme.colors.surfaceHigh
                                        : "transparent"
                                    Behavior on color { ColorAnimation { duration: 120 } }

                                    property bool isMenuOpen: wifiNetCol.openWifiMenuKey.length > 0
                                        && wifiNetCol.openWifiMenuKey === modelData.rowKey

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\uf142"
                                        color: (netMenuHov.hovered || netMenuBtn.isMenuOpen)
                                            ? Theme.colors.foreground
                                            : Theme.colors.foregroundMuted
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.body
                                    }

                                    HoverHandler { id: netMenuHov; cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: {
                                            let rk = modelData.rowKey || modelData.ssid || "";
                                            if (wifiNetCol.openWifiMenuKey === rk) {
                                                wifiNetCol.openWifiMenuKey = "";
                                                return;
                                            }
                                            wifiNetCol.expandedWifiKey = "";
                                            wifiNetCol.wifiPwdErrorKey = "";
                                            wifiNetCol.openMenu(
                                                netMenuBtn,
                                                rk,
                                                modelData.ssid || ""
                                            );
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
                                    color: Theme.colors.error
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
                                        color: Theme.colors.foreground
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.bodySm
                                        selectionColor: Theme.colors.primary
                                        background: Rectangle {
                                            radius: Metrics.rowRadius
                                            color: Theme.colors.surfaceHigh
                                            border.color: Theme.colors.outline
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
                                        color: wifiConnBtnHov.hovered ? Theme.colors.surfaceHigh : Theme.colors.surface
                                        border.color: Theme.colors.outline
                                        border.width: 1

                                        Text {
                                            anchors.centerIn: parent
                                            text: "Connect"
                                            color: Theme.colors.foreground
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

        Item {
            id: wifiMenuOverlay
            anchors.fill: parent
            visible: wifiNetCol.openWifiMenuKey.length > 0
            z: 10

            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: wifiNetCol.openWifiMenuKey = ""
            }

            Item {
                id: wifiMenuPopup
                z: 1
                x: wifiNetCol.menuPopupX
                y: wifiNetCol.menuPopupY
                width: wifiNetCol.menuPopupWidth
                height: Metrics.listRowHeight * 2

                Rectangle {
                    anchors.fill: parent
                    radius: Metrics.rowRadius
                    color: Theme.colors.surfaceHighest
                    border.color: Theme.colors.outline
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 1
                        spacing: 0

                        Rectangle {
                            width: parent.width
                            height: Metrics.listRowHeight
                            radius: Metrics.rowRadiusSm
                            color: wifiMenuConnHov.hovered
                                ? Theme.primaryTint(0.12)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: wifiNetCol.openWifiMenuActive ? "Disconnect" : "Connect"
                                color: Theme.colors.foreground
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.bodySm
                            }

                            HoverHandler { id: wifiMenuConnHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    let ssid = wifiNetCol.openWifiMenuSsid;
                                    let rk = wifiNetCol.openWifiMenuKey;
                                    let active = wifiNetCol.openWifiMenuActive;
                                    wifiNetCol.openWifiMenuKey = "";
                                    if (active) {
                                        Wifi.disconnect();
                                        return;
                                    }
                                    wifiNetCol.wifiPwdErrorKey = "";
                                    Wifi.tryConnect(ssid, "", rk);
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: Metrics.listRowHeight
                            radius: Metrics.rowRadiusSm
                            color: wifiMenuForgetHov.hovered
                                ? Theme.errorTint(0.12)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: 120 } }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                text: "Forget network"
                                color: wifiMenuForgetHov.hovered
                                    ? Theme.colors.error
                                    : Theme.colors.foreground
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.bodySm
                                Behavior on color { ColorAnimation { duration: 120 } }
                            }

                            HoverHandler { id: wifiMenuForgetHov; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                onTapped: {
                                    let ssid = wifiNetCol.openWifiMenuSsid;
                                    let rk = wifiNetCol.openWifiMenuKey;
                                    wifiNetCol.openWifiMenuKey = "";
                                    Wifi.forget(ssid);
                                    if (wifiNetCol.expandedWifiKey === rk) {
                                        wifiNetCol.expandedWifiKey = "";
                                        wifiNetCol.wifiPwdErrorKey = "";
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
        color: Theme.colors.primary
        font.family: Typography.fontFamily
        font.pixelSize: Typography.label
    }
}
