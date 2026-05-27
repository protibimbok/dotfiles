import QtQuick
import QtQuick.Effects
import qs.theme
import qs.tokens

Item {
    id: root

    property real radius: Metrics.barPillRadius
    property int elevation: Metrics.barElevation
    property bool highlighted: false
    property bool hovered: false
    property real explicitWidth: 0
    property real explicitHeight: 0

    default property alias content: contentItem.data

    property real horizontalPadding: Spacing.pillPadding
    readonly property real pillHeight: explicitHeight > 0 ? explicitHeight : Metrics.barPillHeight

    implicitWidth: explicitWidth > 0
        ? explicitWidth
        : (contentItem.childrenRect.width + horizontalPadding * 2)
    implicitHeight: pillHeight
    width: implicitWidth
    height: pillHeight

    readonly property color resolvedFill: highlighted
        ? Theme.pillBackgroundHighlight
        : (hovered ? Theme.pillBackgroundHover : Theme.pillBackground)

    Rectangle {
        id: surface
        anchors.fill: parent
        radius: root.radius
        color: root.resolvedFill
        border.width: 1
        border.color: highlighted ? Theme.pillAccent : Theme.pillBorder
        clip: true

        Behavior on color { ColorAnimation { duration: Durations.colorTransitionSlow; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: Durations.colorTransition; easing.type: Easing.OutCubic } }

        layer.enabled: root.elevation > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: root.highlighted ? 1.0 : 0.8
            shadowColor: Qt.rgba(Theme.shadow.r, Theme.shadow.g, Theme.shadow.b, root.highlighted ? 0.22 : 0.14)
            shadowVerticalOffset: root.highlighted ? 4 : 2
        }

        Item {
            id: contentItem
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: root.horizontalPadding
            anchors.right: parent.right
            anchors.rightMargin: root.horizontalPadding
            height: parent.height
        }
    }
}
