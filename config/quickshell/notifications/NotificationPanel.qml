import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.theme
import qs.services

Item {
    id: root
    signal close()

    property bool panelOpen: false

    ListModel {
        id: notifListModel
    }

    // FIX: Smart sync to preserve ListView add/remove animations
    function syncNotificationModel() {
        const arr = Notifications.notifications;

        // 1. Remove dismissed notifications
        for (let i = notifListModel.count - 1; i >= 0; i--) {
            let exists = false;
            for (let j = 0; j < arr.length; j++) {
                if (arr[j].id === notifListModel.get(i).notifId) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                notifListModel.remove(i, 1);
            }
        }

        // 2. Add new notifications
        for (let i = 0; i < arr.length; i++) {
            let exists = false;
            for (let j = 0; j < notifListModel.count; j++) {
                if (notifListModel.get(j).notifId === arr[i].id) {
                    exists = true;
                    break;
                }
            }
            if (!exists) {
                notifListModel.append({
                    notifId: arr[i].id,
                    appName: arr[i].appName || "",
                    appIcon: arr[i].appIcon || "",
                    summary: arr[i].summary || "",
                    body: arr[i].body || "",
                    timeAgo: arr[i].timeAgo || ""
                });
            }
        }
    }

    onPanelOpenChanged: {
        if (panelOpen) {
            Notifications.markRead();
            root.syncNotificationModel();
        }
    }

    Connections {
        target: Notifications
        function onNotificationsChanged() {
            root.syncNotificationModel();
        }
    }

    Component.onCompleted: root.syncNotificationModel()

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: 0.15
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.close()
    }

    Item {
        id: panel
        width: 600
        height: Math.min(480, root.height - 64)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 54

        layer.enabled: true
        layer.effect: MultiEffect {
            autoPaddingEnabled: true
            shadowEnabled: true
            shadowBlur: 1.0
            shadowColor: "#30000000"
            shadowVerticalOffset: 6
        }

        MouseArea { anchors.fill: parent }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: Theme.colors.bg
            opacity: 0.88
        }

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: "transparent"
            border.color: Theme.colors.border
            border.width: 1
            opacity: 0.25
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "Notifications"
                        color: Theme.colors.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    Rectangle {
                        visible: Notifications.unreadCount > 0
                        width: unreadText.implicitWidth + 12
                        height: 20
                        radius: 10
                        color: Qt.rgba(Theme.colors.accent.r, Theme.colors.accent.g, Theme.colors.accent.b, 0.15)

                        Text {
                            id: unreadText
                            anchors.centerIn: parent
                            text: Notifications.unreadCount
                            color: Theme.colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        visible: Notifications.notifications.length > 0
                        text: "Clear"
                        color: clearHover.hovered ? Theme.colors.text : Theme.colors.textMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        Behavior on color { ColorAnimation { duration: 150 } }
                        HoverHandler { id: clearHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: Notifications.clearAll() }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: notifList
                        anchors.fill: parent
                        model: notifListModel
                        spacing: 6
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        add: Transition {
                            NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
                            NumberAnimation { properties: "x"; from: -8; to: 0; duration: 200; easing.type: Easing.OutCubic }
                        }

                        remove: Transition {
                            NumberAnimation { properties: "opacity"; to: 0; duration: 150; easing.type: Easing.InCubic }
                        }

                        delegate: Rectangle {
                            id: notifItem
                            required property int index
                            required property var notifId
                            required property string appName
                            required property string appIcon
                            required property string summary
                            required property string body
                            required property string timeAgo
                            
                            width: notifList.width
                            height: notifContent.implicitHeight + 20
                            radius: 12
                            color: Qt.rgba(Theme.colors.bg1.r, Theme.colors.bg1.g, Theme.colors.bg1.b, 0.6)

                            RowLayout {
                                id: notifContent
                                // FIX: Removed 'anchors.fill: parent' to fix the height binding loop
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 10
                                spacing: 12

                                Image {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    Layout.alignment: Qt.AlignTop
                                    source: notifItem.appIcon ? Quickshell.iconPath(notifItem.appIcon, "application-x-executable") : ""
                                    sourceSize: Qt.size(22, 22)
                                    visible: notifItem.appIcon !== ""
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        text: notifItem.appName
                                        color: Theme.colors.textMuted
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 11
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: notifItem.summary
                                        color: Theme.colors.text
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 13
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                    }

                                    Text {
                                        visible: notifItem.body !== ""
                                        text: notifItem.body
                                        color: Theme.colors.textMuted
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: notifItem.timeAgo
                                        color: Theme.colors.textMuted
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                        opacity: 0.7
                                    }
                                }

                                Text {
                                    Layout.alignment: Qt.AlignTop
                                    text: "\uf00d"
                                    color: dismissHover.hovered ? Qt.rgba(Theme.colors.red.r, Theme.colors.red.g, Theme.colors.red.b, 0.7) : Theme.colors.textMuted
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                    HoverHandler { id: dismissHover; cursorShape: Qt.PointingHandCursor }
                                    TapHandler { onTapped: Notifications.dismiss(notifItem.notifId) }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: notifListModel.count === 0
                        text: "All clear"
                        color: Theme.colors.textMuted
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                }
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.fillHeight: true
                color: Theme.colors.border
                opacity: 0.2
            }

            MiniCalendar {}
        }
    }

    Keys.onEscapePressed: root.close()

    component MiniCalendar: ColumnLayout {
        spacing: 8
        Layout.preferredWidth: 210
        Layout.minimumWidth: 210
        Layout.maximumWidth: 210
        Layout.fillHeight: true

        property date today: new Date()
        property int viewYear: today.getFullYear()
        property int viewMonth: today.getMonth()

        // Note: Strict type annotations (year: int) require modern Qt 6.
        // If you encounter a syntax error on older Qt versions, remove ': int'.
        function daysInMonth(year: int, month: int): int {
            return new Date(year, month + 1, 0).getDate();
        }

        function firstDayOffset(year: int, month: int): int {
            let d = new Date(year, month, 1).getDay();
            return d === 0 ? 6 : d - 1;
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "\uf104"
                color: prevHover.hovered ? Theme.colors.text : Theme.colors.textMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                Behavior on color { ColorAnimation { duration: 150 } }
                HoverHandler { id: prevHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (viewMonth === 0) { viewMonth = 11; viewYear--; }
                        else viewMonth--;
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                text: Qt.locale().monthName(viewMonth, Locale.LongFormat) + " " + viewYear
                color: Theme.colors.text
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "\uf105"
                color: nextHover.hovered ? Theme.colors.text : Theme.colors.textMuted
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 13
                Behavior on color { ColorAnimation { duration: 150 } }
                HoverHandler { id: nextHover; cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: {
                        if (viewMonth === 11) { viewMonth = 0; viewYear++; }
                        else viewMonth++;
                    }
                }
            }
        }

        Grid {
            Layout.fillWidth: true
            columns: 7
            spacing: 0

            Repeater {
                model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                Text {
                    width: parent.width / 7
                    text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    color: Theme.colors.textMuted
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }
        }

        Grid {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 7
            spacing: 0

            Repeater {
                model: 42

                Item {
                    required property int index
                    property int offset: firstDayOffset(viewYear, viewMonth)
                    property int dayNum: index - offset + 1
                    property bool validDay: dayNum >= 1 && dayNum <= daysInMonth(viewYear, viewMonth)
                    property bool isToday: validDay && dayNum === today.getDate() && viewMonth === today.getMonth() && viewYear === today.getFullYear()

                    width: parent.width / 7
                    height: 26

                    Rectangle {
                        anchors.centerIn: parent
                        width: 22; height: 22; radius: 11
                        color: isToday ? Theme.colors.accent : "transparent"
                        visible: validDay
                    }

                    Text {
                        anchors.centerIn: parent
                        text: validDay ? dayNum : ""
                        color: isToday ? Theme.colors.bg : Theme.colors.text
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}