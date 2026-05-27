// Adapted from caelestia-dots/shell (GPL-3.0)
import QtQuick
import QtQuick.Shapes
import qs.theme
import qs.tokens

MouseArea {
    id: root

    property bool disabled: false
    property bool showHoverBackground: true
    readonly property alias rect: base

    property real pressX: width / 2
    property real pressY: height / 2
    property real circleRadius: 0

    property alias color: base.color
    property alias radius: base.radius

    readonly property real endRadius: {
        const d1 = distSq(0, 0);
        const d2 = distSq(width, 0);
        const d3 = distSq(0, height);
        const d4 = distSq(width, height);
        return Math.sqrt(Math.max(d1, d2, d3, d4));
    }
    property real endRadiusAtPress: 0

    function distSq(x: real, y: real): real {
        return (pressX - x) ** 2 + (pressY - y) ** 2;
    }

    function press(x: real, y: real): void {
        pressX = x;
        pressY = y;
        fadeAnim.complete();
        circleRadius = 0;
        circle.opacity = 0.1;
        rippleAnim.restart();
        endRadiusAtPress = endRadius;
    }

    anchors.fill: parent
    enabled: !disabled
    cursorShape: disabled ? undefined : Qt.PointingHandCursor
    hoverEnabled: true

    onPressed: e => press(e.x, e.y)

    onPressedChanged: {
        if (!pressed && !rippleAnim.running && circle.opacity > 0)
            fadeAnim.start();
    }

    onCircleRadiusChanged: {
        if (!pressed && circleRadius > endRadiusAtPress * 0.99 && !fadeAnim.running)
            fadeAnim.start();
    }

    Anim {
        id: rippleAnim
        alwaysRunToEnd: true
        target: root
        property: "circleRadius"
        to: root.endRadius
        easing: AnimTokens.expressiveSlowEffects
        duration: AnimTokens.durations.expressiveSlowEffects * 2
    }

    Anim {
        id: fadeAnim
        target: circle
        property: "opacity"
        to: 0
        easing: AnimTokens.expressiveSlowEffects
        duration: AnimTokens.durations.expressiveSlowEffects
    }

    StyledRect {
        id: base
        anchors.fill: parent
        opacity: root.pressed ? 0.1 : (root.containsMouse ? 0.08 : 0)
        color: Theme.colors.foreground
        radius: root.parent?.radius ?? 0

        Behavior on opacity {
            Anim {
                easing: AnimTokens.expressiveDefaultEffects
                duration: AnimTokens.durations.expressiveDefaultEffects
            }
        }
    }

    Shape {
        id: circle
        anchors.fill: parent
        opacity: 0
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeWidth: 0
            strokeColor: "transparent"
            fillColor: base.color

            PathArc {
                x: root.width
                y: root.height
                radiusX: root.width / 2
                radiusY: root.height / 2
            }
            PathArc {
                x: 0
                y: 0
                radiusX: root.width / 2
                radiusY: root.height / 2
            }
        }
    }
}
