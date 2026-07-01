import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.tokens
import qs.services
import qs.utils

// A single notification: a plain rounded card that sits inside the shared toast
// container (which carries the melt shape). modelData is a Notifications.popups
// entry. Clicking dismisses the toast.
Rectangle {
    id: root

    required property var modelData
    readonly property string iconSource: modelData.appIcon ? Icons.app(modelData.appIcon) : ""

    radius: Metrics.toastRadius
    color: Theme.colors.surface
    implicitHeight: layout.implicitHeight + Spacing.md * 2

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Notifications.dismissPopup(root.modelData.id)
    }

    Item {
        id: layout
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: Spacing.md
        anchors.rightMargin: Spacing.md
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: Math.max(icon.height, textCol.implicitHeight)

        Rectangle {
            id: icon
            anchors.left: parent.left
            anchors.verticalCenter: textCol.verticalCenter
            width: Metrics.toastIcon
            height: Metrics.toastIcon
            radius: width / 2
            color: Theme.colors.surfaceHigh

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
                text: "" // nerd-font info circle
                font.family: Typography.fontFamily
                font.pixelSize: Typography.iconMd
                color: Theme.pillTextMuted
            }
        }

        Text {
            id: chevron
            anchors.right: parent.right
            anchors.top: parent.top
            text: "" // nerd-font chevron-down
            font.family: Typography.fontFamily
            font.pixelSize: Typography.label
            color: Theme.pillTextMuted
        }

        Column {
            id: textCol
            anchors.left: icon.right
            anchors.leftMargin: Spacing.lg
            anchors.right: chevron.left
            anchors.rightMargin: Spacing.md
            anchors.top: parent.top
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
                    text: "now"
                    color: Theme.pillTextMuted
                    font.family: Typography.fontFamily
                    font.pixelSize: Typography.bodySm
                }
            }

            Text {
                width: parent.width
                visible: text.length > 0
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
}
