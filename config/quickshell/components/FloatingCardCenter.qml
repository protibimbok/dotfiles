import QtQuick
import QtQuick.Shapes
import qs.theme
import qs.tokens

// Center-hanging melt card: its top edge fuses to the bar with a concave cove at
// each top corner (the top-left one identical to FloatingCard's — flaring left out
// from under the bar), and convex rounds at both bottom corners. Both top coves bow
// past the body sideways, so the host must reserve room on the left and the right.
Item {
    id: root

    property real radius: Metrics.toastRadius
    property real invertedRadius: Metrics.toastRadius
    property real padding: Spacing.lg
    property color fillColor: Qt.rgba(0, 0, 0, Metrics.barUnifiedFillOpacity)

    default property alias content: contentItem.data

    implicitHeight: contentItem.childrenRect.height + root.padding * 2

    readonly property real _k: Math.min(root.invertedRadius, root.height / 2)

    property bool _entered: false
    Component.onCompleted: root._entered = true

    function _buildPath(w: real, h: real, r: real, k: real): string {
        const rr = Math.min(r, w / 2, h / 2);
        const kk = Math.min(k, w / 2);
        let p = "M " + (-kk) + ",0 ";                                     // TL cove: top edge extended left
        p += "L " + (w + kk) + ",0 ";                                     // top edge, extended right past TR corner
        p += "A " + kk + " " + kk + " 0 0 0 " + w + "," + kk + " ";       // TR cove back to the right edge
        p += "L " + w + "," + (h - rr) + " ";                             // right edge
        p += "A " + rr + " " + rr + " 0 0 1 " + (w - rr) + "," + h + " "; // BR convex round
        p += "L " + rr + "," + h + " ";                                   // bottom edge
        p += "A " + rr + " " + rr + " 0 0 1 0," + (h - rr) + " ";         // BL convex round
        p += "L 0," + kk + " ";                                           // left edge up to TL cove
        p += "A " + kk + " " + kk + " 0 0 0 " + (-kk) + ",0 Z";           // TL cove back to the top edge
        return p;
    }

    transform: Translate {
        y: root._entered ? 0 : -root.height
        Behavior on y { NumberAnimation { duration: Durations.toastSlide; easing.type: Easing.OutExpo } }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        asynchronous: true

        ShapePath {
            strokeColor: Theme.outlineTint(0.45)
            strokeWidth: 1
            fillColor: root.fillColor
            PathSvg { path: root._buildPath(root.width, root.height, root.radius, root._k) }
        }
    }

    Item {
        id: contentItem
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
