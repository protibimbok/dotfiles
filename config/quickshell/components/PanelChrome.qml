import QtQuick
import QtQuick.Effects
import qs.theme
import qs.tokens

Item {
    id: root

    property real radius: Metrics.panelRadius
    property real fillOpacity: Metrics.panelFillOpacityDefault
    property real borderOpacity: Metrics.panelBorderOpacity
    property bool shadowEnabled: true
    property color shadowColor: "#30000000"
    property int shadowOffset: 6

    default property alias content: contentHost.data

    layer.enabled: shadowEnabled
    layer.effect: MultiEffect {
        autoPaddingEnabled: true
        shadowEnabled: root.shadowEnabled
        shadowBlur: 1.0
        shadowColor: root.shadowColor
        shadowVerticalOffset: root.shadowOffset
    }

    MouseArea { anchors.fill: parent }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: Theme.colors.background
        opacity: root.fillOpacity
    }

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.color: Theme.colors.outline
        border.width: 1
        opacity: root.borderOpacity
    }

    Item {
        id: contentHost
        anchors.fill: parent
    }
}
