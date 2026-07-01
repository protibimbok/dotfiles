import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.tokens
import qs.services
import qs.utils

// Unread notification row inside the hover panel — same interactions as
// NotificationToast but backed by Notifications.notifications.
Item {
    id: root

    required property var modelData
    property bool expanded: false

    readonly property var notifObj: modelData._notifObj
    readonly property var visibleActions: {
        let out = [];
        if (!root.notifObj || !root.notifObj.actions)
            return out;
        for (let i = 0; i < root.notifObj.actions.length; i++) {
            let action = root.notifObj.actions[i];
            if (action.identifier !== "default")
                out.push(action);
        }
        return out;
    }
    readonly property bool hasActions: visibleActions.length > 0
    readonly property bool expandable: hasActions || !!(modelData.body && modelData.body.length)
    readonly property string iconSource: modelData.appIcon ? Icons.app(modelData.appIcon) : ""

    property string timeAgoLabel: Notifications.formatTimeAgo(modelData.ts || Date.now())

    implicitHeight: card.implicitHeight

    Component.onCompleted: root.timeAgoLabel = Notifications.formatTimeAgo(root.modelData.ts || Date.now())

    HoverHandler { cursorShape: Qt.PointingHandCursor }

    Rectangle {
        id: card
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        radius: Metrics.toastRadius
        color: Theme.colors.surface
        implicitHeight: inner.implicitHeight + Spacing.md * 2
    }

    Column {
        id: inner
        anchors.left: card.left
        anchors.right: card.right
        anchors.top: card.top
        anchors.margins: Spacing.md
        spacing: Spacing.sm

        RowLayout {
            width: parent.width
            spacing: Spacing.lg

            Rectangle {
                Layout.preferredWidth: Metrics.toastIcon
                Layout.preferredHeight: Metrics.toastIcon
                Layout.alignment: Qt.AlignTop
                radius: width / 2
                color: Theme.colors.surfaceHigh

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: Notifications.focusNotificationApp(root.modelData.id)
                }

                Image {
                    anchors.centerIn: parent
                    width: Math.round(parent.width * 0.55)
                    height: width
                    source: root.iconSource
                    visible: root.iconSource.length > 0
                    sourceSize: Qt.size(width, height)
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.iconSource.length === 0
                    text: ""
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.iconMd
                    color: Theme.pillTextMuted
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                implicitHeight: textCol.implicitHeight

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: Notifications.activateNotification(root.modelData.id)
                }

                Column {
                    id: textCol
                    width: parent.width
                    spacing: Spacing.xs

                    RowLayout {
                        width: parent.width
                        spacing: Spacing.sm

                        Text {
                            Layout.fillWidth: true
                            text: root.modelData.summary
                            color: Theme.pillText
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.body
                            font.bold: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                        }

                        Text {
                            text: "•"
                            color: Theme.pillTextMuted
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.bodySm
                        }

                        Text {
                            text: root.timeAgoLabel
                            color: Theme.pillTextMuted
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.bodySm
                        }
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0 && !root.expanded
                        text: root.modelData.body
                        color: Theme.pillTextMuted
                        font.family: Typography.fontFamily
                        font.pixelSize: Typography.bodySm
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        textFormat: Text.PlainText
                    }
                }
            }

            Item {
                Layout.preferredWidth: chevron.implicitWidth + Spacing.md * 2
                Layout.preferredHeight: Math.max(chevron.implicitHeight + Spacing.sm, Metrics.toastIcon)
                Layout.alignment: Qt.AlignTop
                visible: root.expandable

                HoverHandler { cursorShape: Qt.PointingHandCursor }
                TapHandler {
                    onTapped: root.expanded = !root.expanded
                }

                Text {
                    id: chevron
                    anchors.centerIn: parent
                    rotation: root.expanded ? 180 : 0
                    text: ""
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.label
                    color: Theme.pillTextMuted

                    Behavior on rotation {
                        NumberAnimation { duration: Durations.colorTransition; easing.type: Easing.OutCubic }
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: root.expanded && text.length > 0
            text: root.modelData.body
            color: Theme.pillTextMuted
            font.family: Typography.fontFamily
            font.pixelSize: Typography.bodySm
            wrapMode: Text.Wrap
            maximumLineCount: 8
            textFormat: Text.PlainText
        }

        Flow {
            width: parent.width
            visible: root.expanded && root.hasActions
            spacing: Spacing.sm

            Repeater {
                model: root.visibleActions

                delegate: Item {
                    id: actionRow
                    required property var modelData

                    implicitWidth: actionBtn.implicitWidth + Spacing.md * 2
                    implicitHeight: Metrics.footerBtnHeight

                    HoverHandler { id: actionHover; cursorShape: Qt.PointingHandCursor }
                    TapHandler {
                        onTapped: Notifications.invokeAction(root.modelData.id, actionRow.modelData)
                    }

                    Rectangle {
                        id: actionBtn
                        anchors.fill: parent
                        radius: Metrics.rowRadius
                        color: actionHover.hovered ? Theme.colors.surfaceHigh : Theme.colors.surfaceHighest

                        Text {
                            anchors.centerIn: parent
                            text: actionRow.modelData.text
                            color: Theme.pillText
                            font.family: Typography.fontFamily
                            font.pixelSize: Typography.bodySm
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }
    }
}
