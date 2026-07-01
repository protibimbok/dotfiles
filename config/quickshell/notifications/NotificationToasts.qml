import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.components
import qs.tokens
import qs.services

// Top-right stack of transient notification toasts, tucked just under the bar. A
// single container card carries the melt shape (fused to the bar, flush to the screen
// edge); the individual toasts inside are plain rounded cards. `_edgeRoom` reserves
// space on the left and bottom so the container's coves (which bow past its body)
// aren't clipped. A Loader (re)creates the container whenever notifications appear so
// its slide-down entrance replays.
PanelWindow {
    id: root

    // Dedicated namespace so the compositor blurs only these (not the bar).
    WlrLayershell.namespace: "quickshell-toast"

    readonly property int _edgeRoom: Metrics.toastRadius

    anchors {
        top: true
        right: true
    }
    margins {
        // Bar's exclusive zone already offsets top-anchored layers by its height,
        // so the container sits flush under the bar and fuses to it.
        top: 0
        right: 0
    }

    exclusiveZone: 0
    color: "transparent"
    visible: Notifications.popups.length > 0

    implicitWidth: Metrics.toastColumnWidth + root._edgeRoom
    implicitHeight: Math.max(1, loader.implicitHeight + root._edgeRoom)

    Loader {
        id: loader
        anchors.right: parent.right
        anchors.top: parent.top
        width: Metrics.toastColumnWidth
        active: Notifications.popups.length > 0

        // Pause toast expiry while the cursor is over the stack (so a notification
        // can be read and clicked without it timing out from under the pointer).
        HoverHandler {
            onHoveredChanged: Notifications.popupsHovered = hovered
        }

        sourceComponent: FloatingCard {
            width: loader.width

            Column {
                id: column
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                spacing: Spacing.md

                move: Transition {
                    NumberAnimation { property: "y"; duration: Durations.toastSlide; easing.type: Easing.OutExpo }
                }

                Repeater {
                    model: Notifications.popups

                    // modelData (a Notifications.popups entry) is injected into the
                    // toast's own required `modelData` property by the Repeater.
                    NotificationToast {
                        width: column.width
                    }
                }
            }
        }
    }
}
