import QtQuick
import QtQuick.Shapes
import qs.theme
import qs.tokens

// Reusable floating surface drawn with a Shape so it can carry a caelestia-style
// "melt" into the top-right corner: the top edge (fused to the bar) and the right
// edge (the screen edge) are flush and meet at a sharp corner, with concave coves at
// the top-left (flaring LEFT out from under the bar) and bottom-right (dripping DOWN
// along the screen edge), plus a convex round only at the bottom-left. Both coves bow
// past the body, so the host window must reserve room on the left and bottom for them.
// On entrance the fully-formed card slides down out from behind the bar. Content goes
// in the default slot; height follows it. Knows nothing about its contents.
Item {
    id: root

    // Convex corner radius for the free (bottom-left) corner.
    property real radius: Metrics.toastRadius
    // Concave cove radius for the edge-facing corners (TL flares left, BR drips down).
    property real invertedRadius: Metrics.toastRadius
    property real padding: Spacing.lg

    // Solid fill, defaulting to the bar's translucent black so the card reads as the
    // same surface as the bar it hangs from.
    property color fillColor: Qt.rgba(0, 0, 0, Metrics.barUnifiedFillOpacity)

    default property alias content: contentItem.data

    implicitHeight: contentItem.childrenRect.height + root.padding * 2

    // Cove radius, capped so it never exceeds half the height.
    readonly property real _k: Math.min(root.invertedRadius, root.height / 2)

    // Entrance: slide the fully-formed card down out from behind the bar.
    property bool _entered: false
    Component.onCompleted: root._entered = true

    // SVG path for the "melted into the top-right corner" shape. Top (y=0) and right
    // (x=w) edges are flush and meet at a sharp corner (w,0). The TL cove extends the
    // top edge LEFT past the corner (to -k,0) and curves back down to the left edge;
    // the BR cove extends the right edge DOWN past the corner and curves back to the
    // bottom edge — both concave, centred on the corner. Bottom-left is convex.
    function _buildPath(w: real, h: real, r: real, k: real): string {
        const rr = Math.min(r, w / 2, h / 2);
        const kk = Math.min(k, w / 2);
        let p = "M " + (-kk) + ",0 ";                                     // TL cove: top edge extended left
        p += "L " + w + ",0 ";                                            // flush top to sharp TR corner
        p += "L " + w + "," + (h + kk) + " ";                             // flush right edge, extended down
        p += "A " + kk + " " + kk + " 0 0 0 " + (w - kk) + "," + h + " "; // BR cove back to bottom edge
        p += "L " + rr + "," + h + " ";                                   // bottom edge to BL
        p += "A " + rr + " " + rr + " 0 0 1 0," + (h - rr) + " ";         // BL convex round
        p += "L 0," + kk + " ";                                           // left edge up to TL cove
        p += "A " + kk + " " + kk + " 0 0 0 " + (-kk) + ",0 Z";           // TL cove back to top edge
        return p;
    }

    // Slide the whole card (shape + content) down out of the bar on entrance.
    transform: Translate {
        y: root._entered ? 0 : -root.height
        Behavior on y { NumberAnimation { duration: Durations.toastSlide; easing.type: Easing.OutExpo } }
    }

    Shape {
        id: shape
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
