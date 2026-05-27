import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.tokens
import qs.services
import qs.components

Item {
    id: root
    signal close()

    required property var shellRoot
    property bool panelOpen: false

    ListModel {
        id: notifListModel
    }

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
            Qt.callLater(root.syncNotificationModel);
        }
    }

    Connections {
        target: Notifications
        function onNotificationsChanged() {
            root.syncNotificationModel();
        }
    }

    Component.onCompleted: root.syncNotificationModel()

    Item {
        id: panel
        width: Metrics.notificationPanelWidth
        height: Math.min(Metrics.notificationPanelMaxHeight, root.height - Spacing.panelMaxHeightInset)
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: Spacing.panelTopMargin

        HoverHandler {
            onHoveredChanged: shellRoot.notifPanelHovered = hovered
        }

        PanelChrome {
            anchors.fill: parent
            fillOpacity: Metrics.panelFillOpacityNotif

            RowLayout {
                anchors.fill: parent
                anchors.margins: Spacing.panelContentMarginLg
                spacing: Spacing.xxl

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: Spacing.lg

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Spacing.md

                        Text {
                            text: "Notifications"
                            color: Theme.colors.foreground
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.header
                            font.bold: true
                        }

                        Rectangle {
                            visible: Notifications.unreadCount > 0
                            width: unreadText.implicitWidth + 12
                            height: 20
                            radius: Metrics.rowRadius + 2
                            color: Theme.primaryTint(0.15)

                            Text {
                                id: unreadText
                                anchors.centerIn: parent
                                text: Notifications.unreadCount
                                color: Theme.colors.primary
                                font.family: Typography.fontFamily
                                font.pixelSize: Typography.bodySm
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: Notifications.notifications.length > 0
                            text: "Clear"
                            color: clearHover.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.body
                            Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
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
                            spacing: Spacing.sm
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            add: Transition {
                                NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: Durations.fade; easing.type: Easing.OutCubic }
                                NumberAnimation { properties: "x"; from: -8; to: 0; duration: Durations.fade; easing.type: Easing.OutCubic }
                            }

                            remove: Transition {
                                NumberAnimation { properties: "opacity"; to: 0; duration: Durations.hoverMedium; easing.type: Easing.InCubic }
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
                                property bool bodyExpanded: false

                                onBodyChanged: bodyExpanded = false

                                width: notifList.width
                                height: notifContent.implicitHeight + 20
                                radius: Metrics.listRadius
                                color: Theme.surfaceTint(Theme.colors.surface, 0.6)

                                RowLayout {
                                    id: notifContent
                                    // Height driven by content; avoid anchors.fill binding loop
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.margins: 10
                                    spacing: Spacing.lg

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
                                        spacing: Spacing.rowGap

                                        Text {
                                            text: notifItem.appName
                                            color: Theme.colors.foregroundMuted
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.bodySm
                                            Layout.fillWidth: true
                                        }

                                        Text {
                                            text: notifItem.summary
                                            color: Theme.colors.foreground
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.title
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                        }

                                        Text {
                                            id: bodyText
                                            visible: notifItem.body !== ""
                                            text: notifItem.body
                                            color: Theme.colors.foregroundMuted
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.body
                                            Layout.fillWidth: true
                                            wrapMode: Text.Wrap
                                            maximumLineCount: notifItem.bodyExpanded ? 0 : 3
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            visible: bodyText.truncated
                                                || (notifItem.bodyExpanded && bodyText.lineCount > 3)
                                            text: notifItem.bodyExpanded ? "Show less" : "Show more"
                                            color: expandHover.hovered ? Theme.colors.foreground : Theme.colors.primary
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.bodySm
                                            Layout.fillWidth: true
                                            Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
                                            HoverHandler { id: expandHover; cursorShape: Qt.PointingHandCursor }
                                            TapHandler { onTapped: notifItem.bodyExpanded = !notifItem.bodyExpanded }
                                        }

                                        Text {
                                            text: notifItem.timeAgo
                                            color: Theme.colors.foregroundMuted
                                            font.family: Typography.fontFamily
                                            font.pixelSize: Typography.label
                                            opacity: 0.7
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignTop
                                        text: "\uf00d"
                                        color: dismissHover.hovered ? Theme.errorTint(0.7) : Theme.colors.foregroundMuted
                                        font.family: Typography.fontFamily
                                        font.pixelSize: Typography.bodySm
                                        Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
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
                            color: Theme.colors.foregroundMuted
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.title
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Theme.colors.outline
                    opacity: 0.2
                }

                MiniCalendar {}
            }
        }
    }

    Keys.onEscapePressed: root.close()

    component MiniCalendar: ColumnLayout {
        spacing: Spacing.md
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
                color: prevHover.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.title
                Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
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
                color: Theme.colors.foreground
                font.family: Typography.fontFamily
                font.pixelSize: Typography.body
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "\uf105"
                color: nextHover.hovered ? Theme.colors.foreground : Theme.colors.foregroundMuted
                font.family: Typography.fontFamily
                font.pixelSize: Typography.title
                Behavior on color { ColorAnimation { duration: Durations.hoverMedium } }
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
                    color: Theme.colors.foregroundMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.label
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
                        color: isToday ? Theme.colors.primary : "transparent"
                        visible: validDay
                    }

                    Text {
                        anchors.centerIn: parent
                        text: validDay ? dayNum : ""
                        color: isToday ? Theme.colors.background : Theme.colors.foreground
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.bodySm
                    }
                }
            }
        }
    }
}