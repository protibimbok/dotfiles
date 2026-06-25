import QtQuick
import qs.theme
import qs.tokens
import qs.services
import qs.bar.components

Item {
    id: root

    required property var shellRoot

    readonly property bool unifiedBar: Hyprland.plainBarMode

    // barContainer offset, so pill geometry can be expressed in surface coords.
    readonly property real surfaceLeft: Spacing.barHorizontal
    readonly property real surfaceTop: Spacing.barTopInset

    // Animated so mode changes cross-fade smoothly.
    property real fillAlpha: unifiedBar ? Metrics.barUnifiedFillOpacity : Metrics.barStripFillOpacity
    readonly property real layoutHeight: Metrics.barLayoutHeight
    property real stripHeight: unifiedBar ? root.layoutHeight : root.layoutHeight / 2

    Behavior on fillAlpha { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
    Behavior on stripHeight { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }

    function pillRect(item) {
        return Qt.vector4d(root.surfaceLeft + item.x, root.surfaceTop + item.y, item.width, item.height);
    }

    // Single translucent surface: the full-width strip and every pill are one
    // signed-distance field, smooth-unioned so the joins are soft fillets with no
    // seam. The pill *content* lives in barContainer (on top, full opacity) so
    // text stays crisp.
    ShaderEffect {
        anchors.fill: parent
        fragmentShader: "shaders/barSurface.frag.qsb"
        blending: true

        property vector2d resolution: Qt.vector2d(width, height)
        property vector4d stripRect: Qt.vector4d(0, 0, root.width, root.stripHeight)
        property vector4d pill0: root.pillRect(leftPill)
        property vector4d pill1: mediaPill.visible ? root.pillRect(mediaPill) : Qt.vector4d(0, 0, 0, 0)
        property vector4d pill2: root.pillRect(barCenter)
        property vector4d pill3: root.pillRect(barRight)
        property vector4d fillColor: Qt.vector4d(0, 0, 0, root.fillAlpha)
        property real pillRadius: Metrics.barPillRadius
        property real smoothing: Metrics.barSurfaceSmoothing
        property real softness: Metrics.barSurfaceEdgeSoftness
    }

    // Pill content. Margins are constant across modes so pills never shift when
    // the bar mode toggles. Backgroundless throughout — the shader draws the fill.
    Item {
        id: barContainer
        anchors.fill: parent
        anchors.leftMargin: Spacing.barHorizontal
        anchors.rightMargin: Spacing.barHorizontal
        anchors.topMargin: Spacing.barTopInset
        anchors.bottomMargin: Spacing.barBottomInset

        BarPill {
            id: leftPill
            backgroundless: true
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: leftHost.implicitWidth + horizontalPadding * 2

            Item {
                id: leftHost
                anchors.centerIn: parent
                implicitWidth: barLeft.implicitWidth
                implicitHeight: Metrics.barPillHeight

                BarLeft {
                    id: barLeft
                    anchors.verticalCenter: parent.verticalCenter
                    shellRoot: root.shellRoot
                }
            }
        }

        BarPill {
            id: mediaPill
            backgroundless: true
            anchors.left: leftPill.right
            anchors.leftMargin: Mpris.isActive ? Spacing.pillGap : 0
            anchors.verticalCenter: parent.verticalCenter
            visible: Mpris.isActive
            width: Mpris.isActive
                ? Math.max(Metrics.barMediaMinWidth, mediaHost.implicitWidth + horizontalPadding * 2)
                : 0

            BarMedia {
                id: mediaHost
                anchors.centerIn: parent
            }

            Behavior on width { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
            Behavior on anchors.leftMargin { NumberAnimation { duration: Durations.fadeSlow; easing.type: Easing.OutCubic } }
        }

        BarCenter {
            id: barCenter
            backgroundless: true
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            shellRoot: root.shellRoot
        }

        BarRight {
            id: barRight
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            backgroundless: true
            shellRoot: root.shellRoot
        }
    }
}
